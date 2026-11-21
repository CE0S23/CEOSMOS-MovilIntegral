import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/rol_url.dart';
import '../../../ui/widgets.dart' show Aviso;

class RolScreen extends StatefulWidget {
  const RolScreen({super.key});

  @override
  State<RolScreen> createState() => _RolScreenState();
}

class _RolScreenState extends State<RolScreen> {
  static const _correosPorRol = {
    'admin': 'admin.ceosmos.p7@example.com',
    'agente': 'agente.ceosmos.p7@example.com',
    'usuario1': 'usuario1.ceosmos.p7@example.com',
    'usuario2': 'usuario2.ceosmos.p7@example.com',
  };

  final _url = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  String? _error;
  bool _ocupado = false;
  bool _mostrarClave = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && rolDesdeUrl(Uri.base.toString()) != null) {
      _url.text = Uri.base.toString();
      _correo.text = _correosPorRol[rolDesdeUrl(_url.text)]!;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final url = _url.text.trim();
    final rol = url.isEmpty ? null : rolDesdeUrl(url);
    if (url.isNotEmpty && rol == null) {
      setState(() => _error = 'URL de rol inválida');
      return;
    }
    final correo = _correo.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      setState(() => _error = 'Escribe un correo válido');
      return;
    }
    if (!_correosPorRol.containsValue(correo)) {
      setState(() => _error = 'Cuenta no autorizada');
      return;
    }
    if (_clave.text.isEmpty) {
      setState(() => _error = 'Escribe el correo y la contraseña');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().entrar(rol, correo, _clave.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' => 'Correo o contraseña incorrectos',
            'network-request-failed' => 'Sin conexión. Intenta de nuevo.',
            _ => 'No se pudo iniciar sesión: ${e.message ?? e.code}',
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo entrar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entrar a Soporte')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: _url,
                onChanged: (valor) {
                  final rol = rolDesdeUrl(valor);
                  if (rol != null) {
                    _correo.text = _correosPorRol[rol]!;
                    _clave.clear();
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'URL de rol (opcional)',
                  hintText: 'https://practica7.app/rol/usuario1',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _correo,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _clave,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _mostrarClave
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: () =>
                        setState(() => _mostrarClave = !_mostrarClave),
                    icon: Icon(
                      _mostrarClave ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !_mostrarClave,
                autofillHints: const [AutofillHints.password],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Aviso(_error!),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _ocupado ? null : _entrar,
                child: const Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
