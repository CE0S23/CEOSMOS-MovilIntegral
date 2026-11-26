// 1.4.0 · Regresión: los campos de usuario no admiten espacios (acceso, registro,
// código, Perfil, Seguridad de la cuenta, Directorio, Citas y Soporte).
import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/sin_espacios.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/usuarios_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

TextEditingValue _aplicar(TextInputFormatter f, String antes, String despues) => f.formatEditUpdate(
  TextEditingValue(text: antes, selection: TextSelection.collapsed(offset: antes.length)),
  TextEditingValue(text: despues, selection: TextSelection.collapsed(offset: despues.length)),
);

void main() {
  group('Validadores', () {
    test('correo con espacios en cualquier posición → error', () {
      for (final v in [' ana@ceosmos.mx', 'ana@ceosmos.mx ', 'ana @ceosmos.mx', 'ana@ceos\tmos.mx']) {
        expect(AuthRepository.validarCorreo(v), SinEspacios.error, reason: v);
        expect(validarCorreoUsuario(v), SinEspacios.error, reason: v);
      }
    });

    test('contraseña, usuario, código y token con espacios → error', () {
      expect(AuthRepository.validarContrasenaLogin('clave con espacio'), SinEspacios.error);
      expect(AuthRepository.validarContrasenaNueva('Orbita# 2026'), SinEspacios.error);
      expect(AuthRepository.validarUsuario('ana maria'), SinEspacios.error);
      expect(AuthRepository.validarCodigoVerificacion('A1 B2C'), isNotNull);
      expect(AuthRepository.validarTokenRestablecer('0123456789 abcdef'), SinEspacios.error);
    });

    test('sin espacios siguen pasando', () {
      expect(AuthRepository.validarContrasenaLogin('Clave#2026'), isNull);
      expect(AuthRepository.validarUsuario('ana_maria'), isNull);
    });

    test('validador combinable', () {
      final v = SinEspacios.validador((s) => s!.isEmpty ? 'vacío' : null);
      expect(v('a b'), SinEspacios.error);
      expect(v(''), 'vacío');
      expect(v('ab'), isNull);
    });
  });

  group('Formateadores', () {
    test('barra espaciadora no escribe nada', () {
      final r = _aplicar(SinEspacios.formateador(), 'ana', 'ana ');
      expect(r.text, 'ana');
      expect(r.selection.baseOffset, 3);
    });

    test('lo pegado se limpia y el cursor queda al final', () {
      final r = _aplicar(SinEspacios.formateador(), '', '  ana @ ceosmos.mx\n');
      expect(r.text, 'ana@ceosmos.mx');
      expect(r.selection.baseOffset, r.text.length);
    });

    test('nombre de persona: sin inicial, dobles colapsados, uno entre palabras', () {
      final f = SinEspacios.nombrePersona();
      expect(_aplicar(f, '', ' ').text, '');
      expect(_aplicar(f, 'Ana ', 'Ana  ').text, 'Ana ');
      expect(_aplicar(f, '', '  Ana   María\tLópez').text, 'Ana María López');
      expect(_aplicar(f, 'Ana', 'Ana M').text, 'Ana M');
      expect(SinEspacios.normalizarNombrePersona('  Ana   María  '), 'Ana María');
    });
  });

  testWidgets('Inicio de sesión: el espacio no entra y se avisa con ícono y texto', (tester) async {
    mockAudio();
    final api = FakeCeosmosApi();
    final state = api.appState()..status = AuthStatus.signedOut;
    addTearDown(state.dispose);
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle();
    final correo = find.widgetWithText(TextFormField, 'Correo electrónico');
    await tester.enterText(correo, ' qa @ejemplo.com ');
    await tester.pump();
    expect(find.text('qa@ejemplo.com'), findsOneWidget);
    expect(find.text(SinEspacios.mensaje), findsOneWidget);
    expect(find.byIcon(Icons.space_bar), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'Cla ve#1');
    await tester.pump();
    final campo = tester.widget<EditableText>(
      find.descendant(of: find.widgetWithText(TextFormField, 'Contraseña'), matching: find.byType(EditableText)),
    );
    expect(campo.controller.text, 'Clave#1');
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
