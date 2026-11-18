// Práctica 6 (MobileConnect): cada requisito de las indicaciones como caso verificable
// sobre la lógica de la conversación (ChatSession), sin red.
import 'package:ceosmos_movil_integral/practicas/p06/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, Object>> enviados;
  late bool canalDisponible;

  ChatSession nueva({DeviceId local = DeviceId.a}) => ChatSession(
        localDevice: local,
        sendPacket: (paquete) async {
          if (!canalDisponible) return false;
          enviados.add(paquete);
          return true;
        },
      );

  setUp(() {
    enviados = [];
    canalDisponible = true;
  });

  test('R1/R2: dos dispositivos con nombre y emisor seleccionable', () {
    expect(DeviceId.a.label, 'A');
    expect(DeviceId.b.label, 'B');
    expect(DeviceId.a.peer, DeviceId.b);
    expect(nueva(local: DeviceId.b).localDevice, DeviceId.b);
  });

  test('R6: rechaza mensajes vacíos, solo espacios y de más de 200 caracteres', () async {
    final s = nueva();
    for (final borrador in ['', '   ', '\n\t', 'x' * 201]) {
      expect(await s.sendMessage(borrador), isFalse);
    }
    expect(enviados, isEmpty);
    expect(s.messages, isEmpty);
    expect(s.notice, 'El mensaje supera 200 caracteres.');
    expect(await s.sendMessage('x' * 200), isTrue); // valor límite aceptado
  });

  test('R4/R5/R7 + hora: envía, lista con emisor, hora HH:mm y aviso visual', () async {
    final s = nueva();
    expect(await s.sendMessage('  Hola B  '), isTrue);
    expect(enviados.single['text'], 'Hola B');
    expect(enviados.single['sender'], 'A');
    final m = s.messages.single;
    expect(m.sender, DeviceId.a);
    expect(m.text, 'Hola B');
    expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(m.time), isTrue);
    expect(s.notice, 'Mensaje enviado al dispositivo B');
  });

  test('Recepción: el mensaje del otro dispositivo aparece con su emisor', () async {
    final s = nueva();
    await s.receive({'type': 'message', 'sender': 'B', 'text': 'Hola A', 'time': '10:30'});
    expect(s.messages.single.sender, DeviceId.b);
    expect(s.notice, 'Mensaje recibido del dispositivo B');
    // Paquetes mal formados se ignoran (no rompen la conversación).
    await s.receive({'type': 'message', 'sender': 'Z', 'text': 'x', 'time': '1'});
    await s.receive({'type': 'message', 'sender': 'B', 'text': '   ', 'time': '1'});
    await s.receive({'type': 'message', 'sender': 'B', 'text': 'x', 'time': 'x' * 17});
    expect(s.messages, hasLength(1));
  });

  test('Contador por dispositivo y botón de limpiar historial', () async {
    final s = nueva();
    await s.sendMessage('uno');
    await s.sendMessage('dos');
    await s.receive({'type': 'message', 'sender': 'B', 'text': 'tres', 'time': '10:31'});
    expect(s.count(DeviceId.a), 2);
    expect(s.count(DeviceId.b), 1);
    await s.clearHistory();
    expect(s.messages, isEmpty);
    expect(s.count(DeviceId.a), 0);
    expect(s.localHistoryCleared, isTrue);
    expect(s.localDevice, DeviceId.a); // limpiar no cambia la identidad
  });

  test('Falla del canal: no se agrega el mensaje ni se confirma el envío', () async {
    final s = nueva();
    canalDisponible = false;
    expect(await s.sendMessage('hola'), isFalse);
    expect(s.messages, isEmpty);
    expect(s.notice, 'No se pudo enviar el mensaje.');
  });
}
