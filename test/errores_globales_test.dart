import 'dart:ui';

import 'package:ceosmos_movil_integral/core/errores_globales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Blindaje · regresión: un error inesperado no cierra la app ni muestra texto técnico.
void main() {
  testWidgets('un widget que falla muestra el aviso amigable, no la traza', (tester) async {
    final onError = FlutterError.onError;
    final builder = ErrorWidget.builder;
    final plataforma = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = onError;
      ErrorWidget.builder = builder;
      PlatformDispatcher.instance.onError = plataforma;
    });
    instalarManejoGlobalDeErrores();

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (_) => throw StateError('fallo interno'))));

    // En depuración el error también llega al arnés de pruebas: se consume aquí.
    expect(tester.takeException(), isA<StateError>());
    expect(find.textContaining('no se pudo mostrar'), findsOneWidget);
    expect(find.textContaining('StateError'), findsNothing);
    expect(ultimoErrorNoControlado, isA<StateError>());
    // Los errores asíncronos no atrapados quedan marcados como manejados.
    expect(PlatformDispatcher.instance.onError!(Exception('x'), StackTrace.empty), isTrue);
    // Restaura antes de que el arnés lo verifique.
    FlutterError.onError = onError;
    ErrorWidget.builder = builder;
    PlatformDispatcher.instance.onError = plataforma;
  });
}


