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
  /// texto (SnackBar) cada vez que se descarta un espacio.
  static TextInputFormatter formateador([BuildContext? context]) =>
      _SinEspaciosFormatter(context == null ? null : () => avisar(context));

  /// Lista lista para `inputFormatters`.
  static List<TextInputFormatter> formateadores([BuildContext? context]) => [
    formateador(context),
  ];

  static DateTime _ultimoAviso = DateTime.fromMillisecondsSinceEpoch(0);

  /// Aviso visible con ícono + texto (no solo color). Se limita a uno cada 2 s.
  static void avisar(BuildContext context) {
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoAviso) < const Duration(seconds: 2)) return;
    _ultimoAviso = ahora;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          key: ValueKey('aviso-sin-espacios'),
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.space_bar, semanticLabel: 'Aviso'),
              SizedBox(width: 12),
              Expanded(child: Text(mensaje)),
            ],
          ),
        ),
      );
  }

  /// Nombre de persona: quita espacios al inicio y al final y colapsa los dobles.
  static String normalizarNombrePersona(String v) => v.trim().replaceAll(_espacios, ' ');

  /// Formateador para nombres de persona mientras se escribe: sin espacio inicial ni
  /// dobles (el espacio final se permite para seguir escribiendo la palabra siguiente).
  static TextInputFormatter nombrePersona() => const _NombrePersonaFormatter();
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
