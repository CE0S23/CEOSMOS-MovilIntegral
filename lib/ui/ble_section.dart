import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/ble/ble_protocolo.dart';
import '../core/ble/ble_transporte.dart';
import '../core/ble/ecosistema_ble.dart';
import 'theme.dart';
import 'widgets.dart';

const _sistema = MethodChannel('ceosmos/sistema');

/// Reloj y TV compañeros por Bluetooth LE (apps «CEOSMOS Reloj» y «CEOSMOS TV»).
class BleSection extends StatelessWidget {
  const BleSection({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ble = state.ble;
    return ListenableBuilder(
      listenable: ble,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reloj y TV por Bluetooth', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'CEOSMOS se conecta como central BLE. Abre «CEOSMOS Reloj» o «CEOSMOS TV» en el otro equipo '
            'y escribe el PIN de 6 dígitos que muestra la primera vez.',
            style: TextStyle(color: Cosmos.muted),
          ),
          const SizedBox(height: 12),
          if (ble.adaptador == AdaptadorBle.apagado)
            _Aviso(
              key: const Key('ble-apagado'),
              icono: Icons.bluetooth_disabled,
              texto: 'El Bluetooth está apagado.',
              accion: 'Encender',
              onAccion: ble.encenderBluetooth,
            )
          else if (ble.adaptador == AdaptadorBle.sinPermiso)
            _Aviso(
              icono: Icons.lock_outline,
              texto: 'CEOSMOS no tiene permiso de Bluetooth (dispositivos cercanos).',
              accion: 'Abrir ajustes',
              onAccion: _abrirAjustes,
            )
          else if (ble.adaptador == AdaptadorBle.noDisponible)
            const _Aviso(icono: Icons.bluetooth_disabled, texto: 'Este equipo no tiene Bluetooth LE disponible.'),
          for (final rol in RolBle.values) ...[
            _TarjetaBle(state: state, rol: rol),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

Future<void> _abrirAjustes() async {
  try {
    await _sistema.invokeMethod<void>('abrirAjustesApp');
  } on PlatformException {
    // Sin canal (pruebas o plataforma sin ajustes de app).
  } on MissingPluginException {
    // Igual que arriba.
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({super.key, required this.icono, required this.texto, this.accion, this.onAccion});
  final IconData icono;
  final String texto;
  final String? accion;
  final Future<void> Function()? onAccion;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Panel(
          child: Row(
            children: [
              Icon(icono, color: Cosmos.peach),
              const SizedBox(width: 12),
              Expanded(child: Text(texto)),
              if (accion != null) TextButton(onPressed: onAccion, child: Text(accion!)),
            ],
          ),
        ),
      );
}

class _TarjetaBle extends StatefulWidget {
  const _TarjetaBle({required this.state, required this.rol});
  final AppState state;
  final RolBle rol;
  @override
  State<_TarjetaBle> createState() => _TarjetaBleState();
}

class _TarjetaBleState extends State<_TarjetaBle> {
  final _mensaje = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _mensaje.dispose();
    super.dispose();
  }

  void _aviso(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _conectar() async {
    var r = await widget.state.connectBle(widget.rol);
    while (mounted && (r == ResultadoConexion.requierePin || r == ResultadoConexion.pinIncorrecto)) {
      final pin = await _pedirPin(r == ResultadoConexion.pinIncorrecto);
      if (pin == null) return;
      r = await widget.state.connectBle(widget.rol, pin: pin);
    }
    if (r == ResultadoConexion.sinPermiso) await _abrirAjustes();
  }

  Future<String?> _pedirPin(bool reintento) async {
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (_) => FormDialog(
        title: reintento ? 'PIN incorrecto, intenta de nuevo' : 'PIN del ${widget.rol.nombre}',
        confirmLabel: 'Conectar',
        fields: [
          DialogField(
            'PIN de 6 dígitos (se ve en la pantalla del ${widget.rol.nombre})',
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) => pinValido(v?.trim() ?? '') ? null : 'Escribe los 6 dígitos.',
          ),
        ],
      ),
    );
    return valores?.first.trim();
  }

  Future<void> _enviar() async {
    final t = _mensaje.text.trim();
    if (t.isEmpty) {
      _aviso('Escribe un mensaje para el reloj.');
      return;
    }
    setState(() => _enviando = true);
    final ok = await widget.state.ble.notificarReloj(t);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) _mensaje.clear();
    _aviso(ok ? 'Notificación enviada al reloj.' : 'No se pudo enviar: el reloj no respondió.');
  }

  @override
  Widget build(BuildContext context) {
    final ble = widget.state.ble;
    final rol = widget.rol;
    final e = ble[rol];
    final vinculado = widget.state.bleVinculado(rol);
    final ocupado = {EstadoEnlace.buscando, EstadoEnlace.conectando, EstadoEnlace.autenticando}.contains(e.estado);
    final (texto, color) = switch (e.estado) {
      EstadoEnlace.desconectado => ('Desconectado', Cosmos.muted),
      EstadoEnlace.buscando => ('Buscando…', Cosmos.lavender),
      EstadoEnlace.conectando => ('Conectando…', Cosmos.lavender),
      EstadoEnlace.autenticando => ('Verificando PIN…', Cosmos.lavender),
      EstadoEnlace.conectado => ('Conectado', Cosmos.mint),
      EstadoEnlace.reconectando => ('Reconectando${e.reintento > 0 ? ' (intento ${e.reintento})' : ''}…', Cosmos.peach),
      EstadoEnlace.error => ('Sin conexión', Cosmos.peach),
    };
    return Panel(
      key: Key('ble-${rol.etiqueta}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rol == RolBle.reloj ? Icons.watch_outlined : Icons.tv_outlined, color: Cosmos.lavender, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CEOSMOS ${rol.nombre}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                    Text(
                      vinculado == null ? 'BLE · sin vincular' : 'BLE · vinculado a tu cuenta (${vinculado.address})',
                      style: const TextStyle(color: Cosmos.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Tag(texto, color: color),
            ],
          ),
          if (e.error != null && e.estado != EstadoEnlace.conectado) ...[
            const SizedBox(height: 10),
            Text(e.error!, style: const TextStyle(color: Cosmos.peach)),
          ],
          const SizedBox(height: 12),
          if (e.activo && rol == RolBle.reloj) ...[
            if (ble.ultimaLectura == null)
              const Text('Esperando lecturas del reloj…', style: TextStyle(color: Cosmos.muted))
            else
              Text(
                '${ble.ultimaLectura!.heartRate} bpm'
                '${ble.ultimaLectura!.steps == null ? '' : ' · ${ble.ultimaLectura!.steps} pasos'}'
                ' · ${ble.muestras.length} lecturas',
                key: const Key('ble-lectura'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('ble-mensaje'),
              controller: _mensaje,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Notificación para el reloj'),
              onSubmitted: (_) => _enviar(),
            ),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.send),
              label: const Text('Enviar al reloj'),
            ),
            const SizedBox(height: 8),
          ],
          if (e.activo && rol == RolBle.tv)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.state.hasSession
                    ? 'Proyectando «${widget.state.currentMedia!.title}» en la TV.'
                    : 'La TV muestra tu panel. Inicia una sesión para proyectarla.',
                style: const TextStyle(color: Cosmos.muted),
              ),
            ),
          if (e.activo && ble.ultimoComando != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Último comando: ${ble.ultimoComando}', style: const TextStyle(color: Cosmos.muted, fontSize: 12)),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (e.activo || e.estado == EstadoEnlace.reconectando)
                OutlinedButton(onPressed: () => ble.desconectar(rol), child: const Text('Desconectar'))
              else
                FilledButton.icon(
                  onPressed: ocupado || ble.adaptador == AdaptadorBle.noDisponible ? null : _conectar,
                  icon: ocupado
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(e.estado == EstadoEnlace.error ? 'Reintentar' : 'Conectar'),
                ),
              if (vinculado != null && !e.activo)
                TextButton(
                  onPressed: () => widget.state.unlinkDevice(vinculado),
                  child: const Text('Olvidar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
