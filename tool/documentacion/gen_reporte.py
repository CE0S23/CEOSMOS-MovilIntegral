# -*- coding: utf-8 -*-
"""Genera «Reporte de avances - CEOSMOS revicion.docx»: prácticas integradas como funciones, calidad y pruebas,
blindaje y riesgos. Los apartados A1–A3, B1 y B2 viven en el Documento de seguimiento.
Cifras: evidencias/documentacion/cifras.md. Uso: python tool/documentacion/gen_reporte.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from docgen import Doc, REPO  # noqa: E402

R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
E = lambda *p: os.path.join(R, 'evidencias', *p)  # noqa: E731
CI_13 = REPO + '/actions/runs/45686893198'
CI_V4 = REPO + '/actions/runs/45099965435'
CI_P13 = REPO + '/actions/runs/44438169735'

d = Doc(os.path.join(R, 'Manual de usuario - CEOSMOS.docx'), 'Reporte de avances')
d.margenes()
d.propiedades('Reporte de avances - CEOSMOS', 'Prácticas integradas como funciones, calidad y pruebas, blindaje y riesgos de CEOSMOS Móvil Integral 1.3.0',
              'CEOSMOS; reporte de avances; prácticas; pruebas; CI; blindaje')
d.encabezado_pie('Reporte de avances · versión 1.3.0')
d.portada(E('documentacion', 'logo_portada.png'), 'Reporte de avances', 'Formato de Avances de Proyecto',
          ['Versión de la app: 1.3.0 · Versión del documento: 3.0', 'Fecha: 25 de noviembre de 2026'],
          ['César Osvaldo Ramírez Pérez', 'Matrícula 2023371167 · Grupo IDGS16',
           'Profesor: M.C.C. Emmanuel Martínez Hernández', 'Repositorio: github.com/CE0S23/CEOSMOS-MovilIntegral'])

d.h1('Control de versiones')
d.tabla([['Versión', 'Fecha', 'Cambios'],
         ['1.0', '18/11/2026', 'Prácticas del curso aplicadas en la app CEOSMOS.'],
         ['1.1', '19–21/11/2026', 'Soporte con roles completado; prácticas reescritas como funciones; «Calidad y pruebas».'],
         ['2.0', '22/11/2026', 'Blindaje y versión 1.2.1.'],
         ['2.1', '24/11/2026', 'Revisión contra la rúbrica (planteamiento, seguimiento, decisiones, arquitectura, PWA, dispositivos).'],
         ['3.0', '25/11/2026', 'Los apartados de planteamiento, seguimiento, decisiones, arquitectura e interfaz se mueven al Documento de seguimiento; aquí queda un resumen con referencia. Cifras de la versión 1.3.0 (344 pruebas, cobertura 56.0 %, 29 corridas de CI); tabla de prácticas por función; entregables de las prácticas de automatización.']],
        [1.6, 2.6, 12.8], 'Control de versiones del documento')
d.p('Cifras: `evidencias/documentacion/cifras.md` (corte del 25/11/2026). Lo no probado se marca **no verificado**; los riesgos aceptados se dicen tal cual.')
d.indice()
d.lista_figuras()
d.lista_tablas()

# 1
d.h1('1. Proyecto y resumen')
d.p('**CEOSMOS: Ecosistema Móvil Integral** — unificación de CEOSMOS WEB y CEOSMOS para Dispositivos Inteligentes en una sola aplicación '
    'Flutter que se distribuye como app Android y como aplicación web progresiva (PWA), conectada a la API NestJS + PostgreSQL de CEOSMOS WEB y a '
    'las apps Reloj y TV por Bluetooth LE.', alin='j')
d.p('Este reporte registra cómo cada práctica del curso quedó integrada como una función de CEOSMOS, la calidad y las pruebas aplicadas y los '
    'riesgos aceptados. El planteamiento del problema, la justificación, los objetivos, la cronología, las decisiones, la arquitectura y la '
    'interfaz están en el **Documento de seguimiento del proyecto - CEOSMOS** (no se duplican aquí):', alin='j')
d.tabla([['Tema', 'Dónde está'],
         ['Planteamiento, justificación, usuarios, objetivos con estado, alcance y metodología (A1)', 'Seguimiento §1'],
         ['Cronología con fechas de git, hitos, plan por parcial contra lo entregado, indicadores y pendientes (A2)', 'Seguimiento §2'],
         ['Decisiones con alternativas y evidencia, cambios de plan, incidentes y lecciones (A3)', 'Seguimiento §3'],
         ['Arquitectura, despliegue, secuencia BLE, datos, APIs y seguridad (B1)', 'Seguimiento §4'],
         ['Sistema de diseño, navegación por rol, flujos, accesibilidad y capturas (B2)', 'Seguimiento §5'],
         ['PWA y dispositivos inteligentes (C, D)', 'Seguimiento §6; Matriz de cumplimiento'],
         ['Uso de la app por rol', 'Manual de usuario - CEOSMOS']],
        [11.5, 5.5], 'Dónde está cada apartado de la documentación')
d.p('**Estado resumido (25/11/2026):** versión 1.3.0 con 344/344 pruebas Flutter, 79/79 de la API y 14/14 por cada app Kotlin; integración '
    'continua en verde ([corrida de la 1.3.0](' + CI_13 + ')). En los equipos sigue instalada la 1.2.1: el APK 1.3.0 está **en curso** '
    '(equipos no conectados).', alin='j')

# 2
d.h1('2. Prácticas integradas como funciones de CEOSMOS')
d.p('Desde el 21/11 ninguna práctica vive en una ventana aparte: cada una es una función con nombre propio, en el menú que le corresponde, '
    'con su rol y su propio almacenamiento. Ningún texto visible de la app dice «Práctica», «P#» ni «Examen» (lo verifica una prueba automática). '
    'La práctica original se menciona aquí por su tema.', alin='j')
d.tabla([['Función', 'Práctica original (tema)', 'Menú', 'Rol', 'Datos propios'],
         ['Tickets y chat interno', 'Asignación de roles e interacción de situaciones', 'Soporte', 'Usuario, agente, administrador', 'Firebase propio (Auth + Firestore) con reglas por rol'],
         ['Reportes compartidos (Flutter y Android)', 'Base de datos en la nube con Firestore', 'Soporte › Reportes e incidencias', 'Cualquier usuario', 'Firebase propio (Firestore), compartido por ambas versiones'],
         ['Incidencias en tiempo real', 'Conexiones y pruebas de BD entre dispositivos', 'Soporte › Reportes e incidencias', 'Cualquier usuario, dos equipos', 'Firebase propio con caché local'],
         ['Mis incidencias y acceso', 'Seguridad, autenticación y control de acceso', 'Soporte › Reportes e incidencias', 'Cada cuenta ve lo propio o asignado', 'Firebase propio con cuentas y reglas'],
         ['Incidencias sin conexión', 'Examen práctico de incidencias de soporte', 'Soporte', 'Cualquier usuario', 'SharedPreferences propio'],
         ['Mensajería entre equipos', 'Interacción entre dispositivos', 'Equipos', 'Cualquier usuario', 'Sin BD (memoria)'],
         ['Seguridad de la cuenta', 'Código seguro', 'Perfil › Cuenta y herramientas', 'Cualquier usuario', 'Sin BD (validación nativa)'],
         ['Directorio de alumnos', 'Consumo de servicio web y almacenamiento estructurado', 'Perfil › Cuenta y herramientas', 'Cualquier usuario', 'SQLite (Floor) v2'],
         ['Citas de bienestar', 'Evaluación de servicios seguros (MediConnect)', 'Perfil › Cuenta y herramientas', 'Cualquier usuario (requiere el servidor de citas)', 'API HTTPS propia + almacén seguro propio'],
         ['Aviso «Sin conexión» y sincronización', 'Optimización, estrés y resiliencia', 'Dentro de Soporte y de la app', '—', '—'],
         ['Calidad y pruebas (sin pantalla)', 'Caja negra, caja blanca y automatización con CI', '—', '—', '`test/`, `integration_test/`, CI']],
        [3.3, 3.8, 3.2, 3.0, 3.7], 'Prácticas integradas como funciones', tam=8.5)
funcs = [
    ('2.1 Tickets y chat interno',
     'El usuario crea tickets con turno y consulta su historial; el agente atiende los asignados y puede pasarlos al administrador; el administrador '
     've la gestión completa (asignados, todos los tickets y dispositivos conectados), reasigna, cambia la prioridad, elimina y limpia el historial. El '
     'rol lo fija un documento en Firestore que las reglas del servidor verifican. El chat muestra emisor, hora y contador por dispositivo, impide '
     'mensajes vacíos y acepta adjuntos de hasta 300 KB. **Cómo se probó:** el 19/11 con las cuatro cuentas entre el teléfono y la tablet, matriz '
     'TC01–TC08 aprobada (alta, campos vacíos, identificador repetido, actualización, eliminación, documento inexistente, pérdida de conexión y '
     'persistencia). Con la 1.2.1 (22/11) se repitió con tres de los cuatro roles: alta, mensajes en tiempo real (2 s), adjunto de 203 KB aceptado y '
     'de 434 KB rechazado, asignación (3 s) y presencia; la segunda cuenta de usuario **no se volvió a probar (no verificado)**.'),
    ('2.2 Reportes compartidos',
     'Cualquier usuario registra reportes, los consulta desde el servidor, actualiza su prioridad con transacciones y los elimina. La versión Flutter y '
     'la versión Android (Kotlin) operan la misma colección en un proyecto de Firebase separado del de CEOSMOS.'),
    ('2.3 Incidencias en tiempo real',
     'Dos equipos comparten la misma base en la nube: lo que uno escribe aparece en el otro al instante, la modificación simultánea se detecta campo '
     'por campo con aviso de conflicto, hay bitácora de eventos y las escrituras sin conexión se sincronizan al volver la red.'),
    ('2.4 Mis incidencias y acceso',
     'Cada persona entra con su cuenta; los registros guardan el UID del propietario y las reglas solo permiten ver y editar lo propio o lo asignado y '
     'rechazan operar sin sesión. Incluye una verificación de permisos que comprueba esas reglas. En CEOSMOS el control de acceso general lo aplica '
     'la API (JWT, roles USER y ADMIN y datos filtrados por usuario).'),
    ('2.5 Incidencias sin conexión',
     'Registrar, consultar y eliminar fallas del equipo en el propio teléfono, aunque no haya red, en un almacenamiento local independiente.'),
    ('2.6 Mensajería entre equipos',
     'Dos teléfonos de la misma red Wi-Fi conversan por TCP (o en modo de simulación) con emisor, hora, contador por dispositivo, limpieza de '
     'historial, aviso visual y rechazo de mensajes vacíos. La interacción entre dispositivos se completa con el Reloj y la TV por Bluetooth LE.'),
    ('2.7 Seguridad de la cuenta',
     'Valida usuario y contraseña en la capa nativa (Kotlin) por un canal de plataforma: campos obligatorios, límites de longitud, contraseña oculta, '
     'usuario con espacios rechazado, mínimo de 8 caracteres, errores genéricos y sin credenciales en Logcat. Los mismos principios protegen el '
     'inicio de sesión real (token en almacén seguro y errores sin datos técnicos).'),
    ('2.8 Directorio de alumnos',
     'Alta, consulta, edición y baja de alumnos en SQLite mediante Floor, con el campo correo agregado por una migración a la versión 2, y consulta '
     'asíncrona a un servicio web con estados de carga y error. En CEOSMOS el mismo patrón es el cliente de la API que usan acceso, favoritos, '
     'sesiones y dispositivos.'),
    ('2.9 Citas de bienestar',
     'Inicia sesión con token, consulta y registra citas contra su propia API HTTPS con certificado fijado y peticiones idempotentes, y guarda sus '
     'credenciales en un almacén seguro separado. Requiere el servidor de citas en la computadora.'),
]
for t, txt in funcs:
    d.h2(t)
    d.p(txt, alin='j')
d.figuras_lado([E('manual', 'm_soporte.png'), E('manual', 'm_chat_admin.png'), E('manual', 'm_herramientas.png')],
               'Soporte, chat de un ticket visto por el administrador y Perfil › Cuenta y herramientas (capturas del Manual)', 8.5,
               'Capturas de la pestaña Soporte, del chat de un ticket y de Cuenta y herramientas')

# 3
d.h1('3. Calidad y pruebas')
d.h2('3.1 Pruebas de caja negra')
d.p('Derivadas de la práctica de evaluación de calidad mediante caja negra. Se aplican sobre CEOSMOS con 12 requisitos verificables (operaciones, '
    'validaciones, persistencia, navegación y roles, manejo de errores) y una suite automatizada que corre en cada revisión, ampliada con pruebas '
    'del Reloj y la TV y con una prueba que recorre la navegación y verifica que ningún texto visible nombre las prácticas.', alin='j')
d.h2('3.2 Pruebas de caja blanca')
d.p('Derivadas de la práctica de pruebas White Box. Análisis estático, pruebas unitarias por caminos independientes, cobertura de instrucciones, '
    'decisiones y condiciones, códigos HTTP, consultas con EXPLAIN y mediciones de red sobre la app, la API y la base; los defectos encontrados se '
    'corrigieron en el código.', alin='j')
d.h2('3.3 Optimización, estrés y resiliencia')
d.p('Pruebas de estrés de la API, profiling de la app y de la base, escenarios de pérdida de conexión y errores del servidor, reintentos con espera '
    'progresiva y escrituras idempotentes para no duplicar sesiones. En la app se ve como el aviso «Sin conexión», la sincronización automática y la '
    'reconexión del Reloj y la TV; desde la 1.3.0 también como el modo sin conexión de la app y de la PWA (sesiones pendientes que sobreviven al cierre).', alin='j')
d.h2('3.4 Automatización de pruebas e integración continua')
d.p('Derivada de las prácticas de automatización de pruebas y validación continua. Hay pruebas de tres componentes críticos: **acceso** (validación '
    'de inicio de sesión y registro), **comunicación** (cliente de la API contra un servidor HTTP local y protocolo BLE reto + HMAC en Dart y Kotlin) '
    'y **persistencia** (directorio de alumnos en SQLite con la migración del campo correo), más una prueba de regresión del defecto «TV reiniciada '
    'seguía Conectado». El pipeline de GitHub Actions (`.github/workflows/ci.yml`) corre en cada push y pull request: análisis estático y pruebas de '
    'Flutter con cobertura, compilación de la PWA con verificación del service worker, y pruebas y lint de las apps Reloj, TV y Companion; publica '
    'reportes y cobertura. Ninguna prueba usa la base ni la API de producción.', alin='j')
d.p('Hasta la versión 1.3.0 se ejecutaron **29 corridas**: 27 en verde, 1 fallida (21/11, aviso del análisis estático en el arnés de capturas, '
    'corregido en la siguiente) y 1 cancelada (reemplazada por un push posterior). Corridas de referencia: '
    f'[1.3.0]({CI_13}) · [entrega-v4]({CI_V4}) · [main tras las prácticas de automatización]({CI_P13}).', alin='j')
d.h2('3.5 Resultado de las prácticas de automatización (13 y 14)')
d.tabla([['Entregable', 'Requisito', 'Estado', 'Ruta o URL'],
         ['Repositorio', 'Al día y público', 'Cumplido', REPO],
         ['Pruebas unitarias', '≥ 5', 'Cumplido: 16 Dart + 5 Kotlin', '`test/p13_14/aut01_03_unitarias_test.dart`, `aut03_regresion_tv_reiniciada_test.dart`; `companion/.../AutomatizacionProtocoloTest.kt`'],
         ['Pruebas de integración', '≥ 3', 'Cumplido: 11', '`test/p13_14/aut04_integracion_api_test.dart`, `aut05_servidor_sin_respuesta_test.dart`, `aut06_persistencia_p04_test.dart`'],
         ['Archivo del pipeline', 'ci.yml', 'Cumplido', '`.github/workflows/ci.yml`'],
         ['Evidencia del pipeline', 'Ejecución automática', 'Cumplido: runs #1–#9 en verde (logs y capturas); 1.3.0 en verde', '`evidencias/p13_14/ci_run_*.txt`, `ci_01…ci_04`; ' + CI_13],
         ['Matriz AUT-01 a AUT-08', 'Completa con resultado y evidencia', 'Cumplido: 8/8 aprobadas', 'Reporte técnico, §7'],
         ['Reporte técnico', '1 a 2 cuartillas, letra ≥ 11 pt', 'Cumplido: 2 páginas, 11 pt', '`evidencias/p13_14/Practicas 13-14 - Automatizacion de pruebas - CEOSMOS.docx/.pdf`']],
        [2.8, 2.8, 4.0, 7.4], 'Entregables de las prácticas 13 y 14', tam=8.5)
d.p('Las 27 pruebas Dart de estas prácticas siguen en el repositorio y pasan dentro de las 344 actuales; las 5 de Kotlin, dentro de las 14 de cada app (25/11/2026).', alin='j')
d.figura(E('p13_14', 'ci_04_actions_main_verde.png'), 'GitHub Actions con la rama main en verde tras fusionar las pruebas automatizadas (19/11)', 15.0,
         'Captura de la página de GitHub Actions con las corridas en verde')
d.h2('3.6 Resumen de pruebas y resultados')
d.tabla([['Conjunto', 'Resultado', 'Fecha', 'Tipo'],
         ['Pruebas de Flutter', '344/344; análisis estático sin avisos', '25/11', 'medido'],
         ['Pruebas de la API (Jest)', '79/79 (7 suites)', '25/11', 'medido'],
         ['Pruebas de Kotlin', 'Reloj, TV y Companion: 14/14 cada una; lint en CI', '25/11', 'medido'],
         ['Cobertura de líneas', '56.0 % (3 373 de 6 023); núcleo 84.8 %', '25/11', 'medido'],
         ['Integración continua', '29 corridas, 27 en verde; la de la 1.3.0 en verde', '25/11', 'medido'],
         ['Caja negra', '12 requisitos y suite automatizada', 'cada revisión', 'medido'],
         ['Caja blanca', 'Caminos independientes, decisiones y condiciones, EXPLAIN y códigos HTTP', '11/11', 'medido'],
         ['Red Box de la API', '13/13 original y 37/37 ampliado en local; 27/27 en producción sin credenciales', '22/11', 'medido'],
         ['Usuario torpe', '12 100 acciones (S24 5 000, Tab S9 5 000 + 2 100)', '22/11', 'medido'],
         ['Reloj y TV de punta a punta', '6 de 7 en hardware; reconexión corregida en 1.2.1; tercer equipo no verificado', '22/11', 'medido'],
         ['Soporte con roles', 'TC01–TC08 con 4 cuentas; 3 de 4 roles con 1.2.1', '19 y 22/11', 'medido'],
         ['PWA y modo sin conexión', 'Instalable (0 errores), sin red y sincronización sin duplicados', '24/11', 'medido en Chromium'],
         ['Web Bluetooth con Reloj y TV reales', '—', '—', 'no verificado']],
        [4.0, 8.0, 2.2, 2.8], 'Resumen de pruebas y resultados', tam=9)

# 4
d.h1('4. Blindaje para la entrega')
d.h2('4.1 Pasada final de regresión')
d.p('Sobre `entrega-v4` (1.2.1, 22/11) pasaron 331 pruebas de Flutter, 79 de la API y 14 por cada app Kotlin, con cobertura de 52.9 % (núcleo 78.9 %). '
    'Con la 1.3.0 (PWA, modo sin conexión y cabecera de tabletas) pasan 344 (13 nuevas: 6 del modo sin conexión y 7 de la PWA) y la cobertura sube a '
    '56.0 % (núcleo 84.8 %). La 1.3.0 aún no está instalada en los equipos.', alin='j')
d.h2('4.2 Usuario torpe dentro de la app')
d.p('Una prueba de integración ejecuta acciones al azar (toques, textos inválidos, Atrás y desplazamientos) en una copia aislada de la app, sin '
    'tocar ajustes ni datos reales: 5 000 en el S24 (sin errores, cierres ni ANR) y 5 000 en la Tab S9 (sin cierres ni ANR, con 4 desbordes en «Agregar '
    'a mi biblioteca»); tras corregirlo, 2 100 de verificación con 0 errores. En total 12 100; el plan de 20 000 no se completó (el S24 se quedó sin '
    'batería y se decidió no repetir lo ya probado).', alin='j')
d.h2('4.3 Tamaño mínimo funcional')
d.p('Un barrido de 91 tamaños (240 a 1600 dp de ancho, 320 a 1000 de alto) no muestra desbordes. En la tablet, la ventana flotante se probó en 14 '
    'tamaños: cómoda desde 260 × 440 dp y sin errores hasta 220 × 380 dp. Áreas táctiles ≥ 48 dp y fuente del sistema al 200 %.', alin='j')
d.h2('4.4 Seguridad verificada')
d.p('La API resistió los 13 ataques del Red Box original y, tras corregir 6 fallos hallados por el ampliado, los 37 casos de este. Las correcciones se '
    'desplegaron en producción el 22/11 y allí pasaron las 27 pruebas que no requieren iniciar sesión. Firestore rechaza lecturas y escrituras sin '
    'sesión salvo una colección de presencia de un proyecto que pertenece a otra cuenta. El análisis de secretos del historial no halló credenciales '
    'de servidor y los secretos de la API se rotaron.', alin='j')
d.tabla([['Conjunto', 'Dónde', 'Resultado'],
         ['Original (tokens, alg:none, inyección SQL, IDOR, asignación masiva, cuerpo enorme, rol, hash, logout)', 'API local', '13/13'],
         ['Ampliado (tokens expirados y HS512, NoSQL, JSON anidado, XSS, javascript: en medios, CORS, cabeceras, enumeración, fuerza bruta)', 'API local', '37/37 (27/37 antes de corregir)'],
         ['Producción sin credenciales (tokens falsos, inyecciones, JSON anidado, CORS, CSP, mensaje genérico, 429)', 'API de producción, ≤ 4 pet./s', '27/27']],
        [10.0, 3.8, 3.2], 'Red Box: qué se atacó y dónde')
d.p('Las pruebas que exigen iniciar sesión (IDOR, medios javascript:, cambio de rol) no se repitieron en producción: se cubren en local y en las '
    'pruebas de la API con el mismo código desplegado.', alin='j')
d.tabla([['Área MASVS', 'Estado', 'Evidencia o motivo'],
         ['Almacenamiento', 'cumple / aceptado', 'Token en Keystore; respaldo desactivado; SQLite sin cifrar y sin credenciales'],
         ['Criptografía', 'parcial', 'TLS 1.2+ y HSTS; JWT solo HS256; BLE con reto + HMAC pero carga sin cifrar'],
         ['Autenticación y autorización', 'cumple', 'Red Box: tokens, IDOR, roles, sesión tras logout'],
         ['Red', 'cumple', 'Sin texto claro; certificado no confiable rechazado con mensaje claro'],
         ['Plataforma', 'cumple / parcial', 'Solo la actividad principal exportada; capturas de pantalla permitidas'],
         ['Código', 'cumple', 'Dependencias auditadas (0 vulnerabilidades en lo distribuido); validación de entradas; errores sin trazas'],
         ['Resiliencia', 'riesgo aceptado', 'Compilación AOT, sin ofuscación ni detección de root'],
         ['Privacidad', 'parcial', 'Datos mínimos; alojados en EE. UU.; sin aviso RGPD']],
        [3.6, 3.0, 10.4], 'Mapa OWASP MASVS (resumen; detalle en evidencias/blindaje/masvs.md)')
d.h2('4.5 Plan de contingencia')
d.p('El script `arreglo_rapido` (Bash y PowerShell) analiza y prueba el área afectada, compila, instala en los dos equipos sin borrar datos y '
    'muestra el registro de errores. En el ensayo se simularon tres fallos (validación de correo, tiempo de espera de la red y permiso de Bluetooth): '
    'las pruebas detectaron los tres y cada ciclo de corrección y verificación tomó entre 1.9 y 2.4 minutos.', alin='j')
d.h2('4.6 Prueba final en los equipos')
d.p('Con el S24 como central y la tablet con Reloj y TV se comprobaron la conexión con PIN y el pulso en vivo (simulado), la notificación al Reloj, '
    'el inicio de la sesión desde la TV, la pausa desde el Reloj y la TV, el Bluetooth apagado y encendido (vuelven en menos de 8 s) y el permiso '
    'denegado (mensaje claro, sin cierre). La reconexión tras cerrar y abrir las apps del Reloj y la TV falló («Conectado» con lecturas congeladas) '
    'y se corrigió en la 1.2.1 con un latido cada 5 s (reautenticación sin PIN en ≈ 4 s, cuatro pruebas de regresión). Un tercer teléfono sin PIN '
    '**no se probó en hardware (no verificado)**; lo cubren las pruebas automáticas y el registro real de la tablet («Escritura rechazada: central no '
    'autenticado»).', alin='j')
d.h2('4.7 Red mínima y geografía')
d.tabla([['Servicio', 'Ancho de banda mínimo', 'Latencia máxima (RTT)', 'Por debajo del mínimo'],
         ['API de CEOSMOS', '5 kbps (11.4 s)', '4 s (12.4 s, dentro del límite de 15 s)', 'Aviso de tiempo agotado; las sesiones quedan pendientes y se reenvían sin duplicarse'],
         ['Firestore', '5 kbps (9.8 s)', 'entre 2 s (funciona) y 4 s (falla)', 'Caché local y sincronización al volver la red'],
         ['Firebase Auth', '5 kbps (10.6 s)', 'entre 2 s y 4 s', 'Mensaje de error del inicio de sesión']],
        [3.0, 3.4, 4.4, 6.2], 'Red mínima por servicio (medido contra producción, 22/11)')
d.p('En EDGE/2G (50 kbps y 400 ms) la API responde en 2.5 s y con 20 % de pérdida en menos de 5 s.', alin='j')
d.tabla([['Continente', 'Ciudad', 'API /health', 'Firestore', 'Tipo'],
         ['Norteamérica', 'Los Ángeles, Búfalo', '200 · 137–258 ms', '403 esperado · 304 ms', 'medido'],
         ['Sudamérica', 'São Paulo, Campinas', '200 · 337–379 ms', '403 · 973 ms', 'medido'],
         ['Europa', 'Madrid, Logroño, Helsinki', '200 · 373–400 ms (Helsinki 396)', '403 · 783 ms', 'medido'],
         ['Asia', 'Singapur, Tokio', '200 · 572–697 ms', '403 · 238 ms', 'medido'],
         ['África', 'Lagos, Johannesburgo', '200 · 652–763 ms', '403 · 2 068 ms', 'medido'],
         ['Oceanía', 'Sídney', '200 · 561–566 ms', '403 · 438 ms', 'medido'],
         ['Redes solo IPv6', '—', 'La API solo publica IPv4; Android traduciría con 464XLAT', '—', 'inferido (no verificado)']],
        [2.6, 3.6, 5.0, 3.4, 2.4], 'Respuesta por continente (sondas públicas, 22/11)', tam=9)
d.h2('4.8 Fallas encontradas y cómo se corrigieron')
d.tabla([['Falla', 'Corrección', 'Prueba de regresión'],
         ['Token con HS512 u otra forma → error 500', 'Solo HS256 y forma validada → 401', 'Jest y Red Box'],
         ['CORS con origen ajeno → 500 (también en producción)', 'Sin cabeceras CORS y sin 500', 'Red Box y producción'],
         ['JSON anidado sin sesión → 500 (también en producción)', '400 o rechazo previo, sin 500', 'Jest y producción'],
         ['Sin Content-Security-Policy', 'CSP default-src none', 'Red Box y producción'],
         ['Medios aceptaban enlaces javascript:', 'Solo https y longitudes acotadas', 'Jest y Red Box'],
         ['El login revelaba si la cuenta existe', 'Mensaje genérico', 'Jest y producción'],
         ['Certificado no confiable → error crudo', 'Mensaje claro', 'tls_rechazo_test'],
         ['Desbordes en «Agregar a mi biblioteca»', 'Contenido desplazable', 'biblioteca_dialogo_test'],
         ['Barra lateral cortada en ventanas anchas y bajas', 'Barra desplazable', 'Barrido de 91 tamaños'],
         ['Reloj y TV «Conectado» con lecturas congeladas', 'Latido y reautenticación sin PIN (1.2.1)', '4 pruebas BLE'],
         ['El usuario torpe desinstaló la app real de los equipos', 'Copia aislada con marcador, comprobación del paquete y alarma', 'blindaje_scripts_test'],
         ['Sin red, una sesión terminada se perdía al cerrar la app', 'Modo sin conexión con cola persistente (1.3.0)', 'sin_conexion_test'],
         ['El service worker de Flutter se desregistraba solo', 'sw.js propio (1.3.0)', 'pwa_test y tarea PWA del CI']],
        [6.2, 6.0, 4.8], 'Fallas encontradas y su corrección', tam=9)

# 5
d.h1('5. Riesgos aceptados y límites')
d.p('Lo que no se pudo probar se marca **no verificado**; los riesgos aceptados se dicen tal cual.', alin='j')
d.tabla([['Riesgo o límite', 'Estado', 'Mitigación'],
         ['Bluetooth: reto + HMAC (el PIN nunca viaja), pero la carga útil no va cifrada', 'riesgo aceptado', 'Solo viajan pulso, pasos y estado de la sesión a pocos metros'],
         ['SQLite y almacenamiento local sin cifrar', 'riesgo aceptado', 'No guardan credenciales; el token está en el Keystore'],
         ['APK firmado con la llave de depuración', 'riesgo aceptado', 'Una llave propia exige desinstalar y registrar su SHA-1 en Firebase'],
         ['Limitador de peticiones en memoria por instancia', 'riesgo aceptado', 'Mejora futura con Redis'],
         ['Perfil público guardado en el equipo para el modo sin conexión', 'riesgo aceptado', 'Sin contraseña ni token; se borra al cerrar sesión o si el servidor revoca el token'],
         ['Pulso y pasos del Reloj simulados', 'límite', 'La tablet no tiene sensor; formato y flujo de un reloj real; un wearable TCP puede mandar lecturas reales'],
         ['Al abrir CEOSMOS hay que pulsar «Conectar» para el Reloj y la TV', 'límite', 'No pide el PIN; las caídas en uso se reconectan solas'],
         ['APK 1.3.0 en los equipos', 'en curso', 'Los equipos tienen la 1.2.1; la 1.3.0 pasó el CI'],
         ['Web Bluetooth de la PWA con el Reloj y la TV reales', 'no verificado en hardware', 'El selector se abre en Chromium'],
         ['PWA instalada en el teléfono', 'no verificado', 'Instalación verificada en escritorio (Chromium)'],
         ['Funciones de Soporte (Firebase) dentro de la PWA', 'no verificado', 'Se usan desde la app Android'],
         ['PWA en un dominio propio', 'pendiente de decidir', 'Requiere agregar el origen a CORS; la demostración usa localhost:4200'],
         ['Regla abierta de presencia en el proyecto de Firebase ajeno', 'pendiente del dueño', 'CEOSMOS no la usa; su propia presencia exige sesión (403)'],
         ['Registro con código por correo en producción (F-14)', 'no verificado', 'Requiere acceso al correo; cubierto con la API simulada'],
         ['Segunda cuenta de usuario en Soporte (con 1.2.1)', 'no verificado', 'Mismo rol que usuario1, que sí se probó'],
         ['Tercer teléfono sin PIN contra el Reloj y la TV', 'no verificado en hardware', 'Pruebas automáticas y registro real de escritura rechazada'],
         ['TalkBack de punta a punta con usuarios reales', 'no verificado', 'Pruebas automáticas de accesibilidad'],
         ['Android 11 o anterior', 'no verificado', 'Permiso de ubicación declarado'],
         ['Redes solo IPv6', 'no verificado', 'Android traduce IPv4 con 464XLAT (inferido)']],
        [7.0, 3.2, 6.8], 'Riesgos aceptados y límites', tam=9)
d.p('El 22/11 una prueba de usuario torpe desinstaló la app real del S24 y de la tablet porque su aislamiento no se aplicó: se perdieron los datos '
    'locales de los equipos (no los de la nube). Se encontró la causa, el script ahora comprueba el paquete antes de correr y se detiene si la app '
    'real se reinstala, y desde entonces cada versión se instala encima conservando la sesión (ver Seguimiento §3.3).', alin='j')

d.h1('6. Conclusión', salto=False)
d.p('Las prácticas del curso dejaron de ser ejercicios aislados y quedaron como funciones de CEOSMOS, cada una con su menú, su rol y su '
    'almacenamiento propio. La calidad se sostiene con 344 pruebas Flutter, 79 de la API y 42 de Kotlin, integración continua en verde, una API '
    'atacada y corregida en producción y pruebas en los equipos reales. Lo pendiente (APK 1.3.0 en los equipos, Web Bluetooth en hardware) y los '
    'riesgos aceptados quedan dichos en la sección 5.', alin='j')

salida = os.path.join(R, 'Reporte de avances - CEOSMOS revicion.docx')
d.guardar(salida)
print(salida)
