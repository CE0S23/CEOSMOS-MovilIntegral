import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ceosmos_movil_integral/practicas/examen1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

// Simula la respuesta del dispositivo, incluyendo errores y escrituras lentas.
class AlmacenPrueba extends InMemorySharedPreferencesStore {
  AlmacenPrueba() : super.empty();

  bool fallar = false;
  bool lanzarError = false;
  Completer<void>? espera;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (espera != null) await espera!.future;
    if (lanzarError) throw StateError('Almacenamiento no disponible');
    if (fallar) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  late AlmacenPrueba almacen;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    almacen = AlmacenPrueba();
    SharedPreferencesStorePlatform.instance = almacen;
  });

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const IncidenciasApp());
    await tester.pumpAndSettle();
  }

  Future<void> capturar(
    WidgetTester tester,
    String equipo,
    String detalle,
  ) async {
    await tester.enterText(find.byType(TextFormField).at(0), equipo);
    await tester.enterText(find.byType(TextFormField).at(1), detalle);
    await tester.ensureVisible(find.text('Guardar incidencia'));
    await tester.tap(find.text('Guardar incidencia'));
    await tester.pumpAndSettle();
  }

  Future<List<dynamic>> registros() async {
    final datos = await almacen.getAll();
    return jsonDecode(datos['flutter.examen1.incidencias'] as String? ?? '[]') as List;
  }

  testWidgets(
    'Muestra los controles requeridos y rechaza campos vacíos o espacios',
    (tester) async {
      await abrir(tester);
      expect(find.text('Incidencias de Soporte'), findsOneWidget);
      expect(find.text('Nombre del equipo'), findsOneWidget);
      expect(find.text('Descripción de la incidencia'), findsOneWidget);
      await capturar(tester, '   ', '   ');
      expect(
        find.text('El campo "Nombre del equipo" es obligatorio'),
        findsOneWidget,
      );
      expect(
        find.text('El campo "Descripción de la incidencia" es obligatorio'),
        findsOneWidget,
      );
      expect(await registros(), isEmpty);
      await capturar(tester, 'Laptop', '');
      expect(await registros(), isEmpty);
      await capturar(tester, '', 'No enciende');
      expect(await registros(), isEmpty);
    },
  );

  testWidgets(
    'Guarda tres incidencias, limpia controles y recupera al reabrir',
    (tester) async {
      await abrir(tester);
      for (var i = 1; i <= 3; i++) {
        await capturar(
          tester,
          '  Equipo $i  ',
          '  Falla $i: conexión y pantalla  ',
        );
        for (final campo in tester.widgetList<TextFormField>(
          find.byType(TextFormField),
        )) {
          expect(campo.controller!.text, isEmpty);
        }
      }
      final datos = await registros();
      expect(datos, hasLength(3));
      expect(datos.first['equipo'], 'Equipo 3');
      expect(datos.first['descripcion'], 'Falla 3: conexión y pantalla');
      expect(datos.map((e) => e['id']).toSet(), hasLength(3));

      // Destruye la pantalla y su estado para obligar a leer el almacenamiento.
      await tester.pumpWidget(const SizedBox());
      await abrir(tester);
      expect(find.text('Incidencias registradas (3)'), findsOneWidget);
      for (var i = 1; i <= 3; i++) {
        expect(find.text('Equipo $i'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Elimina solo el registro seleccionado y conserva el cambio al reabrir',
    (tester) async {
      await abrir(tester);
      await capturar(tester, 'Laptop', 'No enciende');
      await capturar(tester, 'Impresora', 'Papel atascado');
      final tarjeta = find.ancestor(
        of: find.text('Laptop'),
        matching: find.byType(Card),
      );
      final eliminar = find.descendant(
        of: tarjeta,
        matching: find.byIcon(Icons.delete),
      );
      await tester.ensureVisible(eliminar);
      await tester.tap(eliminar);
      await tester.pumpAndSettle();
      expect((await registros()).single['equipo'], 'Impresora');
      await tester.pumpWidget(const SizedBox());
      await abrir(tester);
      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Impresora'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(await registros(), isEmpty);
      expect(find.text('No hay incidencias registradas'), findsOneWidget);
    },
  );

  testWidgets('Si guardar falla conserva la captura y permite reintentar', (
    tester,
  ) async {
    await abrir(tester);
    almacen.fallar = true;
    await capturar(tester, 'Laptop', 'No enciende');
    expect(await registros(), isEmpty);
    expect(find.text('Incidencias registradas (0)'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Laptop',
    );
    expect(find.textContaining('No se pudo guardar.'), findsOneWidget);
    almacen.fallar = false;
    await tester.tap(find.text('Guardar incidencia'));
    await tester.pumpAndSettle();
    expect(await registros(), hasLength(1));
  });

  testWidgets('Si eliminar lanza error conserva la incidencia', (tester) async {
    await abrir(tester);
    await capturar(tester, 'Laptop', 'No enciende');
    almacen.lanzarError = true;
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    expect(await registros(), hasLength(1));
    expect(find.text('No se pudo eliminar. Intenta de nuevo.'), findsOneWidget);
  });

  testWidgets('No sobrescribe datos ilegibles y permite reintentar la carga', (
    tester,
  ) async {
    await almacen.setValue('String', 'flutter.examen1.incidencias', 'JSON dañado');
    await abrir(tester);
    expect(find.textContaining('No se pudieron leer'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect((await almacen.getAll())['flutter.examen1.incidencias'], 'JSON dañado');
    await almacen.setValue('String', 'flutter.examen1.incidencias', '[]');
    await tester.tap(find.text('Reintentar carga'));
    await tester.pumpAndSettle();
    expect(find.text('No hay incidencias registradas'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Bloquea pulsaciones repetidas durante el guardado', (
    tester,
  ) async {
    await abrir(tester);
    almacen.espera = Completer<void>();
    await capturar(tester, 'Laptop', 'No enciende');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Guardar incidencia'));
    almacen.espera!.complete();
    await tester.pumpAndSettle();
    expect(await registros(), hasLength(1));
  });

  testWidgets('Cerrar la pantalla durante el guardado no genera excepciones', (
    tester,
  ) async {
    await abrir(tester);
    almacen.espera = Completer<void>();
    await capturar(tester, 'Laptop', 'No enciende');
    await tester.pumpWidget(const SizedBox());
    almacen.espera!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await registros(), hasLength(1));
  });

  testWidgets('El formulario se puede desplazar con teclado y en horizontal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await abrir(tester);
    await tester.ensureVisible(find.text('Guardar incidencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar incidencia'));
    await tester.pumpAndSettle();
    expect(
      find.text('El campo "Nombre del equipo" es obligatorio'),
      findsOneWidget,
    );
    expect(
      find.text('El campo "Descripción de la incidencia" es obligatorio'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
