import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/auth_repository.dart';
import 'theme.dart';
import 'widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  bool _register = false, _obscure = true, _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({bool demo = false}) async {
    if (_busy || (!demo && !_form.currentState!.validate())) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = widget.state.auth;
      final session = demo
          ? await auth.enterDemo()
          : _register
          ? await auth.register(_name.text, _email.text, _password.text)
          : await auth.login(_email.text, _password.text);
      if (mounted) widget.state.acceptSession(session);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos abrir tu sesión. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final wide = bounds.maxWidth > 900;
          final form = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Brand(),
                  const SizedBox(height: 36),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Tag('TU ESPACIO PERSONAL'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _register ? 'Un nuevo comienzo.' : 'Vuelve a tu centro.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _register
                        ? 'Crea una cuenta para explorar tu propio cosmos.'
                        : 'Menos ruido. Más enfoque. Un momento para ti.',
                    style: const TextStyle(color: Cosmos.muted),
                  ),
                  const SizedBox(height: 30),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Escribe al menos 2 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) =>
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v?.trim() ?? '')
                        ? 'Escribe un correo válido.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        tooltip: _obscure
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => (v?.length ?? 0) < 8
                        ? 'Usa al menos 8 caracteres.'
                        : null,
                  ),
                  if (_error != null || widget.state.notice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        _error ?? widget.state.notice!,
                        style: const TextStyle(color: Cosmos.peach),
                      ),
                    ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _busy ? null : () => _submit(),
                    child: Text(
                      _busy
                          ? 'Abriendo tu espacio…'
                          : _register
                          ? 'Crear cuenta local'
                          : 'Iniciar sesión',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _submit(demo: true),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Explorar demo'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _register = !_register;
                              _error = null;
                            });
                            _form.currentState?.reset();
                          },
                    child: Text(
                      _register
                          ? 'Ya tengo cuenta · Iniciar sesión'
                          : '¿Primera vez? Crea una cuenta',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Demostración local · Sin conexión a servidores\nLas cuentas y tu actividad se borran al reiniciar la app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Cosmos.muted, fontSize: 12),
                  ),
                  TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Passkeys en la siguiente integración',
                        ),
                        content: const Text(
                          'El proyecto web utiliza WebAuthn. Esta entrega local no verifica huellas ni crea passkeys. La integración real requiere la API, un dominio verificado y la configuración nativa de Android/iOS.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.fingerprint, size: 18),
                    label: const Text('Acerca del acceso con passkey'),
                  ),
                ],
              ),
            ),
          );
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 48 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (bounds.maxHeight - (wide ? 96 : 48)).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (wide) ...[
                    Expanded(
                      child: CosmosScene(
                        height: 690,
                        child: Padding(
                          padding: const EdgeInsets.all(44),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Tag(
                                'UN SOLO ECOSISTEMA',
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Tu universo.\nA tu ritmo.',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(fontSize: 56),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Concentración, calma e inspiración.\nAhora, en un mismo lugar.',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Cosmos.muted,
                                ),
                              ),
                              const SizedBox(height: 36),
                              const Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  Tag(
                                    'Móvil',
                                    icon: Icons.smartphone,
                                    color: Colors.white,
                                  ),
                                  Tag(
                                    'Wearable',
                                    icon: Icons.watch_outlined,
                                    color: Colors.white,
                                  ),
                                  Tag(
                                    'TV',
                                    icon: Icons.tv,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 70),
                  ],
                  Flexible(child: form),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
