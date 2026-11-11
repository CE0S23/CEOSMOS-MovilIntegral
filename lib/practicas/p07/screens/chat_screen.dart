import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dispositivo.dart';
import '../models/mensaje.dart';
import '../models/reporte.dart';
import '../services/archivo_service.dart';
import '../services/auth_service.dart';
import '../services/dispositivo_service.dart';
import '../services/mensaje_service.dart';
import '../services/reporte_service.dart';
import '../widgets/burbuja_mensaje.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.reporte});
  final Reporte reporte;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _dispositivos = DispositivoService();
  final _mensajes = MensajeService();
  final _reportes = ReporteService();
  final _archivos = ArchivoService();
  final _texto = TextEditingController();
  StreamSubscription<List<Dispositivo>>? _subDispositivos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subMensajes;
  StreamSubscription<Reporte?>? _subReporte;
  List<Dispositivo> _lista = [];
  List<Mensaje> _historial = [];
  late Reporte _reporte;
  bool _ocupado = false;
  bool _inicial = true;
  int _revisionContadores = 0;

  Dispositivo get _actual => context.read<AuthService>().actual!;
  bool get _tiempoReal => _actual.rol == 'admin' || _actual.rol == 'agente';
  bool get _puedeEnviar =>
      _reporte.activo &&
      _reporte.estado != 'Resuelto' &&
      (_actual.rol != 'agente' || _reporte.asignadoA == 'agente');

  @override
  void initState() {
    super.initState();
    _reporte = widget.reporte;
    _texto.addListener(_reconstruir);
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  void _reconstruir() {
    if (mounted) setState(() {});
  }

  Future<void> _iniciar() async {
    if (!mounted) return;
    if (_tiempoReal) {
      _subReporte = _reportes.escucharId(_reporte.id).listen((r) {
        if (mounted && r != null) setState(() => _reporte = r);
      }, onError: (Object e) => _error('No se pudo actualizar el ticket: $e'));
      _subDispositivos = _dispositivos.escuchar().listen(
        (lista) {
          if (mounted) setState(() => _lista = lista);
        },
        onError: (Object e) =>
            _error('No se pudieron cargar los dispositivos: $e'),
      );
      _subMensajes = _mensajes.escucharRaw(_reporte.id).listen((snapshot) {
        if (!mounted) return;
        if (!_inicial &&
            !snapshot.metadata.isFromCache &&
            snapshot.docChanges.any(
              (c) =>
                  c.type == DocumentChangeType.added &&
                  c.doc.data()?['emisorId'] != _actual.uid &&
                  !c.doc.metadata.hasPendingWrites,
            )) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nuevo mensaje recibido')),
          );
        }
        _inicial = false;
        setState(
          () => _historial = snapshot.docs.map(Mensaje.fromDoc).toList(),
        );
      }, onError: (Object e) => _error('No se pudo cargar el chat: $e'));
    } else {
      await _actualizar();
    }
  }

  Future<void> _actualizar() async {
    try {
      final reporte = await _reportes.consultarId(_reporte.id);
      if (reporte == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final lista = await _dispositivos.consultar();
      final historial = await _mensajes.consultar(_reporte.id);
      if (!mounted) return;
      setState(() {
        _reporte = reporte;
        _lista = lista;
        _historial = historial;
        _revisionContadores++;
      });
    } catch (e) {
      _error('No se pudo actualizar: $e');
    }
  }

  void _error(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _enviar({String tipo = 'mensaje'}) async {
    final texto = tipo == 'solicitud' && _texto.text.trim().isEmpty
        ? 'Solicito atención del administrador'
        : _texto.text.trim();
    if (!_puedeEnviar || texto.isEmpty || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      await _mensajes
          .enviar(
            emisor: _actual,
            reporteId: _reporte.id,
            texto: texto,
            tipo: tipo,
          )
          .timeout(const Duration(seconds: 5));
      _texto.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mensaje enviado')));
      }
      if (!_tiempoReal) await _actualizar();
    } on TimeoutException {
      _error('Mensaje pendiente de sincronizar');
    } catch (e) {
      _error('No se pudo enviar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _adjuntar() async {
    if (!_puedeEnviar || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      final archivo = await _archivos.elegir();
      if (archivo == null) return;
      await _mensajes.enviar(
        emisor: _actual,
        reporteId: _reporte.id,
        texto: 'Archivo: ${archivo.nombre}',
        tipo: 'archivo',
        archivoBase64: _archivos.codificar(archivo),
        archivoNombre: archivo.nombre,
        archivoTipo: archivo.tipo,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Archivo enviado')));
      }
      if (!_tiempoReal) await _actualizar();
    } catch (e) {
      _error('No se pudo adjuntar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<bool> _confirmar(String titulo, String detalle) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titulo),
          content: Text(detalle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _accion(String accion) async {
    if (_ocupado) return;
    if (accion == 'prioridad') {
      final prioridad = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Cambiar prioridad'),
          children: [
            for (final valor in const ['Baja', 'Media', 'Alta'])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, valor),
                child: Text(valor),
              ),
          ],
        ),
      );
      if (prioridad == null) return;
      return _ejecutar(
        () => _reportes.actualizar(_reporte, prioridad: prioridad),
      );
    }
    if (accion == 'pendiente') {
      return _ejecutar(
        () => _reportes.actualizar(_reporte, estado: 'Pendiente'),
      );
    }
    if (accion == 'resuelto') {
      if (!await _confirmar(
        'Resolver ticket',
        'Se cerrará el chat y se liberará el turno.',
      )) {
        return;
      }
      return _ejecutar(
        () => _reportes.actualizar(_reporte, estado: 'Resuelto'),
      );
    }
    if (accion == 'escalar') {
      if (!await _confirmar(
        'Pasar al administrador',
        'El ticket saldrá de la lista del agente.',
      )) {
        return;
      }
      return _ejecutar(() => _reportes.escalar(_reporte), salir: true);
    }
    if (accion == 'devolver') {
      return _ejecutar(() => _reportes.devolver(_reporte), salir: true);
    }
    if (accion == 'eliminar') {
      if (!await _confirmar(
        'Eliminar ticket',
        'Se ocultará el ticket y se liberará el turno.',
      )) {
        return;
      }
      return _ejecutar(() => _reportes.eliminar(_reporte), salir: true);
    }
    if (accion == 'limpiar') {
      if (!await _confirmar(
        'Limpiar historial',
        'Se borrarán solo los mensajes de este ticket.',
      )) {
        return;
      }
      return _ejecutar(() async {
        await _mensajes.limpiar(_reporte.id);
        if (mounted) setState(() => _revisionContadores++);
      });
    }
  }

  Future<void> _ejecutar(
    Future<void> Function() operacion, {
    bool salir = false,
  }) async {
    setState(() => _ocupado = true);
    try {
      await operacion();
      if (!mounted) return;
      if (salir) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ticket actualizado')));
      }
    } catch (e) {
      _error('No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Iterable<Dispositivo> get _participantes => _lista.where(
    (d) => d.uid == _reporte.usuarioId || d.rol == 'agente' || d.rol == 'admin',
  );

  Widget _contador(Dispositivo d) {
    final etiqueta = '${d.nombre}: ';
    if (_tiempoReal) {
      return StreamBuilder<int>(
        stream: _mensajes.contador(d.uid),
        builder: (context, snapshot) => Chip(
          label: Text(
            '$etiqueta${snapshot.data ?? 0} · ${d.enLinea ? "conectado" : "desconectado"}',
          ),
        ),
      );
    }
    return FutureBuilder<int>(
      key: ValueKey('${d.uid}-$_revisionContadores'),
      future: _mensajes.consultarContador(d.uid),
      builder: (context, snapshot) => Chip(
        label: Text(
          '$etiqueta${snapshot.data ?? 0} · ${d.enLinea ? "conectado" : "desconectado"}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subDispositivos?.cancel();
    _subMensajes?.cancel();
    _subReporte?.cancel();
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _actual.rol.startsWith('usuario');
    final admin = _actual.rol == 'admin';
    final agente = _actual.rol == 'agente';
    return Scaffold(
      appBar: AppBar(
        title: Text(_reporte.titulo),
        actions: [
          if (!_tiempoReal)
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _actualizar,
              icon: const Icon(Icons.refresh),
            ),
          if (!usuario)
            PopupMenuButton<String>(
              tooltip: 'Acciones del ticket',
              onSelected: _accion,
              itemBuilder: (context) => [
                if (_reporte.activo && _reporte.estado != 'Resuelto') ...[
                  const PopupMenuItem(
                    value: 'pendiente',
                    child: Text('Marcar como pendiente'),
                  ),
                  const PopupMenuItem(
                    value: 'resuelto',
                    child: Text('Marcar como resuelto'),
                  ),
                  const PopupMenuItem(
                    value: 'prioridad',
                    child: Text('Cambiar prioridad'),
                  ),
                  if (agente)
                    const PopupMenuItem(
                      value: 'escalar',
                      child: Text('Pasar al administrador'),
                    ),
                  if (admin && _reporte.asignadoA == 'admin')
                    const PopupMenuItem(
                      value: 'devolver',
                      child: Text('Devolver al agente'),
                    ),
                ],
                if (admin) ...[
                  if (_reporte.activo)
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Text('Eliminar ticket'),
                    ),
                  const PopupMenuItem(
                    value: 'limpiar',
                    child: Text('Limpiar historial de este ticket'),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_reporte.id} · Turno ${_reporte.turno} · ${_reporte.estado} · ${_reporte.prioridad}',
                ),
                Text(_reporte.descripcion),
                Wrap(
                  spacing: 4,
                  children: _participantes.map(_contador).toList(),
                ),
                if (usuario && _puedeEnviar)
                  TextButton.icon(
                    onPressed: _ocupado
                        ? null
                        : () => _enviar(tipo: 'solicitud'),
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Solicitud al administrador'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _historial.isEmpty
                ? const Center(child: Text('Sin mensajes'))
                : ListView.builder(
                    reverse: true,
                    itemCount: _historial.length,
                    itemBuilder: (context, i) {
                      final mensaje = _historial[_historial.length - 1 - i];
                      return BurbujaMensaje(
                        mensaje: mensaje,
                        propio: mensaje.emisorId == _actual.uid,
                      );
                    },
                  ),
          ),
          if (!_puedeEnviar)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_reporte.activo ? 'Ticket resuelto' : 'Ticket eliminado'),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Adjuntar archivo',
                    onPressed: _ocupado ? null : _adjuntar,
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      maxLength: 1000,
                      decoration: const InputDecoration(hintText: 'Mensaje'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar',
                    onPressed: _ocupado || _texto.text.trim().isEmpty
                        ? null
                        : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
