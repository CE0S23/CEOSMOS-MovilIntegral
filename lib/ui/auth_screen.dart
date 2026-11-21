import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../data/api_client.dart';
import '../data/auth_repository.dart';
import 'theme.dart';
import 'widgets.dart';

/// Pasos del acceso contra la API de CEOSMOS.
enum _Paso { login, registro, verificar, olvide, restablecer }

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
      _password = TextEditingController(),
      _code = TextEditingController(),
      _token = TextEditingController();
  _Paso _paso = _Paso.login;
  bool _obscure = true, _busy = false;
  String? _error, _info;

  @override
  void initState() {
    super.initState();
    _info = widget.state.takeNotice();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _code, _token]) {
      c.dispose();
    }
    super.dispose();
  }

  void _ir(_Paso paso, {String? info}) => setState(() {
    _paso = paso;
    _error = null;
    _info = info;
    _password.clear();
    _code.clear();
  });

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await accion();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (_paso == _Paso.login && e.message.contains('no está verificado')) {
        setState(() => _paso = _Paso.verificar);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  AuthRepository get _auth => widget.state.auth;

  Future<void> _enviar() => switch (_paso) {
    _Paso.login => _ejecutar(() async {
      final session = await _auth.login(_email.text, _password.text);
      await widget.state.acceptSession(session);
    }),
    _Paso.registro => _ejecutar(() async {
      await _auth.register(_name.text, _email.text, _password.text);
      _ir(
        _Paso.verificar,
        info:
            'Cuenta creada. Escribe el código de 6 caracteres que enviamos a ${_email.text.trim()}.',
      );
    }),
    _Paso.verificar => _ejecutar(() async {
      await _auth.verifyEmail(_email.text, _code.text);
      _ir(_Paso.login, info: 'Correo verificado. Ya puedes iniciar sesión.');
    }),
    _Paso.olvide => _ejecutar(() async {
      await _auth.forgotPassword(_email.text);
      _ir(
        _Paso.restablecer,
        info:
            'Si el correo está registrado, recibirás un enlace. Copia el código del enlace (token) aquí.',
      );
    }),
    _Paso.restablecer => _ejecutar(() async {
      await _auth.resetPassword(_token.text, _password.text);
      _ir(_Paso.login, info: 'Contraseña actualizada. Inicia sesión.');
    }),
  };

  Future<void> _reenviar() async {
    if (AuthRepository.validarCorreo(_email.text) != null) {
      setState(() => _error = 'Escribe primero tu correo.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _auth.resendVerification(_email.text);
      if (mounted) setState(() => _info = 'Enviamos un código nuevo.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  (String, String, String) get _textos => switch (_paso) {
    _Paso.login => ('Vuelve a tu centro.', 'Menos ruido. Más enfoque. Un momento para ti.', 'Iniciar sesión'),
    _Paso.registro => ('Un nuevo comienzo.', 'Crea tu cuenta de CEOSMOS. Te enviaremos un código para verificar tu correo.', 'Crear cuenta'),
    _Paso.verificar => ('Verifica tu correo.', 'Escribe el código de 6 caracteres que recibiste.', 'Verificar'),
    _Paso.olvide => ('Recupera tu acceso.', 'Te enviaremos un enlace para crear una contraseña nueva.', 'Enviar enlace'),
    _Paso.restablecer => ('Nueva contraseña.', 'Pega el código del enlace y elige tu nueva contraseña.', 'Guardar contraseña'),
  };

  Widget _campoContrasena({required bool nueva}) => TextFormField(
    key: const ValueKey('campo-contrasena'),
    controller: _password,
    obscureText: _obscure,
    onFieldSubmitted: (_) => _enviar(),
    decoration: InputDecoration(
      labelText: nueva ? 'Contraseña nueva' : 'Contraseña',
      helperText: nueva ? 'Mayúscula, minúscula, número y símbolo (8+).' : null,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      ),
    ),
    validator: nueva
        ? AuthRepository.validarContrasenaNueva
        : AuthRepository.validarContrasenaLogin,
  );

  @override
  Widget build(BuildContext context) {
    final (titulo, subtitulo, boton) = _textos;
    final campos = <Widget>[
      if (_paso == _Paso.registro) ...[
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nombre de usuario',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textInputAction: TextInputAction.next,
          validator: AuthRepository.validarUsuario,
        ),
        const SizedBox(height: 14),
      ],
      if (_paso != _Paso.restablecer) ...[
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: AuthRepository.validarCorreo,
        ),
        const SizedBox(height: 14),
      ],
      if (_paso == _Paso.verificar)
        TextFormField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          onFieldSubmitted: (_) => _enviar(),
          decoration: const InputDecoration(
            labelText: 'Código de verificación',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          validator: AuthRepository.validarCodigoVerificacion,
        ),
      if (_paso == _Paso.restablecer) ...[
        TextFormField(
          controller: _token,
          decoration: const InputDecoration(
            labelText: 'Código del enlace',
            prefixIcon: Icon(Icons.key_outlined),
          ),
          validator: AuthRepository.validarTokenRestablecer,
        ),
        const SizedBox(height: 14),
      ],
      if (_paso == _Paso.login) _campoContrasena(nueva: false),
      if (_paso == _Paso.registro || _paso == _Paso.restablecer) _campoContrasena(nueva: true),
    ];

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Brand(),
              const SizedBox(height: Espacio.xxl),
              const Align(alignment: Alignment.centerLeft, child: Tag('TU ESPACIO PERSONAL')),
              const SizedBox(height: Espacio.l + 4),
              Text(
                titulo,
                style: context.texto.headlineLarge?.copyWith(color: context.paleta.marca),
              ),
              const SizedBox(height: Espacio.m),
              Text(
                subtitulo,
                style: context.texto.bodyLarge?.copyWith(color: context.paleta.textoSecundario),
              ),
              const SizedBox(height: Espacio.xxl - 2),
              ...campos,
              if (_info != null) ...[
                const SizedBox(height: Espacio.m + 2),
                Aviso(_info!, tipo: TipoAviso.exito),
              ],
              if (_error != null) ...[
                const SizedBox(height: Espacio.m + 2),
                Semantics(
                  liveRegion: true,
                  child: Aviso(_error!),
                ),
              ],
              const SizedBox(height: Espacio.xl),
              FilledButton(
                onPressed: _busy ? null : _enviar,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(boton),
              ),
              const SizedBox(height: 8),
              if (_paso == _Paso.login) ...[
                TextButton(
                  onPressed: _busy ? null : () => _ir(_Paso.registro),
                  child: const Text('¿Primera vez? Crea una cuenta'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _ir(_Paso.olvide),
                  child: const Text('Olvidé mi contraseña'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _ir(_Paso.verificar),
                  child: const Text('Tengo un código de verificación'),
                ),
              ] else ...[
                if (_paso == _Paso.verificar)
                  TextButton(
                    onPressed: _busy ? null : _reenviar,
                    child: const Text('Reenviar código'),
                  ),
                if (_paso == _Paso.olvide)
                  TextButton(
                    onPressed: _busy ? null : () => _ir(_Paso.restablecer),
                    child: const Text('Ya tengo el código del enlace'),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _ir(_Paso.login),
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final wide = bounds.maxWidth > 900;
            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 48 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (bounds.maxHeight - (wide ? 96 : 48)).clamp(0, double.infinity),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (wide) ...[
                      Expanded(
                        // Patrón de curvas de la paleta; el texto va sobre un
                        // bloque guinda propio, nunca directamente sobre las líneas.
                        child: CurvasCeosmos(
                          height: 690,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              margin: const EdgeInsets.all(Espacio.xxl),
                              padding: const EdgeInsets.all(Espacio.xxl),
                              decoration: BoxDecoration(
                                color: CeosmosColores.guinda,
                                borderRadius: Radios.bordeL,
                                boxShadow: Sombra.elevada,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Tag('UN SOLO ECOSISTEMA', color: CeosmosColores.cian),
                                  const SizedBox(height: Espacio.l + 4),
                                  Text(
                                    'Tu universo.\nA tu ritmo.',
                                    style: context.texto.displayLarge?.copyWith(color: CeosmosColores.blanco),
                                  ),
                                  const SizedBox(height: Espacio.l + 2),
                                  Text(
                                    'Concentración, calma e inspiración.\nAhora, en un mismo lugar.',
                                    style: context.texto.bodyLarge?.copyWith(color: CeosmosColores.guindaClaro),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 70),
                    ],
                    Flexible(
                      child: wide
                          ? form
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Franja decorativa de la paleta (sin texto encima).
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 420),
                                  child: const CurvasCeosmos(height: 56, radio: Radios.m),
                                ),
                                const SizedBox(height: Espacio.l),
                                form,
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
