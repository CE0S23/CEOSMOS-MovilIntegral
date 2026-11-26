import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reglas de espacios en los campos de usuario (1.4.0).
///
/// - Correo, nombre de usuario, matrícula, códigos y contraseñas: sin espacios en
///   ninguna posición. La barra espaciadora no escribe nada y lo pegado se limpia.
/// - Nombres de persona: sin espacios al inicio, los dobles se colapsan en uno y al
///   guardar se quitan los del final ([normalizarNombrePersona]).
///
/// La API aplica la misma regla como defensa (`@SinEspacios` en los DTO).
abstract final class SinEspacios {
  static final _espacio = RegExp(r'\s');
  static final _espacios = RegExp(r'\s+');

  /// Mensaje que se muestra cuando se rechaza un espacio.
  static const mensaje = 'Este campo no admite espacios. Los quitamos por ti.';

  /// Texto del validador cuando el valor trae espacios (defensa si llegó por otra vía).
  static const error = 'No uses espacios.';

  static bool tieneEspacios(String? v) => v != null && _espacio.hasMatch(v);

  static String quitar(String v) => v.replaceAll(_espacio, '');

  /// Validador combinable: rechaza cualquier espacio y luego delega en [otro].
  static FormFieldValidator<String> validador([FormFieldValidator<String>? otro]) =>
      (v) => tieneEspacios(v) ? error : otro?.call(v);

  /// Formateador que quita todo espacio. Si [context] no es nulo avisa con ícono y
  /// texto ([AvisoSinEspacios]) cada vez que se descarta un espacio.
  static TextInputFormatter formateador([BuildContext? context]) =>
      _SinEspaciosFormatter(context == null ? null : () => avisar(context));

  /// Lista lista para `inputFormatters`.
  static List<TextInputFormatter> formateadores([BuildContext? context]) => [
    formateador(context),
  ];

  static DateTime _ultimoAviso = DateTime.fromMillisecondsSinceEpoch(0);
  static OverlayEntry? _aviso;

  /// Duración del aviso en pantalla.
  static const duracionAviso = Duration(seconds: 3);

  /// Aviso visible con ícono + texto (no solo color). Se limita a uno cada 2 s.
  ///
  /// 1.4.0: se pinta en el Overlay más cercano (por encima de la capa oscura de los
  /// diálogos, que antes lo tapaba porque era un SnackBar del Scaffold de atrás), con
  /// colores explícitos (antes el ícono heredaba un color igual al fondo) y dentro de
  /// una región viva para que TalkBack lo anuncie.
  static void avisar(BuildContext context) {
    if (!context.mounted) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoAviso) < const Duration(seconds: 2)) return;
    _ultimoAviso = ahora;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    cerrarAviso();
    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (_) => AvisoSinEspacios(
        alTerminar: () {
          if (identical(_aviso, entrada)) cerrarAviso();
        },
      ),
    );
    _aviso = entrada;
    overlay.insert(entrada);
  }

  /// Quita el aviso si está en pantalla.
  static void cerrarAviso() {
    final e = _aviso;
    _aviso = null;
    if (e != null && e.mounted) e.remove();
  }

  @visibleForTesting
  static void reiniciarAviso() {
    cerrarAviso();
    _ultimoAviso = DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Nombre de persona: quita espacios al inicio y al final y colapsa los dobles.
  static String normalizarNombrePersona(String v) => v.trim().replaceAll(_espacios, ' ');

  /// Formateador para nombres de persona mientras se escribe: sin espacio inicial ni
  /// dobles (el espacio final se permite para seguir escribiendo la palabra siguiente).
  static TextInputFormatter nombrePersona() => const _NombrePersonaFormatter();
}

/// Aviso «sin espacios»: tarjeta con ícono y texto sobre la parte baja de la pantalla
/// (encima del teclado), contraste AA (colores inversos del tema) y región viva.
/// Se quita solo a los [SinEspacios.duracionAviso] (el temporizador vive con el widget).
class AvisoSinEspacios extends StatefulWidget {
  const AvisoSinEspacios({super.key, this.alTerminar});
  final VoidCallback? alTerminar;

  @override
  State<AvisoSinEspacios> createState() => _AvisoSinEspaciosState();
}

class _AvisoSinEspaciosState extends State<AvisoSinEspacios> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(SinEspacios.duracionAviso, () => widget.alTerminar?.call());
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: mq.viewInsets.bottom + mq.padding.bottom + 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, minHeight: 48),
          child: Semantics(
            key: const ValueKey('aviso-sin-espacios'),
            container: true,
            liveRegion: true,
            label: 'Aviso: ${SinEspacios.mensaje}',
            excludeSemantics: true,
            child: Material(
              color: esquema.inverseSurface,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.space_bar, color: esquema.onInverseSurface, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        SinEspacios.mensaje,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: esquema.onInverseSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SinEspaciosFormatter extends TextInputFormatter {
  _SinEspaciosFormatter(this.alRechazar);
  final VoidCallback? alRechazar;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!SinEspacios.tieneEspacios(newValue.text)) return newValue;
    alRechazar?.call();
    return _limpiar(newValue, (t) => SinEspacios.quitar(t));
  }
}

class _NombrePersonaFormatter extends TextInputFormatter {
  const _NombrePersonaFormatter();
  static final _dobles = RegExp(r'\s{2,}|[\t\n\r]');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    if (!t.startsWith(RegExp(r'\s')) && !_dobles.hasMatch(t)) return newValue;
    return _limpiar(newValue, (s) => s.replaceAll(RegExp(r'\s+'), ' ').trimLeft());
  }
}

/// Aplica [f] y recoloca el cursor según lo que quedó antes de él.
TextEditingValue _limpiar(TextEditingValue v, String Function(String) f) {
  final texto = f(v.text);
  final fin = v.selection.end.clamp(0, v.text.length);
  final cursor = f(v.text.substring(0, fin)).length.clamp(0, texto.length);
  return TextEditingValue(
    text: texto,
    selection: TextSelection.collapsed(offset: cursor),
  );
}
