import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'usuario.dart';
import 'usuario_dao.dart';

part 'app_database.g.dart';

// [CEOSMOS] Práctica 4, caso 4: versión 2 agrega la columna `correo`.
@Database(version: 2, entities: [Usuario])
abstract class AppDatabase extends FloorDatabase {
  UsuarioDao get usuarioDao;
}

/// Migración 1 → 2: agrega `correo` sin perder los usuarios ya guardados.
final migracion1a2 = Migration(1, 2, (database) async {
  await database.execute('ALTER TABLE `usuarios` ADD COLUMN `correo` TEXT');
});
