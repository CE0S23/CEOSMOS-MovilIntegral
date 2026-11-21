import '../atras_ceosmos.dart'; // [CEOSMOS]
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';
import '../../ui/widgets.dart' show Aviso, TipoAviso;

void main() => runApp(const AccesoSeguroApp());

class AccesoSeguroApp extends StatelessWidget {
  const AccesoSeguroApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      onNavigationNotification: atrasManejadoPorCeosmos, // [CEOSMOS] Atrás vuelve a «Prácticas»
        title: 'AccesoSeguro',
        debugShowCheckedModeBanner: false,
        // [CEOSMOS] Tema compartido del sistema de diseño (claro/oscuro).
        theme: CeosmosTema.claro,
        darkTheme: CeosmosTema.oscuro,
        themeMode: ThemeMode.system,
        home: const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _channel = MethodChannel('acceso_seguro/login');
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _success = false;
  bool _notice = false;
  String _message = '';

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = false;
    });
    try {
      // La validación y el acceso de demostración se ejecutan en Kotlin.
      final reply = await _channel.invokeMapMethod<String, Object?>(
        'validateLogin',
        {'username': _user.text, 'password': _password.text},
      );
      if (!mounted) return;
      final ok = reply?['ok'] == true;
      if (ok) _password.clear();
      setState(() {
        _success = ok;
        _message = reply?['message'] as String? ?? 'No se pudo iniciar sesión.';
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = 'No se pudo iniciar sesión. Intenta de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signOut() {
    // La sesión es simulada; al salir se descartan los datos de los campos.
    _user.clear();
    _password.clear();
    setState(() {
      _success = false;
      _notice = true;
      _message = 'Sesión cerrada.';
    });
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Espacio.l, vertical: Espacio.l + 2),
      );

  @override
  Widget build(BuildContext context) {
    // [CEOSMOS] Colores y escala del sistema de diseño (antes navy/azul propios).
    final p = context.paleta;
    final t = context.texto;
    if (_success) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 72, color: p.exito),
                    const SizedBox(height: Espacio.l + 4),
                    Text('Acceso concedido',
                        textAlign: TextAlign.center,
                        style: t.displaySmall?.copyWith(color: p.marca)),
                    const SizedBox(height: Espacio.m),
                    Text('Acceso simulado correcto. Bienvenido.',
                        textAlign: TextAlign.center,
                        style: t.bodyLarge?.copyWith(color: p.textoSecundario)),
                    const SizedBox(height: Espacio.xxl + 4),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _signOut,
                        child: const Text('CERRAR SESIÓN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACCESO SEGURO',
                      style: t.labelMedium?.copyWith(color: p.enlace, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: Espacio.m),
                  Text('Inicia sesión',
                      style: t.displaySmall?.copyWith(color: p.marca)),
                  const SizedBox(height: Espacio.s),
                  Text('Ingresa tus datos para continuar.',
                      style: t.bodyLarge?.copyWith(color: p.textoSecundario)),
                  const SizedBox(height: Espacio.xxl + 6),
                  Text('Usuario', style: t.titleSmall),
                  const SizedBox(height: Espacio.s),
                  TextField(
                    controller: _user,
                    onChanged: (_) => setState(() {
                      _message = '';
                      _notice = false;
                    }),
                    // Impide teclear o pegar cualquier espacio en el usuario.
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    maxLength: 18,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _field('Tu usuario (sin espacios)'),
                  ),
                  const SizedBox(height: 22),
                  Text('Contraseña', style: t.titleSmall),
                  const SizedBox(height: Espacio.s),
                  TextField(
                    controller: _password,
                    onChanged: (_) => setState(() {
                      _message = '';
                      _notice = false;
                    }),
                    maxLength: 64,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                    decoration: _field('Mínimo 8 caracteres'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _busy ? null : _signIn,
                      child: Text(_busy ? 'VALIDANDO...' : 'INGRESAR'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: Center(
                      // [CEOSMOS] Ícono + texto: el error no depende solo del color.
                      child: _message.isEmpty
                          ? Text(_message)
                          : Aviso(_message,
                              tipo: _notice ? TipoAviso.info : TipoAviso.error),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('Demostración local · Sin conexión a un servidor',
                        style: t.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
