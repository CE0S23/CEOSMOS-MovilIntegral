const rolesValidos = {'admin', 'agente', 'usuario1', 'usuario2'};

String? rolDesdeUrl(String entrada) {
  final uri = Uri.tryParse(entrada.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'practica7.app' ||
      uri.pathSegments.length != 2 ||
      uri.pathSegments.first != 'rol' ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final rol = uri.pathSegments.last;
  return rolesValidos.contains(rol) ? rol : null;
}

String nombrePredeterminado(String rol) => switch (rol) {
  'admin' => 'Administrador',
  'agente' => 'Agente',
  'usuario1' => 'Usuario 1',
  'usuario2' => 'Usuario 2',
  _ => 'Dispositivo',
};
