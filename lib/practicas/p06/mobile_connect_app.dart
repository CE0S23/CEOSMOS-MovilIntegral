import '../atras_ceosmos.dart'; // [CEOSMOS]
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_session.dart';
import 'local_network.dart';
import '../../core/theme/theme.dart';

class MobileConnectApp extends StatelessWidget {
  const MobileConnectApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      onNavigationNotification: atrasManejadoPorCeosmos, // [CEOSMOS] Atrás vuelve a «Prácticas»
        title: 'Mensajería entre equipos',
        debugShowCheckedModeBanner: false,
        // [CEOSMOS] Tema compartido del sistema de diseño (claro/oscuro).
        theme: CeosmosTema.claro,
        darkTheme: CeosmosTema.oscuro,
        themeMode: ThemeMode.system,
        home: const ConversationPage(),
      );
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> with WidgetsBindingObserver {
  static const _network = MethodChannel('mobile_connect/network');
  static const _events = EventChannel('mobile_connect/events');
  final _draft = TextEditingController();
  final _hostIp = TextEditingController();
  final _scroll = ScrollController();
  final Map<ChatSession, String?> _seenNotices = {};
  StreamSubscription<dynamic>? _eventSubscription;
  ChatSession? _wifiSession;
  String? _savedWifiKey;
  ChatSession? _simulationA;
  ChatSession? _simulationB;
  DeviceId _selectedDevice = DeviceId.a;
  DeviceId _simulationView = DeviceId.a;
  bool _wifiMode = true;
  bool _started = false;
  bool _connected = false;
  bool _hostListening = false;
  bool _connectionBusy = false;
  bool _everConnected = false;
  bool _resetScheduled = false;
  String _status = 'Sin conexión';
  String? _visualNotice;
  LocalNetworkInfo _localNetwork = const LocalNetworkInfo(message: 'Consultando la red Wi-Fi…');
  bool _networkLoading = false;
  int _networkRevision = 0;

  ChatSession? get _active => _wifiMode
      ? _wifiSession
      : (_simulationView == DeviceId.a ? _simulationA : _simulationB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshLocalNetwork());
    // Recibir es automático: no cambia la identidad del teléfono ni el emisor.
    _eventSubscription = _events.receiveBroadcastStream().listen((dynamic raw) {
      if (!mounted || raw is! Map) return;
      if (raw['type'] == 'network_info') {
        _networkRevision++;
        setState(() => _localNetwork = LocalNetworkInfo.fromMap(raw));
        return;
      }
      if (!_wifiMode) return;
      if (raw['type'] == 'status') {
        setState(() {
          _status = raw['message'] as String? ?? 'Sin conexión';
          _connected = raw['connected'] == true;
          _hostListening = raw['listening'] == true;
          _connectionBusy = raw['connecting'] == true;
          if (_connected) _everConnected = true;
        });
      } else {
        unawaited(_wifiSession?.receive(Map<Object?, Object?>.from(raw)));
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _status = 'No se pudo usar el canal de red.';
          _connected = false;
          _hostListening = false;
          _connectionBusy = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshLocalNetwork());
  }

  Future<void> _refreshLocalNetwork() async {
    if (_networkLoading) return;
    final revision = _networkRevision;
    setState(() => _networkLoading = true);
    try {
      final info = await _network.invokeMapMethod<Object?, Object?>('getLocalNetwork');
      if (mounted && revision == _networkRevision) {
        setState(() => _localNetwork = LocalNetworkInfo.fromMap(info ?? {}));
      }
    } on PlatformException {
      if (mounted && revision == _networkRevision) {
        setState(() => _localNetwork = const LocalNetworkInfo(
            message: 'No se pudo consultar la IP Wi-Fi. Pulsa Actualizar IP.'));
      }
    } finally {
      if (mounted) setState(() => _networkLoading = false);
    }
  }

  Future<void> _copyLocalIp() async {
    final ip = _localNetwork.ip;
    if (ip == null) return;
    await Clipboard.setData(ClipboardData(text: ip));
    if (mounted) _notify('IP Wi-Fi copiada: $ip');
  }

  void _watch(ChatSession session) {
    session.addListener(() => _sessionChanged(session));
  }

  void _sessionChanged(ChatSession session) {
    if (!mounted) return;
    setState(() {});
    if (session.resetComplete && !_resetScheduled) {
      _resetScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_returnToSetup());
      });
      return;
    }
    if (session == _active && session.notice != null &&
        session.notice != _seenNotices[session]) {
      _notify(session.notice!);
    }
    _seenNotices[session] = session.notice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _notify(String text) {
    if (!mounted) return;
    // El aviso ocupa su propio espacio y nunca tapa el botón para enviar.
    setState(() => _visualNotice = text);
  }

  Future<bool> _sendPacket(Map<String, Object> packet) async {
    if (!_connected) return false;
    return await _network.invokeMethod<bool>('sendPacket', packet) == true;
  }

  Future<void> _start() async {
    if (_started) return;
    if (_wifiMode) {
      final error = _selectedDevice == DeviceId.b
          ? _localNetwork.validatePeer(_hostIp.text)
          : _localNetwork.ip == null ? _localNetwork.message : null;
      if (error != null) {
        _notify(error);
        return;
      }
    }
    if (_wifiMode) {
      final key = _selectedDevice == DeviceId.a ? 'host' : 'client:${_hostIp.text.trim()}';
      // Volver a la preparación y reconectar al mismo destino recupera el rol.
      if (_wifiSession == null || _savedWifiKey != key) {
        final previous = _wifiSession;
        if (previous != null) _seenNotices.remove(previous);
        previous?.dispose();
        _wifiSession = ChatSession(localDevice: _selectedDevice,
            sendPacket: _sendPacket, automaticRoles: true,
            isHost: _selectedDevice == DeviceId.a);
        _savedWifiKey = key;
        _watch(_wifiSession!);
      }
    } else if (_simulationA == null || _simulationB == null) {
      // Cada teléfono virtual conserva su identidad y su historial propios.
      _simulationA = ChatSession(localDevice: DeviceId.a, automaticRoles: true, isHost: true, sendPacket: (packet) async {
        await _simulationB!.receive(packet);
        return true;
      });
      _simulationB = ChatSession(localDevice: DeviceId.b, automaticRoles: true, sendPacket: (packet) async {
        await _simulationA!.receive(packet);
        return true;
      });
      _watch(_simulationA!);
      _watch(_simulationB!);
      _simulationView = _selectedDevice;
    }
    setState(() {
      _started = true;
      _everConnected = false;
    });
    if (_wifiMode) await _connectFixedDevice();
  }

  Future<void> _connectFixedDevice() async {
    final session = _wifiSession;
    if (session == null || _connectionBusy) return;
    final error = _selectedDevice == DeviceId.b
        ? _localNetwork.validatePeer(_hostIp.text)
        : _localNetwork.ip == null ? _localNetwork.message : null;
    if (error != null) {
      _notify(error);
      return;
    }
    setState(() {
      _connected = false;
      _hostListening = false;
      _connectionBusy = true;
      _status = 'Preparando conexión…';
    });
    try {
      // La reconexión utiliza la identidad elegida al principio.
      if (_selectedDevice == DeviceId.a) {
        await _network.invokeMethod<void>('host');
      } else {
        final ip = _hostIp.text.trim();
        await _network.invokeMethod<void>('connect', {'ip': ip});
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _status = 'No se pudo iniciar la conexión.';
          _connectionBusy = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final session = _active;
    if (session == null) return;
    final error = session.validateMessage(_draft.text);
    if (error != null) {
      _notify(error);
      return;
    }
    if (_wifiMode && !_connected) {
      _notify('Conecta los dispositivos primero.');
      return;
    }
    if (await session.sendMessage(_draft.text) && mounted) {
      _draft.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _returnToSetup() async {
    if (_wifiMode) {
      try {
        await _network.invokeMethod<void>('disconnect');
      } on PlatformException {
        // La sesión confirmada se descarta aunque falle el cierre del canal.
      }
    }
    if (!mounted) return;
    // Regresar desconecta la red, pero conserva historial e identidad en memoria.
    _draft.clear();
    setState(() {
      _started = false;
      _connected = false;
      _hostListening = false;
      _connectionBusy = false;
      _everConnected = false;
      _resetScheduled = false;
      _status = 'Sin conexión';
      _visualNotice = null;
    });
  }

  Future<void> _confirmReset() async {
    final session = _active;
    if (session == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Reiniciar chat y roles'),
      content: const Text('Se borrará el chat de ambos y el próximo en escribir será A. ¿Continuar?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reiniciar ambos')),
      ],
    ));
    if (confirmed == true && mounted) await session.requestReset();
  }

  void _disposeSessions() {
    _wifiSession?.dispose();
    _simulationA?.dispose();
    _simulationB?.dispose();
    _wifiSession = null;
    _savedWifiKey = null;
    _simulationA = null;
    _simulationB = null;
    _seenNotices.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    _disposeSessions();
    _draft.dispose();
    _hostIp.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _ipField() => TextField(
        key: const Key('host-ip'),
        controller: _hostIp,
        autocorrect: false,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: const InputDecoration(
            labelText: 'IP Wi-Fi del teléfono que creó la sala', border: OutlineInputBorder()),
      );

  Widget _networkCard({bool compact = false}) => Card(
        color: context.paleta.cianSuave,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!compact) ...[
              Text('IP de este dispositivo (Wi-Fi)',
                  style: context.texto.titleSmall),
              const SizedBox(height: 6),
            ],
            Row(children: [
              Expanded(child: _localNetwork.ip != null
                  ? SelectableText('${compact ? 'Mi IP Wi-Fi: ' : ''}${_localNetwork.ip}',
                      key: const Key('local-wifi-ip'),
                      style: (compact ? context.texto.titleSmall : context.texto.headlineSmall)
                          ?.copyWith(color: context.paleta.marca))
                  : Text(_localNetwork.message, key: const Key('local-network-unavailable'))),
              IconButton(
                tooltip: 'Copiar IP',
                onPressed: _localNetwork.ip == null ? null : _copyLocalIp,
                icon: const Icon(Icons.copy_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Actualizar IP',
                onPressed: _networkLoading ? null : _refreshLocalNetwork,
                icon: const Icon(Icons.refresh),
              ),
            ]),
            if (!compact && _localNetwork.ip != null)
              Text('Si creas la sala, comparte esta IP con tu compañero. Ambos deben estar en la misma Wi-Fi.',
                  style: context.texto.bodySmall),
          ]),
        ),
      );

  Widget _setup() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Prepara la conversación',
                  style: context.texto.headlineMedium?.copyWith(color: context.paleta.marca)),
              const SizedBox(height: 12),
              const Text('Uno crea la sala y otro se une. El primero que escriba será A y el otro B; ambos pueden enviar y recibir.'),
              const SizedBox(height: 20),
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('Wi-Fi local'), selected: _wifiMode,
                    onSelected: (_) => setState(() => _wifiMode = true)),
                ChoiceChip(label: const Text('Simulación local'), selected: !_wifiMode,
                    onSelected: (_) => setState(() => _wifiMode = false)),
              ]),
              const SizedBox(height: 16),
              if (_wifiMode) _networkCard(),
              Wrap(spacing: 8, children: DeviceId.values.map((device) => ChoiceChip(
                label: Text(_wifiMode
                    ? device == DeviceId.a ? 'Crear sala' : 'Unirse a una sala'
                    : 'Dispositivo ${device.label}'),
                selected: _selectedDevice == device,
                onSelected: (_) => setState(() => _selectedDevice = device),
              )).toList()),
              const SizedBox(height: 12),
              if (_wifiMode) ...[
                Text(_selectedDevice == DeviceId.a
                    ? 'Comparte tu IP Wi-Fi. Escucharás en TCP 5000. Crear la sala no determina si serás A o B.'
                    : 'Escribe la IP de quien creó la sala. La conexión usa TCP 5000.'),
                if (_selectedDevice == DeviceId.b) ...[
                  const SizedBox(height: 16),
                  _ipField(),
                ],
              ] else
                const Text('La demostración muestra dos teléfonos virtuales. Cada uno tiene su propia conversación y recibe los mensajes del otro.'),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _wifiMode && _localNetwork.ip == null ? null : _start,
                child: Text(!_wifiMode ? 'Iniciar simulación'
                    : _selectedDevice == DeviceId.a ? 'Crear conversación' : 'Unirme a la conversación'),
              )),
            ]),
          ),
        ),
      );

  Widget _conversation() {
    final session = _active!;
    final ready = !_wifiMode || _connected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!_wifiMode)
          SegmentedButton<DeviceId>(
            segments: const [
              ButtonSegment(value: DeviceId.a, label: Text('Ver teléfono A')),
              ButtonSegment(value: DeviceId.b, label: Text('Ver teléfono B')),
            ],
            selected: {_simulationView},
            onSelectionChanged: (selection) {
              _draft.clear();
              setState(() {
                _simulationView = selection.first;
                _visualNotice = null;
              });
            },
          ),
        const SizedBox(height: 8),
        Text(session.roleAssigned
            ? 'Este dispositivo: ${session.localDevice.label}  ·  Chat con ${session.localDevice.peer.label}'
            : 'Rol pendiente · El primero en escribir será A',
            style: context.texto.titleMedium),
        if (_wifiMode) ...[
          _networkCard(compact: true),
          Text(_status),
          if (_connectionBusy) const LinearProgressIndicator(),
          if (!_connected) ...[
            if (_selectedDevice == DeviceId.b) _ipField(),
            Wrap(spacing: 8, children: [
              if (!_hostListening)
                OutlinedButton(onPressed: _connectionBusy ? null : _connectFixedDevice,
                    child: const Text('Reintentar conexión')),
              if (!_everConnected)
                TextButton(onPressed: _returnToSetup,
                    child: const Text('Cambiar preparación')),
            ]),
          ],
        ],
        Row(children: [
          Expanded(child: Text('A: ${session.count(DeviceId.a)}  ·  B: ${session.count(DeviceId.b)} enviados')),
          TextButton.icon(
            onPressed: session.sending || session.clearing || session.resetPending
                ? null : session.clearHistory,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Eliminar historial'),
          ),
        ]),
        OutlinedButton(
          onPressed: ready && session.canReset ? _confirmReset : null,
          child: Text(session.resetPending ? 'Reiniciando…' : 'Reiniciar chat y roles en ambos'),
        ),
        if (session.localHistoryCleared)
          Text('Tu historial está vacío. Conservas tu rol al recibir o enviar nuevamente.',
              style: context.texto.bodySmall),
        Expanded(child: Card(
          color: context.paleta.superficie,
          elevation: 0,
          child: session.messages.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Aún no hay mensajes.\nEscribe para iniciar la conversación.',
                      textAlign: TextAlign.center),
                ))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(10),
                  itemCount: session.messages.length,
                  itemBuilder: (_, index) => _MessageBubble(
                      session.messages[index], localDevice: session.localDevice),
                ),
        )),
        const SizedBox(height: 8),
        TextField(
          key: const Key('message-draft'),
          controller: _draft,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Mensaje (máximo 200 caracteres)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 48, child: FilledButton(
          onPressed: session.sending || session.clearing || session.resetPending ? null : _send,
          child: Text(session.sending ? 'Enviando…' : 'Enviar mensaje'),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_started,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _started) unawaited(_returnToSetup());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MobileConnect'),
          leading: _started ? IconButton(
            tooltip: 'Regresar', icon: const Icon(Icons.arrow_back),
            onPressed: _returnToSetup,
          ) : null,
        ),
        body: SafeArea(child: Column(children: [
          if (_visualNotice != null)
            Container(
              color: context.paleta.cianSuave,
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Row(children: [
                Expanded(child: Text(_visualNotice!)),
                IconButton(
                  tooltip: 'Cerrar aviso',
                  onPressed: () => setState(() => _visualNotice = null),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ]),
            ),
          Expanded(child: _started ? _conversation() : _setup()),
        ])),
      ));
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(this.message, {required this.localDevice});
  final ChatMessage message;
  final DeviceId localDevice;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine ?? message.sender == localDevice;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Card(
          color: mine ? context.paleta.cianSuave : context.paleta.guindaSuave,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
              Text('${mine ? 'Tú · ' : ''}Dispositivo ${message.sender.label}',
                  style: context.texto.titleSmall),
              const SizedBox(height: Espacio.xs),
              Text(message.text),
              const SizedBox(height: Espacio.xs),
              Text(message.time, style: context.texto.bodySmall),
            ]),
          ),
        ),
      ),
    );
  }
}
