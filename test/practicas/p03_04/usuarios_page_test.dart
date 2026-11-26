import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/app_database.dart';
import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/usuario.dart';
import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/usuario_dao.dart';
import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/usuarios_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DaoDePrueba implements UsuarioDao {
  final registros = <Usuario>[];
  int consultas = 0;
  int siguienteId = 1;

  @override
  Future<List<Usuario>> obtenerTodos() async {
    consultas++;
    return List.of(registros);
  }

  @override
  Future<void> insertar(Usuario usuario) async {
    registros.add(
      Usuario(
        id: siguienteId++,
        nombre: usuario.nombre,
        edad: usuario.edad,
        profesion: usuario.profesion,
        correo: usuario.correo,
      ),
    );
  }

  @override
  Future<void> actualizar(Usuario usuario) async {
    registros[registros.indexWhere((otro) => otro.id == usuario.id)] = usuario;
  }

  @override
  Future<void> eliminar(Usuario usuario) async {
    registros.removeWhere((otro) => otro.id == usuario.id);
  }
}

class BaseDePrueba extends Fake implements AppDatabase {
  BaseDePrueba(this.usuarioDao);

  @override
  final UsuarioDao usuarioDao;
}

Future<void> mostrar(WidgetTester tester, DaoDePrueba dao) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UsuariosPage(baseDeDatos: Future.value(BaseDePrueba(dao))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pulsar(WidgetTester tester, String texto) async {
  final boton = find.text(texto);
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Valida nombre, edad y profesión antes de insertar', (
    tester,
  ) async {
    final dao = DaoDePrueba();
    await mostrar(tester, dao);
    await pulsar(tester, 'REGISTRAR');
    expect(find.text('Ingresa el nombre.'), findsOneWidget);
    expect(find.text('Ingresa la profesión.'), findsOneWidget);
    expect(find.text('Ingresa una edad entera entre 1 y 120.'), findsOneWidget);
    expect(find.text('Ingresa el correo.'), findsOneWidget);
    // 1.4.0: el campo ya no deja escribir espacios (se limpian), así que no se prueban aquí.
    for (final correo in ['sin-arroba', 'a@b']) {
      await tester.enterText(find.byType(TextFormField).at(3), correo);
      await pulsar(tester, 'REGISTRAR');
      expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    }
    for (final edad in ['0', '121', '2.5', 'abc']) {
      await tester.enterText(find.byType(TextFormField).at(1), edad);
      await pulsar(tester, 'REGISTRAR');
      expect(
        find.text('Ingresa una edad entera entre 1 y 120.'),
        findsOneWidget,
      );
    }
    expect(dao.registros, isEmpty);
    expect(dao.consultas, 0);
  });

  testWidgets('Consulta explícita y refresco al insertar, editar y eliminar', (
    tester,
  ) async {
    final dao = DaoDePrueba();
    await mostrar(tester, dao);
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), '24');
    await tester.enterText(find.byType(TextFormField).at(2), 'Ingeniera');
    await tester.enterText(find.byType(TextFormField).at(3), 'Ana@Correo.MX');
    await pulsar(tester, 'REGISTRAR');
    expect(dao.registros, hasLength(1));
    expect(dao.consultas, 0);
    expect(find.byType(ListTile), findsNothing);

    await pulsar(tester, 'VER usuarios');
    expect(dao.consultas, 1);
    expect(find.text('Ana'), findsOneWidget);
    await tester.ensureVisible(find.byType(ListTile));
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.text('ACTUALIZAR'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana María');
    await pulsar(tester, 'ACTUALIZAR');
    expect(dao.consultas, 2);
    expect(dao.registros.single.nombre, 'Ana María');
    expect(dao.registros.single.correo, 'ana@correo.mx');

    await tester.enterText(find.byType(TextFormField).at(0), 'Luis');
    await tester.enterText(find.byType(TextFormField).at(1), '30');
    await tester.enterText(find.byType(TextFormField).at(2), 'Docente');
    await tester.enterText(find.byType(TextFormField).at(3), 'luis@uni.mx');
    await pulsar(tester, 'REGISTRAR');
    expect(dao.consultas, 3);
    expect(dao.registros, hasLength(2));

    final eliminar = find.byTooltip('Eliminar usuario').first;
    await tester.ensureVisible(eliminar);
    await tester.tap(eliminar);
    await tester.pumpAndSettle();
    await pulsar(tester, 'CANCELAR');
    expect(dao.registros, hasLength(2));
    await tester.tap(eliminar);
    await tester.pumpAndSettle();
    await pulsar(tester, 'ELIMINAR');
    expect(dao.registros.single.nombre, 'Luis');
    expect(dao.consultas, 4);
  });

  testWidgets('P4 caso 4: el correo se muestra en la consulta y se actualiza', (
    tester,
  ) async {
    final dao = DaoDePrueba()
      ..registros.add(
        Usuario(id: 1, nombre: 'Previo', edad: 20, profesion: 'TI'),
      )
      ..siguienteId = 2;
    await mostrar(tester, dao);
    await pulsar(tester, 'VER usuarios');
    expect(find.text('20 años · TI'), findsOneWidget); // registro de la v1 (sin correo)
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(3), 'previo@uni.mx');
    await pulsar(tester, 'ACTUALIZAR');
    expect(dao.registros.single.correo, 'previo@uni.mx');
    expect(find.text('20 años · TI\nprevio@uni.mx'), findsOneWidget);
  });
}
