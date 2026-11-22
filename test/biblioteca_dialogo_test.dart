import 'package:ceosmos_movil_integral/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

// Blindaje · regresiones del usuario torpe en la Tab S9 (22/11):
//  1. «Agregar a mi biblioteca» no se desborda con teclado abierto y errores.
//  2. Borrar de la biblioteca pide confirmación.
void main() {
  setUp(mockAudio);

  Future<FakeCeosmosApi> abrirBiblioteca(
    WidgetTester tester,
    Size tamano,
  ) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final api = FakeCeosmosApi()
      ..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final state = api.appState();
    addTearDown(state.dispose);
    await state.acceptSession(
      await state.auth.login('ana@example.com', 'Clave#2026'),
    );
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.tap(find.byIcon(Icons.explore_outlined).last);
    await tester.pumpAndSettle();
    final agregar = find.widgetWithText(TextButton, 'Agregar');
    await tester.ensureVisible(agregar);
    await tester.tap(agregar);
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('diálogo con teclado abierto y errores no se desborda', (
    tester,
  ) async {
    await abrirBiblioteca(tester, const Size(800, 600));
    tester.view.viewInsets = const FakeViewPadding(
      bottom: 380,
    ); // teclado de la tablet
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Usa una URL https.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('borrar de la biblioteca pide confirmación', (tester) async {
    final api = await abrirBiblioteca(tester, const Size(412, 915));
    // La miniatura queda «cargando» (sin red en las pruebas): pasos fijos en vez de pumpAndSettle.
    Future<void> asentar() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first,
      'https://img.example/calma.jpg',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await asentar();
    expect(api.calls, contains('POST /media'));

    final borrar = find.byTooltip('Eliminar de mi biblioteca');
    await tester.ensureVisible(borrar);
    await tester.tap(borrar);
    await asentar();
    expect(find.text('¿Eliminar de tu biblioteca?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await asentar();
    expect(api.calls.where((c) => c.startsWith('DELETE /media')), isEmpty);

    await tester.tap(borrar);
    await asentar();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await asentar();
    expect(api.calls.where((c) => c.startsWith('DELETE /media')), hasLength(1));
  });
}
