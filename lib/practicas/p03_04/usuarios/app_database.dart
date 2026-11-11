import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'usuario.dart';
import 'usuario_dao.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [Usuario])
abstract class AppDatabase extends FloorDatabase {
  UsuarioDao get usuarioDao;
}
