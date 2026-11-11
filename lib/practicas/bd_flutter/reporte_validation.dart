String? validarId(String id) => RegExp(r'^REP[0-9]{3}$').hasMatch(id.trim())
    ? null
    : 'El ID debe tener el formato REP001.';

String? validarReporte({
  required String id,
  required String equipo,
  required String descripcion,
  required String prioridad,
}) {
  final errorId = validarId(id);
  if (errorId != null) return errorId;
  if (equipo.trim().isEmpty) return 'El equipo es obligatorio.';
  if (descripcion.trim().isEmpty) return 'La descripción es obligatoria.';
  if (equipo.trim().length > 100 || descripcion.trim().length > 500) {
    return 'El texto supera el límite permitido.';
  }
  if (!{'Baja', 'Media', 'Alta'}.contains(prioridad)) {
    return 'La prioridad debe ser Baja, Media o Alta.';
  }
  return null;
}
