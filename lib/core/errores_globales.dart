import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Último error no controlado (para diagnóstico; nunca se muestra en crudo).
Object? ultimoErrorNoControlado;

/// Red de seguridad global: ningún error inesperado cierra la app ni muestra
/// texto técnico al usuario.
///  * Errores del framework → se registran en el log (sin datos sensibles).
///  * Errores asíncronos no atrapados → se registran y se marcan como manejados.
///  * Un widget que falla al construirse → tarjeta amigable en lugar de la
///    pantalla roja (en release Flutter mostraría un hueco gris).
void instalarManejoGlobalDeErrores() {
  final anterior = FlutterError.onError;
  FlutterError.onError = (details) {
    ultimoErrorNoControlado = details.exception;
    if (kDebugMode && anterior != null) {
      anterior(details);
    } else {
      debugPrint('CEOSMOS error no controlado: ${details.exceptionAsString()}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ultimoErrorNoControlado = error;
    debugPrint('CEOSMOS error asíncrono no controlado: $error');
    return true; // manejado: la app sigue abierta
  };
  ErrorWidget.builder = (details) => ErrorAmigable(details: details);
}

/// Lo que ve el usuario cuando una parte de la pantalla no se pudo dibujar.
class ErrorAmigable extends StatelessWidget {
  const ErrorAmigable({super.key, this.details});
  final FlutterErrorDetails? details;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFFFF4E5),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Text(
          'Esta parte de la pantalla no se pudo mostrar.\n'
          'Vuelve atrás e inténtalo de nuevo; tus datos están a salvo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF5D4037), fontSize: 14),
        ),
      ),
    );
  }
}
