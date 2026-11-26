/// Singular y plural de los textos con contador (1.4.0): «1 sesión», «2 sesiones»,
/// «0 sesiones». En español solo el 1 (y el −1) va en singular.
///
/// ```dart
/// contar(n, 'sesión', 'sesiones')                         // «1 sesión»
/// contar(n, 'experiencia guardada', 'experiencias guardadas')
/// ```
String contar(num n, String singular, String plural) => '${_numero(n)} ${palabra(n, singular, plural)}';

/// Solo la palabra que corresponde a [n] (para frases donde el número va aparte).
String palabra(num n, String singular, String plural) => n.abs() == 1 ? singular : plural;

String _numero(num n) => n is int || n == n.truncate() ? '${n.toInt()}' : '$n';
