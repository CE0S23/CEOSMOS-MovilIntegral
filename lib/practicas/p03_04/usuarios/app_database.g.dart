// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';


abstract class $AppDatabaseBuilderContract {
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  $AppDatabaseBuilderContract addCallback(Callback callback);

  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  UsuarioDao? _usuarioDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `usuarios` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `nombre` TEXT NOT NULL, `edad` INTEGER NOT NULL, `profesion` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  UsuarioDao get usuarioDao {
    return _usuarioDaoInstance ??= _$UsuarioDao(database, changeListener);
  }
}

class _$UsuarioDao extends UsuarioDao {
  _$UsuarioDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _usuarioInsertionAdapter = InsertionAdapter(
            database,
            'usuarios',
            (Usuario item) => <String, Object?>{
                  'id': item.id,
                  'nombre': item.nombre,
                  'edad': item.edad,
                  'profesion': item.profesion
                }),
        _usuarioUpdateAdapter = UpdateAdapter(
            database,
            'usuarios',
            ['id'],
            (Usuario item) => <String, Object?>{
                  'id': item.id,
                  'nombre': item.nombre,
                  'edad': item.edad,
                  'profesion': item.profesion
                }),
        _usuarioDeletionAdapter = DeletionAdapter(
            database,
            'usuarios',
            ['id'],
            (Usuario item) => <String, Object?>{
                  'id': item.id,
                  'nombre': item.nombre,
                  'edad': item.edad,
                  'profesion': item.profesion
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Usuario> _usuarioInsertionAdapter;

  final UpdateAdapter<Usuario> _usuarioUpdateAdapter;

  final DeletionAdapter<Usuario> _usuarioDeletionAdapter;

  @override
  Future<List<Usuario>> obtenerTodos() async {
    return _queryAdapter.queryList('SELECT * FROM usuarios ORDER BY id',
        mapper: (Map<String, Object?> row) => Usuario(
            id: row['id'] as int?,
            nombre: row['nombre'] as String,
            edad: row['edad'] as int,
            profesion: row['profesion'] as String));
  }

  @override
  Future<void> insertar(Usuario usuario) async {
    await _usuarioInsertionAdapter.insert(usuario, OnConflictStrategy.abort);
  }

  @override
  Future<void> actualizar(Usuario usuario) async {
    await _usuarioUpdateAdapter.update(usuario, OnConflictStrategy.abort);
  }

  @override
  Future<void> eliminar(Usuario usuario) async {
    await _usuarioDeletionAdapter.delete(usuario);
  }
}
