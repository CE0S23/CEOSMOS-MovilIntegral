import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const AccesoSeguroApp());

class AccesoSeguroApp extends StatelessWidget {
  const AccesoSeguroApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AccesoSeguro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1769AA)),
          scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        ),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0D203A);
    const blue = Color(0xFF1769AA);
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
                    const Icon(Icons.verified_user_outlined,
                        size: 72, color: Color(0xFF167443)),
                    const SizedBox(height: 20),
                    const Text('Acceso concedido',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: navy,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Acceso simulado correcto. Bienvenido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF526277), fontSize: 16)),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _signOut,
                        style: FilledButton.styleFrom(backgroundColor: blue),
                        child: const Text('CERRAR SESIÓN',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('ACCESO SEGURO',
                      style: TextStyle(color: blue, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Inicia sesión',
                      style: TextStyle(color: navy, fontSize: 34, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Ingresa tus datos para continuar.',
                      style: TextStyle(color: Color(0xFF526277), fontSize: 15)),
                  const SizedBox(height: 38),
                  const Text('Usuario', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                  const Text('Contraseña', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                      style: FilledButton.styleFrom(backgroundColor: blue),
                      child: Text(_busy ? 'VALIDANDO...' : 'INGRESAR',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(_message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _notice ? blue : const Color(0xFFB42318),
                            fontSize: 14,
                          )),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text('Demostración local · Sin conexión a un servidor',
                        style: TextStyle(color: Color(0xFF68788D), fontSize: 12)),
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
