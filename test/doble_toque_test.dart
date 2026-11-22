import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

// Blindaje · anti doble toque: 3 toques seguidos en «Iniciar sesión» envían UN login.
void main() {
  setUp(mockAudio);

  testWidgets('tres toques rápidos en Iniciar sesión → una sola petición', (tester) async {
    final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final state = api.appState()..status = AuthStatus.signedOut;
    addTearDown(state.dispose);
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), 'ana@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'Clave#2026');
    final boton = find.widgetWithText(FilledButton, 'Iniciar sesión');
    await tester.tap(boton);
    await tester.tap(boton, warnIfMissed: false);
    await tester.tap(boton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c == 'POST /auth/login'), hasLength(1));
    expect(state.status, AuthStatus.signedIn);
  });
}
