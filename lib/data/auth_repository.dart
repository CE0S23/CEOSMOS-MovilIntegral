import '../core/sin_espacios.dart';
import '../domain/models.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Autenticación contra la API real de CEOSMOS (`/api/auth`).
class AuthRepository {
  AuthRepository(this.api, this.tokens);
  final ApiClient api;
  final TokenStore tokens;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _password = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,72}$',
  );

  static String? validarCorreo(String? v) {
    final value = v ?? '';
    if (value.trim().isEmpty) return 'Escribe tu correo.';
    if (SinEspacios.tieneEspacios(value)) return SinEspacios.error;
    return _email.hasMatch(value) ? null : 'Escribe un correo válido.';
  }

  /// Misma política que el backend (registro y cambio de contraseña).
  static String? validarContrasenaNueva(String? v) {
    final value = v ?? '';
    if (SinEspacios.tieneEspacios(value)) return SinEspacios.error;
    if (value.length < 8) return 'Mínimo 8 caracteres.';
    if (value.length > 72) return 'Máximo 72 caracteres.';
    return _password.hasMatch(value)
        ? null
        : 'Usa mayúscula, minúscula, número y símbolo.';
  }

  static String? validarUsuario(String? v) {
    final value = v ?? '';
    if (value.trim().length < 3 || value.length > 30) return 'Entre 3 y 30 caracteres.';
    if (SinEspacios.tieneEspacios(value)) return SinEspacios.error;
    return null;
  }

  /// Contraseña del inicio de sesión: solo se exige que no esté vacía (la política
  /// completa se aplica al crearla; una cuenta antigua puede no cumplirla).
  static String? validarContrasenaLogin(String? v) => (v ?? '').isEmpty
      ? 'Escribe tu contraseña.'
      : SinEspacios.tieneEspacios(v) ? SinEspacios.error : null;

  static final _codigo = RegExp(r'^[0-9A-Fa-f]{6}$');

  /// Código de verificación de correo: 6 caracteres hexadecimales.
  static String? validarCodigoVerificacion(String? v) => _codigo.hasMatch(v ?? '')
      ? null
      : 'El código tiene 6 caracteres (0-9, A-F).';

  /// Token del enlace para restablecer la contraseña (se pega completo).
  static String? validarTokenRestablecer(String? v) => (v?.trim().length ?? 0) < 10
      ? 'Pega el código completo del enlace.'
      : SinEspacios.tieneEspacios(v) ? SinEspacios.error : null;

  static String normalizar(String email) => email.trim().toLowerCase();

  /// Restaura la sesión guardada; devuelve null si no hay token o ya no es válido.
  Future<AuthSession?> restore() async {
    final token = await tokens.read();
    if (token == null) return null;
    api.token = token;
    try {
      return AuthSession(user: await me(), token: token);
    } on ApiException catch (e) {
      if (e.unauthorized) {
        await _forget();
        return null;
      }
      rethrow; // sin red: se mantiene el token para reintentar
    }
  }

  Future<AppUser> me() async =>
      AppUser.fromJson((await api.get('/users/me')) as Map<String, dynamic>);

  Future<AuthSession> login(String email, String password) async {
    final res = await api.post('/auth/login', {
      'email': normalizar(email),
      'password': password,
    });
    final token = (res as Map)['token'] as String?;
    if (token == null) {
      throw const ApiException('El servidor no devolvió una sesión.');
    }
    api.token = token;
    try {
      final user = await me();
      await tokens.write(token);
      return AuthSession(user: user, token: token);
    } catch (_) {
      api.token = null;
      rethrow;
    }
  }

  /// Crea la cuenta; el servidor envía un código de verificación por correo.
  Future<void> register(String username, String email, String password) =>
      api.post('/auth/register', {
        'username': username.trim(),
        'email': normalizar(email),
        'password': password,
      });

  Future<void> verifyEmail(String email, String code) =>
      api.post('/auth/verify-email', {
        'email': normalizar(email),
        'code': code.trim().toUpperCase(),
      });

  Future<void> resendVerification(String email) =>
      api.post('/auth/resend-verification', {'email': normalizar(email)});

  Future<void> forgotPassword(String email) =>
      api.post('/auth/forgot-password', {'email': normalizar(email)});

  Future<void> resetPassword(String token, String newPassword) =>
      api.post('/auth/reset-password', {
        'token': token.trim(),
        'newPassword': newPassword,
      });

  /// Revoca la sesión en el servidor y borra el token local.
  Future<void> logout() async {
    try {
      if (api.token != null) await api.post('/auth/logout');
    } on ApiException {
      // Sin red o sesión ya vencida: igual se borra localmente.
    } finally {
      await _forget();
    }
  }

  Future<void> _forget() async {
    api.token = null;
    await tokens.clear();
  }
}
