import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_p07.dart'; // [CEOSMOS]
import 'screens/home_screen.dart';
import 'screens/rol_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // [CEOSMOS] En lugar de la app [DEFAULT] se inicializa la app con nombre
  // «practica7» (ver firebase_p07.dart). Equivale a la inicialización original.
  await FirebaseP07.inicializar();
  final auth = AuthService();
  await auth.iniciar();
  runApp(
    ChangeNotifierProvider.value(value: auth, child: const Practica7App()),
  );
}

/// [CEOSMOS] Punto de entrada dentro de CEOSMOS: hace lo mismo que `main()`
/// (Firebase + AuthService) y libera el servicio al salir de la práctica.
class Practica7Entrada extends StatefulWidget {
  const Practica7Entrada({super.key});

  @override
  State<Practica7Entrada> createState() => _Practica7EntradaState();
}

class _Practica7EntradaState extends State<Practica7Entrada> {
  AuthService? _auth;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    setState(() => _error = null);
    try {
      await FirebaseP07.inicializar();
      final auth = AuthService();
      await auth.iniciar();
      if (!mounted) {
        auth.dispose();
        return;
      }
      setState(() => _auth = auth);
    } catch (e, pila) {
      debugPrint('[P07] Error al iniciar Firebase: $e');
      debugPrint('$pila');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _auth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth != null) {
      return ChangeNotifierProvider.value(
        value: auth,
        child: const Practica7App(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('No se pudo conectar con Firebase: $_error',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _iniciar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class Practica7App extends StatelessWidget {
  const Practica7App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Práctica 7',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: Consumer<AuthService>(
      builder: (context, auth, _) =>
          auth.actual == null ? const RolScreen() : const HomeScreen(),
    ),
  );
}
