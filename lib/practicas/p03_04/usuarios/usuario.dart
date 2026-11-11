import 'package:floor/floor.dart';

@Entity(tableName: 'usuarios')
class Usuario {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String nombre;
  final int edad;
  final String profesion;

  Usuario({
    this.id,
    required this.nombre,
    required this.edad,
    required this.profesion,
  });
}
