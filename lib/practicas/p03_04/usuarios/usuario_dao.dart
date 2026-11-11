import 'package:floor/floor.dart';

import 'usuario.dart';

@dao
abstract class UsuarioDao {
  @Query('SELECT * FROM usuarios ORDER BY id')
  Future<List<Usuario>> obtenerTodos();

  @insert
  Future<void> insertar(Usuario usuario);

  @update
  Future<void> actualizar(Usuario usuario);

  @delete
  Future<void> eliminar(Usuario usuario);
}
