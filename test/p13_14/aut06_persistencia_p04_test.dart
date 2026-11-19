// P13-14 · AUT-06 · Persistencia real de la Práctica 4 (alumnos) con SQLite.
// Se usa la base Floor GENERADA de la app (`$FloorAppDatabase`, DAO y migración
// `migracion1a2`) sobre sqflite_common_ffi: en escritorio/CI Floor ya elige
// `databaseFactoryFfi`, el mismo motor SQLite que en Android, sin emulador.
//   · CRUD en una base EN MEMORIA: insertar, volver a leer, actualizar y borrar.
//   · Migración v1 → v2 (campo `correo`): requiere un ARCHIVO temporal, porque una
//     base en memoria desaparece al cerrarse y no se puede «reabrir» en otra versión.
import 'dart:io';

import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/app_database.dart';
import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  group('CRUD en memoria', () {
    late AppDatabase db;
    setUp(() async => db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build());
    tearDown(() => db.close());

    test('insertar y volver a leer conserva todos los campos (incluido correo)', () async {
      await db.usuarioDao.insertar(Usuario(nombre: 'Ana', edad: 21, profesion: 'Ingeniería', correo: 'ana@uni.mx'));
      await db.usuarioDao.insertar(Usuario(nombre: 'Beto', edad: 30, profesion: 'Diseño', correo: 'beto@uni.mx'));
      final todos = await db.usuarioDao.obtenerTodos();
      expect(todos.map((u) => (u.id, u.nombre, u.edad, u.profesion, u.correo)), [
        (1, 'Ana', 21, 'Ingeniería', 'ana@uni.mx'),
        (2, 'Beto', 30, 'Diseño', 'beto@uni.mx'),
      ]);
    });

    test('actualizar y eliminar se reflejan al volver a leer', () async {
      await db.usuarioDao.insertar(Usuario(nombre: 'Ana', edad: 21, profesion: 'Ingeniería', correo: 'ana@uni.mx'));
      final ana = (await db.usuarioDao.obtenerTodos()).single;
      await db.usuarioDao.actualizar(Usuario(id: ana.id, nombre: 'Ana M.', edad: 22, profesion: 'Ingeniería', correo: 'ana.m@uni.mx'));
      expect((await db.usuarioDao.obtenerTodos()).single.correo, 'ana.m@uni.mx');
      await db.usuarioDao.eliminar(ana);
      expect(await db.usuarioDao.obtenerTodos(), isEmpty);
    });

    test('id duplicado → excepción de SQLite (OnConflictStrategy.abort) y no se pierde el original', () async {
      await db.usuarioDao.insertar(Usuario(id: 7, nombre: 'Ana', edad: 21, profesion: 'Ing', correo: 'a@uni.mx'));
      await expectLater(
        db.usuarioDao.insertar(Usuario(id: 7, nombre: 'Otro', edad: 40, profesion: 'X', correo: 'o@uni.mx')),
        throwsA(isA<DatabaseException>()),
      );
      expect((await db.usuarioDao.obtenerTodos()).single.nombre, 'Ana');
    });
  });

  group('Migración v1 → v2 (campo correo)', () {
    late Directory dir;
    late String ruta;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('p13_14_p04_');
      ruta = '${dir.path}${Platform.pathSeparator}p04.db';
      // Base tal como la dejaba la versión 1 de la práctica (sin columna correo).
      final v1 = await databaseFactoryFfi.openDatabase(ruta,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (d, _) => d.execute(
                'CREATE TABLE `usuarios` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `nombre` TEXT NOT NULL, `edad` INTEGER NOT NULL, `profesion` TEXT NOT NULL)'),
          ));
      await v1.insert('usuarios', {'nombre': 'Previo', 'edad': 19, 'profesion': 'Arquitectura'});
      await v1.close();
    });
    tearDown(() => dir.delete(recursive: true));

    test('con migracion1a2 los alumnos de v1 se conservan (correo null) y los nuevos guardan correo', () async {
      final db = await $FloorAppDatabase.databaseBuilder(ruta).addMigrations([migracion1a2]).build();
      addTearDown(db.close);
      await db.usuarioDao.insertar(Usuario(nombre: 'Nuevo', edad: 20, profesion: 'Medicina', correo: 'nuevo@uni.mx'));
      final todos = await db.usuarioDao.obtenerTodos();
      expect(todos.map((u) => (u.nombre, u.correo)), [('Previo', null), ('Nuevo', 'nuevo@uni.mx')]);
      expect(await db.database.getVersion(), 2);
    });

    test('sin la migración Floor se niega a abrir (no borra ni corrompe los datos de v1)', () async {
      await expectLater($FloorAppDatabase.databaseBuilder(ruta).build(), throwsA(anything));
      final v1 = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(readOnly: true));
      addTearDown(v1.close);
      expect(await v1.query('usuarios'), hasLength(1), reason: 'el alumno previo sigue en disco');
    });
  });
}
