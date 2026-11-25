# Genera despliegue.html y datos.html con el mismo estilo de arquitectura.html.
# Uso: python tool/diagramas/generar_despliegue_datos.py  (luego capturar con Chrome headless)
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
head = open(os.path.join(AQUI, 'arquitectura.html'), encoding='utf-8').read().split('</defs>')[0] + '</defs>'


def svg_head(title, w, h):
    return (head.replace('<title>Arquitectura CEOSMOS</title>', f'<title>{title}</title>')
            .replace('width="1400" height="860" viewBox="0 0 1400 860"',
                     f'width="{w}" height="{h}" viewBox="0 0 {w} {h}"'))


def box(x, y, w, h, cls, t, subs, rx=12):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" class="caja {cls}"/>'
    s += f'<text x="{x+14}" y="{y+24}" class="h">{t}</text>'
    for i, l in enumerate(subs):
        s += f'<text x="{x+14}" y="{y+44+i*17}" class="s">{l}</text>'
    return s


def zona(x, y, w, h, t):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" class="zona"/>'
            f'<text x="{x+18}" y="{y+26}" class="zt">{t}</text>')


# ---------- DESPLIEGUE ----------
b = svg_head('Despliegue CEOSMOS', 1400, 820)
b += '<text x="30" y="46" class="t" font-size="30">Diagrama de despliegue · CEOSMOS Móvil Integral 1.3.0</text>'
b += zona(30, 80, 420, 700, 'EQUIPOS DEL USUARIO')
b += box(55, 120, 370, 130, 'guinda', 'Galaxy S24 · app Android (APK)',
         ['Flutter 3.41 · Dart 3.11', 'Token en Keystore (almacén seguro)',
          'Copia sin conexión: perfil + sesiones pendientes', 'Central BLE · cliente TCP del wearable'])
b += box(55, 275, 370, 130, 'cian', 'Navegador · PWA (Chrome / Edge)',
         ['Misma base de código compilada a web', 'manifest.json + sw.js propio (31 archivos)',
          'Servida en http://localhost:4200 (demostración)', 'Web Bluetooth: central (no verificado en hardware)'])
b += box(55, 430, 370, 150, 'ambar', 'Galaxy Tab S9 · apps Kotlin',
         ['CEOSMOS Reloj: periférico GATT; pulso y', '  pasos SIMULADOS, botón y vibración',
          'CEOSMOS TV: periférico GATT, D-pad;', '  proyecta la sesión', 'PIN de 6 dígitos · servicio en primer plano'])
b += box(55, 605, 370, 90, 'caja', 'Wearable TCP (opcional)',
         ['Misma red Wi-Fi · una línea JSON por lectura', 'Solo app Android (el navegador no abre sockets)'])
b += zona(500, 80, 560, 700, 'NUBE (PRODUCCIÓN)')
b += box(530, 120, 500, 130, 'guinda', 'API CEOSMOS · NestJS 11 + Prisma 5',
         ['Vercel, región iad1 (EE. UU. Este)', 'https://ceosmos-api.vercel.app/api',
          'JWT HS256 · roles USER / ADMIN · CORS con lista', 'CSP · 120 peticiones/min (acceso 10/min)'])
b += box(530, 290, 500, 110, 'cian', 'PostgreSQL · Neon (us-east-1)',
         ['Fuente única de verdad de CEOSMOS', 'Relacional + JSONB (metadata, configuration)',
          'Conexión TLS desde la API (Prisma)'])
b += box(530, 430, 500, 130, 'ambar', 'Firebase (proyectos separados)',
         ['Soporte · Tickets y chat (Auth + Firestore)', 'Reportes compartidos (Firestore)',
          'Incidencias en tiempo real / Mis incidencias', 'Reglas por rol · us-central1 / nam5'])
b += box(530, 595, 500, 90, 'caja', 'Resend (correo)',
         ['Códigos de verificación y enlaces', 'de recuperación de contraseña'])
b += zona(1110, 80, 260, 700, 'DESARROLLO')
b += box(1130, 120, 220, 150, 'caja', 'GitHub (público)', ['CE0S23/', 'CEOSMOS-MovilIntegral', 'tags entrega-v1…v4'])
b += box(1130, 300, 220, 170, 'cian', 'GitHub Actions',
         ['Flutter: analyze + test', 'PWA: build + sw.js', 'Kotlin: Reloj, TV,', 'Companion (test + lint)', 'Sin secretos'])
b += box(1130, 500, 220, 120, 'caja', 'Equipo de desarrollo', ['flutter build apk', 'construir_pwa.ps1', 'adb install -r'])
b += '<path d="M425 160 L530 160" class="l"/><text x="434" y="152" class="et">HTTPS · JWT</text>'
b += '<path d="M425 330 L470 330 L470 205 L530 205" class="l"/><text x="432" y="348" class="et">HTTPS</text>'
b += '<path d="M780 250 L780 290" class="l"/><text x="790" y="275" class="et">Prisma · TLS</text>'
b += '<path d="M1030 185 L1065 185 L1065 640 L1030 640" class="l"/><text x="1036" y="625" class="et">REST</text>'
b += '<path d="M425 230 L490 230 L490 480 L530 480" class="l"/><text x="434" y="470" class="et">SDK Firebase</text>'
b += '<path d="M55 200 L42 200 L42 500 L55 500" class="lb"/><text x="70" y="422" class="etb">BLE GATT · reto + HMAC</text>'
b += '<path d="M330 405 L330 430" class="lt"/><text x="340" y="422" class="et" style="fill:#9A5800">Web BT</text>'
b += '<path d="M425 245 L438 245 L438 650 L425 650" class="lt"/><text x="395" y="598" class="et" style="fill:#9A5800">TCP</text>'
b += '<path d="M1240 270 L1240 300" class="l"/><path d="M1240 500 L1240 470" class="l"/>'
b += ('<text x="30" y="808" class="s">Continuas: probado en producción o en hardware. Discontinuas: Web Bluetooth '
      '(no verificado en hardware) y TCP (alternativa). Fuente: tool/diagramas/despliegue.html.</text>')
b += '</svg></body></html>'
open(os.path.join(AQUI, 'despliegue.html'), 'w', encoding='utf-8').write(b)

# ---------- DATOS ----------
d = svg_head('Datos CEOSMOS', 1400, 900)
d += '<text x="30" y="46" class="t" font-size="30">Modelo de datos y almacenamiento propio por función</text>'
d += zona(30, 80, 760, 790, 'POSTGRESQL (NEON) · ESQUEMA PRISMA DE LA API')
d += box(300, 115, 220, 100, 'guinda', 'User', ['id (uuid) · email único', 'role: USER | ADMIN'])
ents = [
    (55, 280, 'FocusSession', ['contentKey · mode FOCUS /', 'RELAX / INSPIRE · duración', 'metadata JSONB (wearable)', 'clientId único por usuario']),
    (300, 280, 'LinkedDevice', ['type WEARABLE | TV', 'transport TCP | BLE', 'address (CE:05:&lt;id&gt; en BLE)', 'configuration JSONB']),
    (545, 280, 'Favorite', ['contentKey', 'único por usuario']),
    (55, 470, 'Preferences', ['1 : 1 con User', 'preferencias de sesión']),
    (300, 470, 'MediaItem', ['biblioteca propia', 'type (imagen / audio)', 'solo URL https']),
    (545, 470, 'Session · EmailToken', ['sesión de autenticación', 'códigos de correo']),
    (55, 640, 'AuditLog', ['bitácora de acciones', 'metadata JSONB', 'userId opcional']),
    (300, 640, 'Passkey', ['WebAuthn (web;', 'no implementado en móvil)']),
    (545, 640, 'Task', ['tareas heredadas', 'de CEOSMOS WEB']),
]
d += '<path d="M410 215 L410 255 M165 255 L655 255" class="l" style="marker-end:none"/>'
for x in (165, 410, 655):
    d += f'<path d="M{x} 255 L{x} 280" class="l"/>'
for x, y, t, s in ents:
    d += box(x, y, 220, 50 + 17 * len(s) + 10, 'caja', t, s)
d += ('<text x="55" y="850" class="s">Todas las tablas (las nueve) dependen de User (1 : N; Preferences 1 : 1) con borrado en cascada; '
      'AuditLog conserva el registro (SET NULL).</text>')
d += zona(820, 80, 550, 790, 'ALMACENAMIENTO PROPIO POR FUNCIÓN')
rows = [
    ('Sesiones, favoritos y equipos', 'PostgreSQL (API de CEOSMOS)', 'guinda'),
    ('Token de acceso', 'Keystore / almacén seguro', 'guinda'),
    ('Perfil y sesiones pendientes', 'SharedPreferences / localStorage', 'guinda'),
    ('Tickets y chat interno', 'Firebase propio (Auth + Firestore)', 'ambar'),
    ('Reportes compartidos (Flutter y Android)', 'Firebase propio (Firestore)', 'ambar'),
    ('Incidencias en tiempo real', 'Firebase propio + caché local', 'ambar'),
    ('Mis incidencias y acceso', 'Firebase propio + reglas por cuenta', 'ambar'),
    ('Incidencias sin conexión', 'SharedPreferences propio', 'cian'),
    ('Directorio de alumnos', 'SQLite (Floor), versión 2', 'cian'),
    ('Citas de bienestar', 'API HTTPS propia + almacén seguro propio', 'cian'),
    ('Mensajería entre equipos', 'Sin BD (memoria)', ''),
    ('Seguridad de la cuenta', 'Sin BD (validación nativa)', ''),
    ('PIN del Reloj y la TV', 'Almacén seguro del teléfono', 'cian'),
    ('App shell de la PWA', 'Cache Storage del service worker', 'cian'),
]
for i, (f, s, c) in enumerate(rows):
    y = 115 + i * 52
    d += (f'<rect x="845" y="{y}" width="500" height="44" rx="10" class="caja {c}"/>'
          f'<text x="860" y="{y+19}" class="h" style="font-size:13.5px">{f}</text>'
          f'<text x="860" y="{y+36}" class="s">{s}</text>')
d += '<text x="845" y="850" class="s">Fuente: memoria/12 - Mapa de funciones.md · tool/diagramas/datos.html</text>'
d += '</svg></body></html>'
open(os.path.join(AQUI, 'datos.html'), 'w', encoding='utf-8').write(d)
print('ok')
