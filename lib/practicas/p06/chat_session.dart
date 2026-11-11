import 'package:flutter/foundation.dart';

enum DeviceId {
  a('A'), b('B');
  const DeviceId(this.label);
  final String label;
  DeviceId get peer => this == a ? b : a;
}

typedef PacketSender = Future<bool> Function(Map<String, Object> packet);

class ChatMessage {
  const ChatMessage(this.sender, this.text, this.time, {this.mine});
  final DeviceId sender;
  final String text;
  final String time;
  // La posición de la burbuja no depende de cambios posteriores de rol.
  final bool? mine;
}

class ChatSession extends ChangeNotifier {
  ChatSession({required DeviceId localDevice, required this.sendPacket,
      this.automaticRoles = false, this.isHost = false})
      : _preferredDevice = localDevice,
        _assignedDevice = automaticRoles ? null : localDevice;

  final DeviceId _preferredDevice;
  final bool automaticRoles;
  final bool isHost;
  final PacketSender sendPacket;
  DeviceId? _assignedDevice;
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  bool _resetting = false;
  bool _disposed = false;
  bool _historyCleared = false;
  int _resetVersion = 0;
  String? notice;

  DeviceId get localDevice => _assignedDevice ?? _preferredDevice;
  bool get roleAssigned => _assignedDevice != null;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get sending => _sending;
  bool get clearing => false;
  bool get resetPending => _resetting;
  bool get resetComplete => false;
  bool get localHistoryCleared => _historyCleared;
  bool get peerHistoryCleared => false;
  bool get canReset => !_sending && !_resetting;

  int count(DeviceId device) =>
      _messages.where((message) => message.sender == device).length;

  String? validateMessage(String draft) {
    if (draft.trim().isEmpty) return 'Escribe un mensaje antes de enviar.';
    if (draft.trim().length > 200) return 'El mensaje supera 200 caracteres.';
    return null;
  }

  void _assign(DeviceId role) {
    _assignedDevice = role;
    // Si ambos enviaron primero, el anfitrión conserva A y el cliente toma B.
    // Se corrigen las etiquetas, conservando quién envió cada burbuja.
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      final mine = message.mine ?? message.sender == role;
      _messages[index] = ChatMessage(mine ? role : role.peer,
          message.text, message.time, mine: mine);
    }
  }

  Future<bool> sendMessage(String draft) async {
    final error = validateMessage(draft);
    if (error != null) {
      notice = error;
      _changed();
      return false;
    }
    if (_sending || _resetting) return false;
    final previousRole = _assignedDevice;
    final resetVersion = _resetVersion;
    if (_assignedDevice == null) _assign(DeviceId.a);
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final text = draft.trim();
    _sending = true;
    notice = null;
    _changed();
    final sent = await _send({'type': 'message', 'sender': localDevice.label,
      'text': text, 'time': time});
    if (_disposed) return false;
    _sending = false;
    if (resetVersion != _resetVersion) {
      _changed();
      return sent;
    }
    if (sent) {
      _messages.add(ChatMessage(localDevice, text, time, mine: true));
      _historyCleared = false;
      notice = 'Mensaje enviado al dispositivo ${localDevice.peer.label}';
    } else {
      // Un intento fallido no decide por sí solo el rol de una conversación nueva.
      if (previousRole == null && _messages.isEmpty) _assignedDevice = null;
      notice = 'No se pudo enviar el mensaje.';
    }
    _changed();
    return sent;
  }

  Future<void> receive(Map<Object?, Object?> packet) async {
    if (_disposed) return;
    if (packet['type'] == 'reset') {
      _resetRoles();
      notice = 'El compañero reinició el chat. El próximo en escribir será A.';
      _changed();
      return;
    }
    if (packet['type'] != 'message') return;
    final text = packet['text'];
    final time = packet['time'];
    final sender = packet['sender'];
    if (text is! String || time is! String || time.length > 16 ||
        (sender != 'A' && sender != 'B') || validateMessage(text) != null) {
      return; // [CEOSMOS] lint: llaves en el if (misma lógica)
    }
    final remote = sender == 'A' ? DeviceId.a : DeviceId.b;
    if (automaticRoles && (_assignedDevice == null ||
        (_assignedDevice == remote && !isHost))) {
      _assign(remote.peer);
    }
    _messages.add(ChatMessage(localDevice.peer, text.trim(), time, mine: false));
    _historyCleared = false;
    notice = 'Mensaje recibido del dispositivo ${localDevice.peer.label}';
    _changed();
  }

  Future<void> clearHistory() async {
    if (_sending || _resetting) return;
    // Borrar mensajes no borra el rol: el siguiente mensaje recupera el mismo A/B.
    _messages.clear();
    _historyCleared = true;
    notice = 'Historial local eliminado. Tu identidad se conserva.';
    _changed();
  }

  Future<void> requestReset() async {
    if (!canReset) return;
    _resetting = true;
    notice = null;
    _changed();
    // RESET es el control que entiende la app del compañero; reinicia ambos lados.
    final sent = await _send({'type': 'reset'});
    if (_disposed) return;
    _resetting = false;
    if (sent) {
      _resetRoles();
      notice = 'Chat y roles reiniciados. El próximo en escribir será A.';
    } else {
      notice = 'No se pudo avisar al compañero. Se conservan el historial y el rol.';
    }
    _changed();
  }

  void _resetRoles() {
    _resetVersion++;
    _messages.clear();
    _assignedDevice = automaticRoles ? null : _preferredDevice;
    _historyCleared = false;
  }

  Future<bool> _send(Map<String, Object> packet) async {
    try { return await sendPacket(packet); } catch (_) { return false; }
  }

  void _changed() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}
