// PWA: manifiesto instalable, service worker propio (offline sin guardar datos
// personales), atajos del manifiesto y mensajes de Web Bluetooth.
import 'dart:convert';
import 'dart:io';

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_transporte.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_transporte_fbp.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Manifiesto', () {
    final m = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map<String, dynamic>;

    test('tiene lo que Chrome exige para instalar', () {
      for (final campo in ['name', 'short_name', 'start_url', 'display', 'icons', 'id', 'scope']) {
        expect(m[campo], isNotNull, reason: campo);
      }
      expect(m['display'], 'standalone');
      final iconos = (m['icons'] as List).cast<Map<String, dynamic>>();
      expect(iconos.map((i) => i['sizes']), containsAll(['192x192', '512x512']));
      expect(iconos.where((i) => i['purpose'] == 'maskable'), isNotEmpty);
      for (final i in iconos) {
        expect(File('web/${i['src']}').existsSync(), isTrue, reason: i['src'] as String);
      }
    });

    test('capturas y atajos apuntan a archivos y pestañas reales', () {
      for (final c in (m['screenshots'] as List).cast<Map<String, dynamic>>()) {
        expect(File('web/${c['src']}').existsSync(), isTrue, reason: c['src'] as String);
      }
      for (final a in (m['shortcuts'] as List).cast<Map<String, dynamic>>()) {
        final url = Uri.parse('https://x/${a['url']}');
        expect(pestanaDesdeUrl(url), greaterThan(0), reason: a['url'] as String);
      }
    });
  });

  group('Service worker', () {
    final sw = File('web/sw.js').readAsStringSync();
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    test('se registra el propio y no el de Flutter (que se desregistra solo)', () {
      expect(bootstrap, contains("register('sw.js'"));
      expect(bootstrap, isNot(contains('serviceWorkerSettings')));
      expect(File('web/index.html').readAsStringSync(), contains('manifest.json'));
    });

    test('precarga el app shell y responde sin red con el index guardado', () {
      expect(sw, contains("const VERSION = 'dev';"), reason: 'marcador que reemplaza pwa_precache.py');
      expect(sw, contains('const PRECARGA = ['));
      expect(sw, contains("addEventListener('install'"));
      expect(sw, contains("cache.match('index.html')"));
    });

    test('nunca guarda la API, Firebase ni peticiones que no sean GET', () {
      expect(sw, contains("if (req.method !== 'GET') return;"));
      for (final patron in [r'/\/api\//', 'firestore', 'identitytoolkit', 'securetoken']) {
        expect(sw, contains(patron));
      }
    });
  });

  test('Atajo de la PWA: ?pestana= abre la pestaña; sin parámetro o inválido, Inicio', () {
    expect(pestanaDesdeUrl(null), 0);
    expect(pestanaDesdeUrl(Uri.parse('https://x/')), 0);
    expect(pestanaDesdeUrl(Uri.parse('https://x/?pestana=Equipos')), 3);
    expect(pestanaDesdeUrl(Uri.parse('https://x/?pestana=nada')), 0);
  });

  test('Web Bluetooth: cancelar, permiso negado y sin equipos dan mensajes claros', () {
    expect(
      BleTransporteFbp.traducirErrorWeb('NotFoundError: User cancelled the requestDevice() chooser.'),
      isA<FalloBle>().having((f) => f.mensaje, 'mensaje', contains('selector')),
    );
    expect(BleTransporteFbp.traducirErrorWeb('SecurityError: not allowed'), isA<PermisoBleDenegado>());
    expect(
      BleTransporteFbp.traducirErrorWeb('NotFoundError: No devices found'),
      isA<FalloBle>().having((f) => f.mensaje, 'mensaje', contains('no encontró')),
    );
    expect(mensajeSinBle, contains('Bluetooth LE'));
  });
}
