import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// [CEOSMOS] Cada práctica Flutter trae su propio `MaterialApp`. En Android 14+
/// (atrás predictivo) el `WidgetsApp` interno le dice al sistema que el framework
/// NO maneja Atrás cuando su Navigator está en la raíz, y Android cerraba CEOSMOS
/// completo en lugar de volver a «Prácticas». Dentro de CEOSMOS el Atrás siempre lo
/// maneja `PracticaHost` (primero la práctica y luego la lista), así que se informa
/// `true` y se detiene la notificación aquí.
bool atrasManejadoPorCeosmos(NavigationNotification _) {
  SystemNavigator.setFrameworkHandlesBack(true);
  return true;
}
