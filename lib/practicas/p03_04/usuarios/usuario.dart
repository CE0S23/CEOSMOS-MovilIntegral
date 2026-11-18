import 'package:floor/floor.dart';

@Entity(tableName: 'usuarios')
class Usuario {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String nombre;
  final int edad;
  final String profesion;

  /// [CEOSMOS] Práctica 4, caso 4: nuevo campo. Nulo solo en registros creados
  /// con la versión 1 de la base (antes de la migración).
  final String? correo;

  Usuario({
    this.id,
    required this.nombre,
    required this.edad,
    required this.profesion,
    this.correo,
  });
}
