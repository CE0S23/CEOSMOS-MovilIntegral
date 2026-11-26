# -*- coding: utf-8 -*-
"""Genera «Reporte final - CEOSMOS Movil Integral.docx»: documento único de entrega, ordenado por la rúbrica (A1–F2).
Une el Documento de seguimiento, el Reporte de avances, la Matriz de cumplimiento y el reporte de las prácticas 13 y 14.
Cifras: evidencias/documentacion/cifras.md. Uso: python tool/documentacion/gen_reporte_final.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from docgen import Doc, REPO  # noqa: E402

R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
E = lambda *p: os.path.join(R, 'evidencias', *p)  # noqa: E731
M = lambda n: E('manual', n + '.png')  # noqa: E731
CI_13 = REPO + '/actions/runs/45686893198'
CI_DOC = REPO + '/actions/runs/45689765691'
CI_V4 = REPO + '/actions/runs/45099965435'
CI_P13 = REPO + '/actions/runs/44438169735'

d = Doc(os.path.join(R, 'Manual de usuario - CEOSMOS.docx'), 'Reporte final del proyecto')
d.margenes()
d.propiedades('Reporte final - CEOSMOS Móvil Integral',
              'Seguimiento, diseño, PWA, dispositivos inteligentes, seguridad, calidad y demostración de CEOSMOS Móvil Integral 1.3.0',
              'CEOSMOS; reporte final; seguimiento; arquitectura; PWA; BLE; seguridad; pruebas; rúbrica')
d.encabezado_pie('Reporte final · versión 1.3.0')

d.portada(E('documentacion', 'logo_portada.png'), 'Reporte final del proyecto',
          'Seguimiento, diseño, desarrollo PWA, dispositivos inteligentes, seguridad y calidad',
          ['Versión de la app: 1.3.0 · Versión del documento: 4.0', 'Fecha: 25 de noviembre de 2026'],
          ['César Osvaldo Ramírez Pérez', 'Matrícula 2023371167 · Grupo IDGS16',
           'Profesor: M.C.C. Emmanuel Martínez Hernández', 'Repositorio: github.com/CE0S23/CEOSMOS-MovilIntegral'])

d.h1('Control de versiones')
d.tabla([['Versión', 'Fecha', 'Cambios'],
         ['1.0', '18/11/2026', 'Reporte de avances: prácticas del curso aplicadas en CEOSMOS.'],
         ['1.1', '19–21/11/2026', 'Soporte con roles; prácticas reescritas como funciones de la app; calidad y pruebas.'],
         ['2.0', '22/11/2026', 'Blindaje para la entrega y versión 1.2.1.'],
         ['3.0', '24–25/11/2026', 'Revisión contra la rúbrica: planteamiento, seguimiento, decisiones, arquitectura, PWA, dispositivos; versión 1.3.0.'],
         ['4.0', '25/11/2026', 'Documento único de entrega: integra el Documento de seguimiento, el Reporte de avances, la Matriz de cumplimiento '
                               'y el reporte de automatización de pruebas, ordenado según los criterios A1–F2 de la rúbrica.']],
        [1.6, 2.6, 12.8], 'Control de versiones del documento')
d.p('Todas las cifras salen de una sola fuente, `evidencias/documentacion/cifras.md` (corte del 25/11/2026). Cada afirmación remite a un '
    'archivo del repositorio, a un commit o a una corrida de integración continua.', alin='j')
d.indice()
d.lista_figuras()
d.lista_tablas()

# ======================= Resumen ejecutivo =======================
d.h1('Resumen ejecutivo')
d.p('**CEOSMOS Móvil Integral** unifica dos proyectos de cuatrimestres anteriores (CEOSMOS WEB y CEOSMOS para Dispositivos Inteligentes) en '
    'una sola aplicación Flutter que se distribuye como **app Android** y como **aplicación web progresiva (PWA) instalable**. Ambas usan la misma '
    'API NestJS y la misma base PostgreSQL, se comunican por **Bluetooth LE autenticado** con dos dispositivos inteligentes (Reloj y TV) y siguen '
    'funcionando **sin conexión** sin perder sesiones.', alin='j')
d.tabla([['Indicador', 'Valor al 25/11/2026'],
         ['Versión', '1.3.0 (commit `fc37eed`), repositorio público'],
         ['Pruebas automatizadas', '344/344 Flutter · 79/79 API · 14/14 por cada app Kotlin (Reloj, TV, Companion)'],
         ['Cobertura de líneas', '56.0 % de toda la app; núcleo (`core`, `data`, `domain`) 84.8 %'],
         ['Integración continua', '30 corridas en GitHub Actions; la de la 1.3.0 y la de la documentación final, en verde'],
         ['Seguridad', 'Red Box 13/13 y 37/37 en local, 27/27 en producción sin credenciales; BLE con reto + HMAC-SHA256'],
         ['Robustez', '12 100 acciones al azar sin cierres ni ANR; 91 tamaños de ventana sin desbordes; red mínima de 5 kbps'],
         ['Hardware', 'Galaxy S24 (central) y Galaxy Tab S9 (Reloj y TV) probados de punta a punta']],
        [4.0, 13.0], 'Indicadores principales')
d.h2('Cumplimiento por criterio de la rúbrica')
d.p('Cada criterio tiene su capítulo; la trazabilidad completa con rutas de evidencia está en el Anexo A.', alin='j')
d.tabla([['Criterio', 'Capítulo', 'Estado'],
         ['A1. Planteamiento del problema y justificación', '1', 'Cumple'],
         ['A2. Seguimiento de avances durante el cuatrimestre', '2', 'Cumple'],
         ['A3. Evidencia de decisiones y cambios', '3', 'Cumple'],
         ['B1. Diseño de arquitectura', '4', 'Cumple'],
         ['B2. Diseño de interfaz y experiencia de usuario', '5', 'Cumple'],
         ['C1. Funcionamiento de la aplicación', '6.1', 'Cumple'],
         ['C2. Manifiesto y configuración PWA', '6.2', 'Cumple'],
         ['C3. Service Worker y funcionamiento offline', '6.3', 'Cumple'],
         ['C4. Diseño responsivo e instalabilidad', '6.4', 'Cumple'],
         ['D1. Comunicación con el dispositivo inteligente', '7.1', 'Cumple en Android; en la PWA, ver §7.1'],
         ['D2. Uso de capacidades o sensores', '7.2', 'Cumple con un límite declarado: pulso y pasos simulados'],
         ['D3. Intercambio y procesamiento de información', '7.3', 'Cumple'],
         ['D4. Manejo de permisos y compatibilidad', '7.4', 'Cumple'],
         ['E1. Protección de información y autenticación', '8.1', 'Cumple'],
         ['E2. Pruebas y validación', '8.2', 'Cumple'],
         ['E3. Rendimiento, estabilidad y recuperación', '8.3', 'Cumple'],
         ['F1. Demostración funcional', '9', 'Guion y entorno preparados'],
         ['F2. Dominio técnico y respuestas', '9.4 y Anexo C', 'Fundamentos documentados']],
        [8.2, 2.6, 6.2], 'Cumplimiento de la rúbrica por capítulo', tam=9)

# ======================= 1. A1 =======================
d.h1('1. Planteamiento del problema y justificación')
d.h2('1.1 Contexto')
d.p('El ecosistema CEOSMOS nace en cuatrimestres previos como dos desarrollos independientes con la misma premisa: ayudar a la persona '
    'a entrar en un estado de concentración, relajación o inspiración («focus mode») para estudiar o trabajar mejor.', alin='j')
d.viñetas([
    '**CEOSMOS WEB** (Desarrollo Web Integral): PWA en Angular 18 con API NestJS 11 + Prisma 5 sobre PostgreSQL en Neon; correo y contraseña, '
    'passkeys WebAuthn, verificación por correo (Resend), roles, bitácora de auditoría y bloqueo de cuenta.',
    '**CEOSMOS para Dispositivos Inteligentes** (Desarrollo de Aplicaciones Inteligentes): app móvil Flutter como hub, un wearable simulado y una '
    'PWA para TV, sincronizados con Firebase. El enlace BLE con el wearable fue inestable en el hardware de entonces y se pasó a TCP/IP.',
])
d.p('Ambos proyectos funcionaban, pero como clientes aislados: sin base de datos, cuenta ni lógica compartida.', alin='j')
d.h2('1.2 Problema')
d.p('Quien usa CEOSMOS depende de dos productos que no se comunican: cada uno tiene su cuenta, su base de datos y su historial; las '
    'lecturas del reloj no llegan al historial de la web y lo configurado en un lado no existe en el otro. No hay un cliente único que, '
    'desde el teléfono o desde el navegador, use la misma cuenta y la misma base, controle los dispositivos inteligentes (reloj y TV) y siga '
    'funcionando cuando la red falla (transporte, escuela u oficinas con Wi-Fi inestable).', alin='j')
d.p('**Consecuencias:** datos duplicados o perdidos, doble mantenimiento del código, experiencias distintas por plataforma y sesiones de enfoque '
    'que se pierden si al terminarlas no hay conexión.', alin='j')
d.p('**Pregunta guía:** ¿cómo unificar ambos proyectos en una sola aplicación, instalable en Android y desde la web, con una sola fuente de verdad, '
    'que se comunique de forma segura con los dispositivos inteligentes y que no pierda información sin conexión?', alin='j')
d.h2('1.3 Usuarios y roles')
d.tabla([['Rol', 'Quién es', 'Qué puede hacer', 'Dónde se controla'],
         ['USER', 'Estudiante o persona que trabaja frente a una pantalla', 'Sesiones de enfoque, Explorar, favoritos, biblioteca, Reloj y TV, Soporte, Perfil', 'API (JWT con rol)'],
         ['ADMIN', 'Administrador de la plataforma', 'Todo lo anterior y Perfil › Administración (usuarios, roles, estado, bitácora)', 'API (JWT con rol); la sección solo se muestra a ADMIN'],
         ['Usuario de Soporte', 'Cualquier persona que pide ayuda', 'Crear tickets con turno, chatear y ver su historial', 'Reglas de Firestore por documento de rol'],
         ['Agente', 'Personal de soporte', 'Atender los tickets asignados y pasarlos al administrador', 'Reglas de Firestore'],
         ['Administrador de Soporte', 'Responsable de la mesa de ayuda', 'Ver todo, reasignar, cambiar prioridad, eliminar y limpiar historial', 'Reglas de Firestore']],
        [2.8, 3.8, 6.4, 4.0], 'Usuarios y roles de CEOSMOS')
d.h2('1.4 Justificación')
d.p('Mantener dos plataformas para un mismo ecosistema fragmenta el código, duplica el mantenimiento y obliga a sostener dos bases de datos, dos '
    'esquemas de autenticación y dos experiencias que responden a la misma necesidad. Unificarlas en un solo código Flutter, que se publica como app '
    'Android y como PWA, deja una sola fuente de verdad (la API NestJS + PostgreSQL de CEOSMOS WEB) y convierte al teléfono en el hub que habla con '
    'los periféricos (Reloj y TV). El resultado es un producto coherente, más fácil de mantener, probar y escalar.', alin='j')
d.tabla([['Necesidad', 'Cómo la resuelve CEOSMOS Móvil Integral'],
         ['Una sola cuenta e historial', 'La app y la PWA usan la misma API y la misma base PostgreSQL que CEOSMOS WEB'],
         ['Un solo código que mantener', 'Flutter compila la app Android y la PWA desde `lib/`; lo propio de cada plataforma va detrás de interfaces'],
         ['Usar el reloj y la TV durante la sesión', 'Bluetooth LE autenticado: pulso en vivo, botón del Reloj y D-pad de la TV controlan la sesión'],
         ['Redes inestables', 'Modo sin conexión con cola persistente y envío idempotente al volver la red'],
         ['Confianza en los datos', 'JWT, almacén seguro, reto + HMAC en BLE, pruebas de ataque y CI en cada cambio']],
        [5.2, 11.8], 'Necesidades y respuesta de la solución')
d.h2('1.5 Objetivo general')
d.p('Desarrollar CEOSMOS Móvil Integral: una aplicación Flutter que se distribuye como app Android y como aplicación web progresiva (PWA) '
    'instalable, conectada a la API y a la base de datos de CEOSMOS WEB y a los dispositivos inteligentes Reloj y TV por Bluetooth LE, segura, '
    'probada y capaz de funcionar sin conexión.', alin='j')
d.h2('1.6 Objetivos específicos y resultado')
d.tabla([['Objetivo específico', 'Resultado', 'Dónde se demuestra'],
         ['1. Unificar acceso, usuarios, sesiones de enfoque y dispositivos en la API NestJS + PostgreSQL (Neon) con JWT y roles.', 'Cumplido', '§4, §8.1'],
         ['2. Comunicar la app con el Reloj y la TV por BLE (GATT) con reto + HMAC, y con un wearable por TCP/IP.', 'Cumplido en la app Android, probado en hardware. La PWA incluye Web Bluetooth (ver §7.1)', '§4.5, §7.1'],
         ['3. Usar datos y controles de los dispositivos (pulso, pasos, botón, D-pad) para conducir la sesión y guardarla en el historial.', 'Cumplido; el pulso y los pasos los genera la app Reloj porque la tablet no tiene sensor (§7.2)', '§7.2, §7.3'],
         ['4. Publicar la app como PWA instalable con manifiesto, service worker propio y modo sin conexión.', 'Cumplido: 0 errores de instalabilidad, abre y guarda sesiones sin red', '§6'],
         ['5. Diseño responsivo y accesible (240 a 1600 dp, contraste AA, áreas de 48 dp, fuente al 200 %).', 'Cumplido', '§5, §6.4'],
         ['6. Validar con pruebas automatizadas, integración continua, pruebas de seguridad y pruebas en equipos reales.', 'Cumplido (344 pruebas Flutter, CI en verde, Red Box, S24 + Tab S9)', '§8'],
         ['7. Migrar las passkeys WebAuthn al móvil (plan del primer parcial).', 'No cumplido: Android exige publicar `assetlinks.json` en un dominio propio verificado, que el proyecto no tiene; se mantuvo correo y contraseña con JWT', '§2.3, §10.2']],
        [7.4, 6.2, 3.4], 'Objetivos específicos y resultado')
d.h2('1.7 Alcance')
d.tabla([['Incluye', 'Fuera del alcance'],
         ['App Android (APK) y PWA desde una sola base de código Flutter', 'Publicación en Google Play'],
         ['Acceso, registro con código por correo, recuperación de contraseña, roles USER y ADMIN', 'Passkeys en móvil (requiere dominio propio)'],
         ['Sesiones de enfoque, Explorar, favoritos, biblioteca propia e historial', 'Sensor de pulso real (la Tab S9 no tiene)'],
         ['Reloj y TV como apps Kotlin con BLE; wearable por TCP/IP', 'Cifrado de la carga útil BLE (bonding LE Secure Connections)'],
         ['Funciones de Soporte, mensajería, seguridad de la cuenta, directorio y citas, cada una con su almacenamiento', 'Funciones de Soporte dentro de la PWA (se usan en la app Android)'],
         ['Modo sin conexión, pruebas automatizadas, CI y blindaje de seguridad', 'Firma del APK con llave de publicación (se usa la llave de depuración, §3.1)']],
        [8.5, 8.5], 'Alcance del proyecto')
d.h2('1.8 Restricciones')
d.viñetas([
    'Hardware disponible: un Galaxy S24 (central) y una Galaxy Tab S9 que ejecuta a la vez el Reloj y la TV. Sin reloj físico con sensor.',
    'Un solo desarrollador y un cuatrimestre.',
    'Uno de los proyectos de Firebase heredados por Soporte pertenece a otra cuenta, por lo que su configuración no se administra desde este proyecto.',
    'Web Bluetooth existe solo en Chrome y Edge; Firefox y Safari muestran un aviso en la tarjeta de Equipos.',
    'Las pruebas que exigen iniciar sesión no se ejecutan contra producción (no se escriben contraseñas reales allí); se cubren en local con el mismo código desplegado.',
])
d.h2('1.9 Metodología')
d.p('Desarrollo iterativo por entregas cortas, cada una cerrada con pruebas y evidencia:', alin='j')
d.numerada([
    '**Planear** en la memoria del proyecto (`memoria/`, notas en Obsidian): pendientes, decisiones y bitácora fechada.',
    '**Construir** en el repositorio público con commits descriptivos y etiquetas de entrega (`entrega-v1` a `entrega-v4`).',
    '**Probar** en tres niveles: pruebas automatizadas (unitarias, widgets, integración, caja negra y blanca), integración continua en cada push y recorridos en los equipos reales.',
    '**Atacar y estresar** (Red Box, usuario torpe, red degradada) antes de cada entrega.',
    '**Documentar** con capturas reales y cifras tomadas de una sola fuente (`evidencias/documentacion/cifras.md`).',
])

# ======================= 2. A2 =======================
d.h1('2. Seguimiento de avances durante el cuatrimestre')
d.p('Cronología tomada del historial de git del repositorio público (del 11/11 al 25/11/2026) y, para la primera revisión, de la bitácora '
    '(`memoria/10 - Bitácora.md`), porque es anterior al repositorio.', alin='j')
d.h2('2.1 Cronología')
d.tabla([['Fecha', 'Avance', 'Commit / evidencia', 'Estado'],
         ['08/10', 'Primera revisión: app Flutter local sin base de datos, catálogo y sesiones; 11 pruebas.', 'Bitácora (anterior al repositorio)', 'Cumplido'],
         ['11/11', 'Línea base; plan de integración e inventario de prácticas; cada práctica con su propia BD; app conectada a la API real (NestJS + PostgreSQL); registro con correo; pruebas en el S24; caja blanca.', '7417fdf … aa5f34e, 4d68d88, 0cd2ce7', 'Cumplido'],
         ['18/11', 'Optimización, estrés y resiliencia (reintentos, idempotencia); central BLE y apps Reloj y TV probadas en S24 + Tab S9; Red Box de la API; memoria reestructurada; pruebas automatizadas, CI y repositorio público (PR #1).', '3860019, 8105d26, 1a8f98c, 7ed7df2, 546bf30, 77dd4fd', 'Cumplido'],
         ['19/11', 'Evidencias de CI; Soporte con 4 roles en dos equipos (TC01–TC08 aprobados).', '829919a, ec83dbf', 'Cumplido'],
         ['21/11', 'Sistema de diseño (paleta AA, claro y oscuro); prácticas convertidas en funciones de CEOSMOS; blindaje etapa 3 (contingencia, usuario torpe en la app); `entrega-v1`.', '2930619, 6bdfd5f, c431e0e, 7c6715e', 'Cumplido'],
         ['22/11', 'Blindaje: Red Box ampliado, API corregida en producción, 91 tamaños, red mínima, reconexión BLE con latido; 1.2.1 instalada en los dos equipos; `entrega-v2` a `entrega-v4`.', 'ce1d0d1, be6b0ba, 2167f30, c265ec7', 'Cumplido'],
         ['24/11', 'Revisión contra la rúbrica: PWA con service worker propio, modo sin conexión, Web Bluetooth, diagramas, cabecera de tabletas.', 'Incluido en fc37eed', 'Cumplido'],
         ['25/11', 'Versión 1.3.0 y documentación final.', 'fc37eed, 31defc1; [CI en verde](' + CI_13 + ')', 'Cumplido']],
        [1.5, 8.7, 4.3, 2.5], 'Cronología del proyecto (fechas de git)', tam=9)
d.h2('2.2 Hitos y versiones')
d.tabla([['Hito', 'Fecha', 'Commit', 'Contenido'],
         ['entrega-v1', '21/11', '7c6715e', 'Blindaje etapa 3: contingencia y usuario torpe dentro de la app'],
         ['entrega-v2', '22/11', 'ce1d0d1', 'Blindaje etapas 1 y 2: robustez, accesibilidad, tamaños, red, geografía y Red Box ampliado'],
         ['entrega-v3', '22/11', 'be6b0ba', 'Aislamiento del usuario torpe, verificación de producción y dependencias'],
         ['entrega-v4', '22/11', '2167f30', 'App 1.2.1: API en producción, reconexión BLE con latido; instalada en el S24 y la Tab S9'],
         ['1.3.0', '25/11', 'fc37eed', 'PWA con service worker propio, modo sin conexión y Web Bluetooth; CI en verde']],
        [2.6, 1.6, 2.0, 10.8], 'Etiquetas de entrega y versiones')
d.h2('2.3 Plan por parcial contra lo entregado')
d.tabla([['Parcial', 'Compromiso del plan', 'Resultado', 'Estado'],
         ['1.°', 'Proyecto Flutter unificado y UI de feeds visuales y auditivos', 'Una base de código para Android y web', 'Cumplido'],
         ['1.°', 'Conexión con la API REST y migración del acceso (correo y contraseña + passkeys)', 'Correo y contraseña, JWT y verificación por correo. Passkeys no: Android exige `assetlinks.json` en un dominio propio', 'Parcial'],
         ['1.°', 'Modelos unificados en un esquema relacional con JSONB', '`metadata` de sesiones y `configuration` de dispositivos en JSONB', 'Cumplido'],
         ['2.°', 'Wearable con TCP/IP primario y BLE de respaldo', 'Cambió: BLE es el canal del Reloj y la TV; TCP/IP queda para un wearable en Wi-Fi (§3.2)', 'Cumplido con cambio'],
         ['2.°', 'Métricas en vivo y sincronizadas con el historial', 'Pulso y pasos en vivo y resumen en `metadata.wearable` (lecturas generadas por la app Reloj, §7.2)', 'Cumplido'],
         ['3.°', 'PostgreSQL en producción, audio en segundo plano, carga diferida y caché LRU de 150–200 MB', 'Cumplido; en la PWA la caché es la del service worker (60 imágenes como máximo)', 'Cumplido'],
         ['3.°', 'Profiling y pruebas de integración de punta a punta', 'Estrés, profiling, prueba de integración crítica; 344 pruebas automatizadas', 'Cumplido'],
         ['Prácticas', 'Laboratorios de consumo de API, IoT, caché y profiling planteados en la propuesta', 'Integrados como funciones de la app y como pruebas (§2.4)', 'Cumplido']],
        [1.8, 5.2, 7.6, 2.4], 'Plan por parcial contra lo entregado', tam=9)

d.h2('2.4 Prácticas del curso integradas como funciones')
d.p('Desde el 21/11 ninguna práctica vive en una ventana aparte: cada una es una función con nombre propio, en el menú que le corresponde, '
    'con su rol y su propio almacenamiento. Ningún texto visible de la app dice «Práctica», «P#» ni «Examen» (lo verifica una prueba automática).', alin='j')
d.tabla([['Función', 'Práctica original (tema)', 'Menú', 'Rol', 'Datos propios'],
         ['Tickets y chat interno', 'Asignación de roles e interacción de situaciones', 'Soporte', 'Usuario, agente, administrador', 'Firebase propio (Auth + Firestore) con reglas por rol'],
         ['Reportes compartidos (Flutter y Android)', 'Base de datos en la nube con Firestore', 'Soporte › Reportes e incidencias', 'Cualquier usuario', 'Firebase propio (Firestore), compartido por ambas versiones'],
         ['Incidencias en tiempo real', 'Conexiones y pruebas de BD entre dispositivos', 'Soporte › Reportes e incidencias', 'Cualquier usuario, dos equipos', 'Firebase propio con caché local'],
         ['Mis incidencias y acceso', 'Seguridad, autenticación y control de acceso', 'Soporte › Reportes e incidencias', 'Cada cuenta ve lo propio o asignado', 'Firebase propio con cuentas y reglas'],
         ['Incidencias sin conexión', 'Examen práctico de incidencias de soporte', 'Soporte', 'Cualquier usuario', 'SharedPreferences propio'],
         ['Mensajería entre equipos', 'Interacción entre dispositivos', 'Equipos', 'Cualquier usuario', 'Sin BD (memoria)'],
         ['Seguridad de la cuenta', 'Código seguro', 'Perfil › Cuenta y herramientas', 'Cualquier usuario', 'Sin BD (validación nativa)'],
         ['Directorio de alumnos', 'Consumo de servicio web y almacenamiento estructurado', 'Perfil › Cuenta y herramientas', 'Cualquier usuario', 'SQLite (Floor) v2'],
         ['Citas de bienestar', 'Evaluación de servicios seguros (MediConnect)', 'Perfil › Cuenta y herramientas', 'Cualquier usuario (con el servidor de citas)', 'API HTTPS propia + almacén seguro propio'],
         ['Aviso «Sin conexión» y sincronización', 'Optimización, estrés y resiliencia', 'Toda la app', '—', 'Cola persistente de sesiones'],
         ['Calidad y pruebas (sin pantalla)', 'Caja negra, caja blanca y automatización con CI', '—', '—', '`test/`, `integration_test/`, CI']],
        [3.3, 3.8, 3.2, 3.0, 3.7], 'Prácticas integradas como funciones', tam=8.5)
funcs = [
    ('Tickets y chat interno',
     'El usuario crea tickets con turno y consulta su historial; el agente atiende los asignados y puede pasarlos al administrador; el administrador '
     've la gestión completa (asignados, todos los tickets y dispositivos conectados), reasigna, cambia la prioridad, elimina y limpia el historial. El '
     'rol lo fija un documento en Firestore que las reglas del servidor verifican. El chat muestra emisor, hora y contador por dispositivo, impide '
     'mensajes vacíos y acepta adjuntos de hasta 300 KB. **Cómo se probó:** con las cuatro cuentas entre el teléfono y la tablet, matriz '
     'TC01–TC08 aprobada (alta, campos vacíos, identificador repetido, actualización, eliminación, documento inexistente, pérdida de conexión y '
     'persistencia); con la 1.2.1 se repitieron alta, mensajes en tiempo real (2 s), adjunto de 203 KB aceptado y de 434 KB rechazado, asignación (3 s) y presencia.'),
    ('Reportes compartidos',
     'Cualquier usuario registra reportes, los consulta desde el servidor, actualiza su prioridad con transacciones y los elimina. La versión Flutter y '
     'la versión Android (Kotlin) operan la misma colección en un proyecto de Firebase separado del de CEOSMOS.'),
    ('Incidencias en tiempo real',
     'Dos equipos comparten la misma base en la nube: lo que uno escribe aparece en el otro al instante, la modificación simultánea se detecta campo '
     'por campo con aviso de conflicto, hay bitácora de eventos y las escrituras sin conexión se sincronizan al volver la red.'),
    ('Mis incidencias y acceso',
     'Cada persona entra con su cuenta; los registros guardan el UID del propietario y las reglas solo permiten ver y editar lo propio o lo asignado y '
     'rechazan operar sin sesión. En CEOSMOS el control de acceso general lo aplica la API (JWT, roles USER y ADMIN y datos filtrados por usuario).'),
    ('Incidencias sin conexión',
     'Registrar, consultar y eliminar fallas del equipo en el propio teléfono, aunque no haya red, en un almacenamiento local independiente.'),
    ('Mensajería entre equipos',
     'Dos teléfonos de la misma red Wi-Fi conversan por TCP (o en modo de simulación) con emisor, hora, contador por dispositivo, limpieza de '
     'historial, aviso visual y rechazo de mensajes vacíos.'),
    ('Seguridad de la cuenta',
     'Valida usuario y contraseña en la capa nativa (Kotlin) por un canal de plataforma: campos obligatorios, límites de longitud, contraseña oculta, '
     'usuario con espacios rechazado, mínimo de 8 caracteres, errores genéricos y sin credenciales en Logcat.'),
    ('Directorio de alumnos',
     'Alta, consulta, edición y baja de alumnos en SQLite mediante Floor, con el campo correo agregado por una migración a la versión 2, y consulta '
     'asíncrona a un servicio web con estados de carga y error.'),
    ('Citas de bienestar',
     'Inicia sesión con token, consulta y registra citas contra su propia API HTTPS con certificado fijado y peticiones idempotentes, y guarda sus '
     'credenciales en un almacén seguro separado.'),
]
for t, txt in funcs:
    d.h3(t)
    d.p(txt, alin='j')
d.figuras_lado([M('m_soporte'), M('m_chat_admin'), M('m_herramientas')],
               'Soporte, chat de un ticket visto por el administrador y Perfil › Cuenta y herramientas', 8.5,
               'Capturas de la pestaña Soporte, del chat de un ticket y de Cuenta y herramientas')

d.h2('2.5 Indicadores de avance')
d.tabla([['Indicador', 'Valor vigente (25/11)', 'Evolución'],
         ['Pruebas Flutter', '344/344; análisis estático sin avisos', '11 (08/10) → 215 (18/11) → 331 (22/11) → 344 (24/11)'],
         ['Pruebas de la API (Jest)', '79/79', 'Estable desde el 22/11'],
         ['Pruebas Kotlin', 'Reloj, TV y Companion: 14/14 cada una', '5 nuevas en las prácticas de automatización'],
         ['Cobertura de líneas', '56.0 % de toda la app; núcleo 84.8 %', '49.5 % (18/11) → 52.9 % / 78.9 % (22/11) → 56.0 % / 84.8 %'],
         ['Integración continua', '30 corridas: 28 en verde, 1 fallida corregida en la siguiente, 1 cancelada por un push posterior', '[Corrida de la 1.3.0](' + CI_13 + ')'],
         ['Red Box', '13/13 original, 37/37 ampliado (local), 27/27 en producción', '27/37 antes de corregir 6 fallos'],
         ['Usuario torpe', '12 100 acciones sin cierres ni ANR', '4 desbordes encontrados y corregidos'],
         ['Tamaños de ventana', '91 sin desbordes', 'Barra lateral corregida el 22/11']],
        [3.6, 6.4, 7.0], 'Indicadores de calidad')

# ======================= 3. A3 =======================
d.h1('3. Decisiones y cambios')
d.p('Cada decisión está registrada con su motivo en `memoria/09 - Decisiones técnicas.md` y, cuando cambió código, en el commit indicado.', alin='j')
d.h2('3.1 Registro de decisiones')
dec = [['Fecha', 'Decisión', 'Alternativas', 'Motivo', 'Efecto', 'Evidencia'],
       ['11/11', 'La BD de CEOSMOS es la API NestJS + PostgreSQL (Neon)', 'Firestore, como el proyecto anterior', 'Es el backend real de CEOSMOS WEB: una sola fuente de verdad', 'Firestore queda solo para Soporte', 'aa5f34e'],
       ['11/11', 'Cada función heredada con su propio almacenamiento', 'Compartir la BD de CEOSMOS', 'Aislar datos y sesiones de cada práctica', 'Una BD o proyecto por función (§4.6)', '8410837'],
       ['11/11', 'CSRF solo para sesiones por cookie; 120 pet./min (acceso 10/min)', 'CSRF para todos los clientes', 'Un cliente con token Bearer no es atacable por CSRF; la app hace ~6 peticiones al abrir', 'App y web comparten la API', 'memoria/09'],
       ['11–18/11', 'Reintentos con espera exponencial y `clientId` idempotente', 'Reintento simple', 'Al reintentar sin respuesta se duplicaban sesiones', 'Cero duplicados en estrés', '3860019'],
       ['18/11', '**Cambio de plan:** BLE como canal principal del Reloj y la TV', 'TCP/IP primario (plan original)', 'Con periféricos nativos en Kotlin el enlace fue estable en hardware', 'TCP/IP queda para un wearable en Wi-Fi', '8105d26, 1a8f98c'],
       ['18/11', '**Cambio de plan:** Reloj y TV como apps Android nativas, no PWA', 'PWA para la TV (proyecto anterior)', 'Web Bluetooth solo puede ser central; la TV debe ser periférico GATT', 'Las dos conviven en la tablet', '8105d26'],
       ['18/11', 'Autenticación BLE por reto + HMAC-SHA256 con PIN de 6 dígitos', 'Emparejamiento del sistema', 'El PIN nunca viaja por el aire y no hay diálogo del sistema', 'Escrituras sin autenticar rechazadas (GATT 8)', '24ba2eb, 8105d26'],
       ['18/11', 'Guardar la dirección `CE:05:<id>`', 'Guardar la MAC', 'La MAC del periférico rota por privacidad', 'La reconexión encuentra al mismo equipo', 'memoria/06'],
       ['18/11', 'Repositorio propio y público', 'Repositorio de la web (CEOSMOSV2)', 'Historia y despliegue distintos; el profesor lo ve sin invitación', 'github.com/CE0S23/CEOSMOS-MovilIntegral', '546bf30'],
       ['18/11', 'CI sin secretos (servidor HTTP local, BLE simulado, SQLite en memoria)', 'Probar contra producción o Firebase', 'Las pruebas nunca deben tocar producción', 'El CI corre en cada push sin credenciales', '546bf30'],
       ['21/11', 'Sistema de diseño guinda/cian con contraste AA', 'Mantener los estilos sueltos de cada práctica', 'Un producto coherente y accesible', '6 combinaciones corregidas a AA', '2930619'],
       ['21/11', '**Cambio de plan:** las prácticas pasan a ser funciones de CEOSMOS', 'Ventana «Prácticas» con cada práctica aislada', 'Un producto final coherente para el usuario', 'Pestaña Soporte; prueba que impide textos de «práctica»', '6bdfd5f'],
       ['22/11', 'Latido BLE cada 5 s y reautenticación sin PIN', 'Reconexión manual', 'Defecto en hardware: «Conectado» con lecturas congeladas', 'Reconexión en ≈ 4 s', '2167f30'],
       ['22/11', 'Meta del usuario torpe ajustada a 12 100 acciones', '20 000 acciones del plan inicial', 'Las corridas en ambos equipos ya no mostraban fallos nuevos tras la corrección; repetir no aportaba información', 'Cobertura de ambos equipos con una corrida de verificación', 'memoria/13'],
       ['22/11', 'Versiones release apuntan a producción por defecto', 'Exigir la URL al compilar', 'Un release sin URL apuntaba al emulador', 'Prueba de la regla de URL', 'memoria/13'],
       ['22/11', 'Firmar el APK con la llave de depuración', 'Keystore de publicación', 'Con otra firma hay que desinstalar (se pierden datos) y registrar su SHA-1 en Firebase; no se publica en Google Play', 'Instalación encima conservando datos', 'memoria/13'],
       ['24/11', 'Service worker propio (`sw.js`)', 'El de Flutter', 'El de Flutter 3.41 se desregistra solo: sin modo sin conexión', 'La PWA abre sin red', 'fc37eed'],
       ['24/11', 'Modo sin conexión: perfil y pendientes en el equipo; token en almacén seguro', 'Exigir red para abrir', 'Una sesión terminada sin red se perdía al cerrar la app', 'Sesión enviada una sola vez al volver la red', 'fc37eed'],
       ['24/11', 'Servir la PWA en `localhost:4200` para la demostración', 'Dominio propio', 'Contexto seguro (requisito de service worker y Web Bluetooth) y origen ya admitido por CORS en la API de producción', 'Instalable sin cambiar la configuración de producción', 'memoria/14'],
       ['24/11', 'Pulso del Reloj generado por la app Reloj', 'Reloj Wear OS con sensor', 'La tablet no tiene sensor de frecuencia cardiaca y no se contaba con un reloj físico', 'Mismo formato, validación y guardado que un reloj real', 'memoria/09']]
d.tabla(dec, [1.3, 3.5, 2.8, 3.6, 3.2, 2.0], 'Registro de decisiones técnicas', tam=8)
d.h2('3.2 Cambios de plan')
d.viñetas([
    '**De TCP/IP a BLE.** El plan ponía TCP/IP como transporte primario por la inestabilidad del BLE del cuatrimestre anterior. Este cuatrimestre, con el S24 como central y periféricos GATT nativos en Kotlin en la Tab S9, el enlace fue estable; BLE pasó a ser el canal principal y TCP/IP la alternativa.',
    '**Reloj y TV nativos, no PWA.** Web Bluetooth solo puede actuar como central; una TV que anuncia y sirve GATT tiene que ser nativa. Las dos apps conviven en la tablet.',
    '**Rediseño y reubicación de las prácticas.** El 21/11 se aplicó un sistema de diseño único y las prácticas dejaron de vivir en una ventana «Prácticas»: ahora son funciones con nombre propio en Soporte, Equipos y Perfil (§2.4).',
    '**Firestore → API propia.** La base de CEOSMOS es la de la API NestJS + PostgreSQL; Firestore se conserva solo para las funciones de Soporte.',
    '**PWA con service worker propio y modo sin conexión** (24/11), porque el de Flutter 3.41 no daba funcionamiento sin red.',
])
d.h2('3.3 Incidentes y lecciones aprendidas')
d.tabla([['Fecha', 'Incidente', 'Cómo se corrigió', 'Lección'],
         ['18/11', 'La TV reiniciada seguía marcando «Conectado» y rechazaba cada proyección (DEF-BLE-01)', 'Reautenticación al recibir «sin autorización»; prueba de regresión que falla con el código viejo', 'Todo defecto de hardware queda con su prueba automática'],
         ['18/11', 'Un secreto antiguo estaba en el historial de git antes de publicar el repositorio', 'Historial redactado antes de publicar; secretos rotados el 22/11; análisis de secretos sin hallazgos de servidor', 'Revisar el historial antes de hacer público un repositorio'],
         ['21/11', 'Corrida de CI fallida: el análisis estático marcó un aviso en el arnés de capturas de `tool/`', 'Corregido en 0f30c8c; la siguiente corrida pasó', 'Correr `flutter analyze` también tras tocar herramientas'],
         ['22/11', 'Una prueba de estrés («usuario torpe») desinstaló la app real del S24 y de la tablet porque su aislamiento no se aplicó; se perdieron datos locales (no los de la nube)', 'Copia aislada con archivo marcador, comprobación del paquete antes de correr y alarma si la app real se reinstala; desde entonces cada versión se instala encima (be6b0ba)', 'Nunca ejecutar pruebas en un equipo sin confirmar el paquete; probar el aislamiento antes que la prueba'],
         ['22/11', 'Un release compilado sin URL apuntaba al emulador (10.0.2.2)', 'Producción por defecto en release y prueba de la regla', 'Los valores por defecto deben ser los de producción'],
         ['22/11', 'Reloj y TV en «Conectado» con lecturas congeladas tras reiniciar sus apps', 'Latido cada 5 s y reautenticación sin PIN (1.2.1)', 'Un enlace físico vivo no significa sesión viva'],
         ['22/11', 'El Red Box ampliado halló 6 fallos en la API (500 ante CORS ajeno o JSON anidado, sin CSP, enlaces javascript:, login que revelaba cuentas)', 'Corregidos y desplegados a producción; 27/27 allí', 'Atacar también producción, sin credenciales y a baja tasa'],
         ['22/11', 'Un toque automatizado con coordenadas viejas pulsó «Cerrar sesión» en un equipo', 'Volver a leer la pantalla antes de cada toque', 'No reutilizar coordenadas entre pantallas'],
         ['24/11', 'El service worker de Flutter 3.41 se desregistra solo: la PWA no abría sin red', '`web/sw.js` propio con precarga versionada', 'Verificar el modo sin conexión de punta a punta, no solo la instalación']],
        [1.4, 5.0, 5.6, 5.0], 'Incidentes y lecciones aprendidas', tam=8.5)

# ======================= 4. B1 =======================
d.h1('4. Diseño de arquitectura')
d.h2('4.1 Vista general')
d.p('CEOSMOS Móvil Integral es un solo código Flutter (`lib/`) que se compila como app Android y como PWA. Las dos variantes comparten interfaz, '
    'estado, datos y Bluetooth; lo que cambia por plataforma (radio BLE, sockets, caché de imágenes) está detrás de interfaces con importaciones '
    'condicionales, lo que además permite simularlo en las pruebas. Ambas hablan con la misma API NestJS en Vercel y la misma base PostgreSQL; el '
    'Reloj y la TV son periféricos GATT nativos en la tablet.', alin='j')
d.figura(E('diagramas', 'arquitectura.png'), 'Arquitectura de CEOSMOS Móvil Integral (fuente: tool/diagramas/arquitectura.html)', 16.5,
         'Diagrama de arquitectura: un código Flutter compilado como app Android y PWA, API NestJS en Vercel con PostgreSQL en Neon, Firebase para Soporte, y Reloj y TV por Bluetooth LE')
d.h2('4.2 Despliegue')
d.figura(E('diagramas', 'despliegue.png'), 'Despliegue: equipos del usuario, nube de producción y desarrollo (fuente: tool/diagramas/despliegue.html)', 16.5,
         'Diagrama de despliegue con el S24, la PWA en el navegador, la Tab S9 con Reloj y TV, la API en Vercel, Neon, Firebase, Resend, GitHub y GitHub Actions')
d.h2('4.3 Capas')
d.tabla([['Capa', 'Tecnología', 'Responsabilidad'],
         ['Interfaz (`lib/ui`, `lib/core/theme`)', 'Flutter 3.41.9 / Dart 3.11.5, Material 3', 'Pantallas, navegación por pestañas o barra lateral, tema claro y oscuro'],
         ['Estado (`lib/core/app_state.dart`)', 'ChangeNotifier', 'Sesión de acceso, temporizador, reintentos, modo sin conexión y cola de pendientes'],
         ['Datos (`lib/data`)', 'http, flutter_secure_storage, shared_preferences', 'Cliente de la API con JWT y plazo de 15 s, token seguro, copia local para abrir sin red'],
         ['Dispositivos (`lib/core/ble`, wearable)', 'flutter_blue_plus / Web Bluetooth; Socket TCP', 'Descubrir, autenticar, intercambiar y reconectar con Reloj, TV y wearable'],
         ['PWA (`web/`)', 'manifest.json, sw.js, flutter_bootstrap.js', 'Instalación, precarga del app shell y funcionamiento sin conexión'],
         ['API', 'NestJS 11 + Prisma 5 en Vercel', 'Autenticación, roles, sesiones, favoritos, dispositivos, biblioteca, bitácora'],
         ['Base de datos', 'PostgreSQL en Neon (us-east-1)', 'Modelo relacional con JSONB para datos variables'],
         ['Periféricos (`companion/`)', 'Kotlin + Jetpack Compose', 'Servidor GATT del Reloj y la TV, PIN, vibración y D-pad']],
        [4.4, 5.2, 7.4], 'Capas de la solución')
d.h2('4.4 APIs que consume la app')
d.tabla([['Grupo', 'Rutas (prefijo /api)', 'Uso', 'Acceso'],
         ['Autenticación', '/auth/register, /login, /logout, /verify-email, /resend-verification, /forgot-password, /reset-password', 'Registro con código, acceso, recuperación', 'Público (con límite de 10/min)'],
         ['Usuario', '/users/me, /users/profile, /users/preferences, /users/me/sessions', 'Perfil, preferencias e historial', 'JWT'],
         ['Sesiones de enfoque', '/focus-sessions, /focus-sessions/resumen', 'Guardar sesiones (idempotentes por clientId) y resumen', 'JWT'],
         ['Favoritos y biblioteca', '/favorites, /media', 'Favoritos y medios propios (solo https)', 'JWT'],
         ['Dispositivos', '/devices', 'Reloj, TV y wearable vinculados', 'JWT'],
         ['Administración', '/admin/users, /admin/users/:id/role, /admin/users/:id/status, /admin/audit-log', 'Usuarios, roles, bloqueo y bitácora', 'JWT con rol ADMIN'],
         ['Salud del servicio', '/health', 'Verificación de producción', 'Público'],
         ['Firebase (SDK)', 'Auth y Firestore de cada función de Soporte', 'Tickets, reportes e incidencias', 'Reglas por cuenta y rol']],
        [3.0, 6.6, 4.4, 3.0], 'APIs consumidas por la app', tam=9)
d.h2('4.5 Secuencia BLE: reto + HMAC con PIN')
d.p('CEOSMOS es el central y cada periférico publica un servicio con tres características: AUTH (reto y respuesta), A_DISP (CEOSMOS escribe) y '
    'DE_DISP (el periférico notifica). El periférico envía un reto aleatorio de un solo uso; CEOSMOS responde con HMAC-SHA256(PIN, reto). El PIN '
    'nunca viaja; sin autenticar, toda escritura se rechaza (GATT 8) y tres fallos bloquean 60 s. Los mensajes son JSON de hasta 180 bytes, '
    'validados en tipo, rango y tamaño, con un máximo de 20 por segundo; un latido cada 5 s detecta si el periférico se reinició.', alin='j')
d.figura(E('diagramas', 'ble_secuencia.png'), 'Secuencia de conexión, autenticación, intercambio y persistencia con el Reloj (fuente: tool/diagramas/ble_secuencia.html)', 16.5,
         'Diagrama de secuencia BLE: descubrimiento, reto, respuesta HMAC con el PIN, intercambio de lecturas y guardado de la sesión en la API')
d.h2('4.6 Datos y almacenamiento propio por función')
d.p('El núcleo es relacional (usuarios, sesiones, dispositivos, catálogo) por su necesidad transaccional y de integridad; los atributos variables '
    '(métricas del wearable, configuración de cada equipo, bitácora) van en columnas JSONB para no crear una tabla por atributo. Se descartó un '
    'almacén por vectores: no hay búsqueda semántica. Archivos admitidos: imágenes WebP/JPEG hasta 2 MB y audio MP3/AAC hasta 10 MB; la caché local '
    'del móvil se limita a 150 MB con reemplazo LRU y la de la PWA a 60 imágenes externas.', alin='j')
d.figura(E('diagramas', 'datos.png'), 'Modelo de datos de la API y almacenamiento propio de cada función (fuente: tool/diagramas/datos.html)', 16.5,
         'Diagrama del modelo de datos Prisma (User y sus nueve tablas dependientes) y tabla del almacenamiento propio de cada función')

# ======================= 5. B2 =======================
d.h1('5. Diseño de interfaz y experiencia de usuario')
d.h2('5.1 Sistema de diseño')
d.tabla([['Token', 'Valor', 'Uso'],
         ['Guinda', '#5B011D', 'Color de marca, botón primario, títulos'],
         ['Cian', '#51D7FD', 'Acento, botón secundario (con texto guinda), anillo de foco'],
         ['Cian para texto', '#08708F', 'Enlaces e íconos sobre fondos claros (5.36:1)'],
         ['Fondo / tinta', '#FFF8F3 / #1E0A12', 'Fondo crema y texto principal; modo oscuro #16060D / #FCEFF3'],
         ['Estados', 'éxito #17805A · advertencia #9A5800 · error #C42A3F', 'Siempre con ícono + texto (nunca solo color)'],
         ['Tipografía', 'Bricolage Grotesque 700/800 · DM Sans 400/500/700', 'Títulos y números grandes · texto, botones y formularios (empaquetadas)'],
         ['Espaciado', '4 · 8 · 12 · 16 · 24 · 32', 'Escala única en Flutter (Espacio)'],
         ['Radios', '12 · 16 · 20 · píldora', 'Tarjetas, diálogos y botones']],
        [3.4, 6.2, 7.4], 'Tokens del sistema de diseño (memoria/11 - Sistema de diseño.md)')
d.h2('5.2 Navegación y menús por rol')
d.tabla([['Pestaña', 'Contenido', 'Rol'],
         ['Inicio', 'Saludo, estado «Sincronizado» o «Sin conexión», comenzar sesión, intención (Concentración, Relajación, Inspiración)', 'Todos'],
         ['Explorar', 'Catálogo de ambientes, favoritos y biblioteca propia', 'Todos'],
         ['Mi sesión', 'Sesión en curso con pausa y confirmación antes de terminar', 'Todos'],
         ['Equipos', 'Reloj y TV por Bluetooth, wearable por Wi-Fi y Mensajería entre equipos', 'Todos'],
         ['Soporte', 'Tickets y chat interno; Incidencias sin conexión; Reportes e incidencias', 'Usuario, agente y administrador de Soporte'],
         ['Perfil', 'Favoritos, Cuenta y herramientas (Seguridad, Directorio, Citas), historial, cerrar sesión', 'Todos'],
         ['Perfil › Administración', 'Usuarios, roles, estado y bitácora', 'Solo ADMIN']],
        [3.4, 9.6, 4.0], 'Navegación y menús por rol')
d.p('En el teléfono la navegación es una barra inferior; en ventanas anchas (tableta, escritorio) pasa a una barra lateral fija.', alin='j')
d.figuras_lado([M('m_acceso'), M('m_inicio'), M('m_mi_sesion')],
               'Acceso, Inicio y sesión de enfoque en curso en el Galaxy S24', 8.5,
               'Capturas del teléfono: pantalla de acceso, Inicio y Mi sesión con el temporizador')
d.h2('5.3 Flujos principales')
d.numerada([
    '**Sesión de enfoque:** Acceso → elegir intención → ambiente y duración → sesión con pausa → confirmar antes de terminar → resumen en el historial (o pendiente si no hay red).',
    '**Reloj y TV:** Equipos → Conectar → PIN de 6 dígitos (solo la primera vez) → pulso en vivo; el botón del Reloj y el D-pad de la TV controlan la sesión.',
    '**Soporte:** Soporte → Tickets y chat interno → nuevo ticket → chat en tiempo real con el agente → asignación al administrador si hace falta.',
    '**Recuperación:** Olvidé mi contraseña → código por correo → nueva contraseña → acceso.',
])
d.h2('5.4 Accesibilidad')
d.viñetas([
    'Seis combinaciones de color ajustadas a contraste WCAG AA (`tool/contraste/`).',
    'Áreas táctiles de al menos 48 dp, nombres para lectores de pantalla y fuente del sistema al 200 % sin desbordes (`test/accesibilidad_test.dart`).',
    'Errores siempre con ícono y texto; foco visible con anillo cian en la TV (D-pad).',
])
d.h2('5.5 Decisiones de UX surgidas de las pruebas como usuario novato')
d.tabla([['Hallazgo', 'Decisión'],
         ['El botón Atrás cerraba la app dentro de algunas funciones (Android 16/17)', 'Atrás regresa a la sección anterior; prueba de navegación'],
         ['El diálogo «Agregar a mi biblioteca» se desbordaba con entradas al azar (usuario torpe)', 'Contenido desplazable; prueba de regresión'],
         ['El avatar quedaba a media cabecera en tabletas', 'Cabecera con Expanded + Align (1.3.0)'],
         ['Permiso de Bluetooth denegado sin salida clara', 'Mensaje con la ruta exacta en Ajustes, botón «Reintentar» y «Olvidar» el PIN'],
         ['Terminar una sesión por accidente', 'Confirmación antes de terminar'],
         ['Errores técnicos crudos (certificado, red)', 'Mensajes en lenguaje claro con qué hacer'],
         ['Textos de «Práctica», «P#» o «Examen» visibles', 'Nombres funcionales; prueba que impide que vuelvan a aparecer'],
         ['Reconectar el Reloj y la TV al abrir la app', 'Basta pulsar «Conectar»: no se vuelve a pedir el PIN y las caídas en uso se reconectan solas']],
        [8.0, 9.0], 'Decisiones de UX tomadas a partir de pruebas')
d.h2('5.6 Manual de usuario')
d.p('El **Manual de usuario - CEOSMOS** (documento aparte, 35 páginas) describe la instalación (APK y PWA), la cuenta y el acceso, cada función por '
    'rol con capturas anotadas, el Reloj y la TV, el uso sin internet, la solución de problemas, la seguridad y un glosario.', alin='j')
d.figuras_lado([M('m_admin_menu'), M('m_equipos_conectados')],
               'Menú de administración de Soporte y Equipos con Reloj y TV conectados (capturas anotadas del Manual)', 9.0,
               'Capturas anotadas: menú del administrador de Soporte y pestaña Equipos con el Reloj y la TV conectados')

# ======================= 6. C =======================
d.h1('6. Desarrollo de la aplicación tipo PWA')
d.h2('6.1 Funcionamiento de la aplicación (C1)')
d.p('La PWA es la misma app Flutter compilada para web (`scripts/construir_pwa.ps1`): acceso con la API de producción, Inicio, Explorar, sesiones '
    'de enfoque con historial, Equipos con Web Bluetooth y Perfil. Lo que depende de la plataforma se resuelve con importaciones condicionales: en '
    'web, BLE usa Web Bluetooth y la caché de imágenes la administra el service worker. Se verificó en Chromium el 24/11: acceso, Inicio, sesión '
    'completa guardada en el historial y Equipos.', alin='j')
d.tabla([['Función', 'App Android', 'PWA'],
         ['Acceso, registro, recuperación, roles', 'Sí', 'Sí'],
         ['Inicio, Explorar, favoritos, biblioteca, historial', 'Sí', 'Sí'],
         ['Sesiones de enfoque sin conexión', 'Sí', 'Sí (service worker + cola persistente)'],
         ['Reloj y TV por Bluetooth LE', 'Sí (flutter_blue_plus)', 'Web Bluetooth en Chrome y Edge (ver §7.1)'],
         ['Wearable por Wi-Fi (TCP)', 'Sí', 'No: el navegador no abre sockets TCP'],
         ['Funciones de Soporte (Firebase)', 'Sí', 'Se usan en la app Android']],
        [6.6, 4.4, 6.0], 'Funciones disponibles por plataforma')
d.h2('6.2 Manifiesto y configuración PWA (C2)')
d.p('`web/manifest.json` declara todo lo que Chrome exige para instalar y lo que mejora la experiencia instalada; Chrome reportó **0 errores de '
    'instalabilidad** y `test/pwa_test.dart` valida el manifiesto en cada corrida del CI.', alin='j')
d.tabla([['Campo', 'Valor', 'Para qué'],
         ['id, start_url, scope', '`./`', 'Identidad estable de la app instalada y alcance de navegación'],
         ['name / short_name', 'CEOSMOS · Móvil Integral / CEOSMOS', 'Nombre en la instalación y bajo el ícono'],
         ['display / display_override', 'standalone; window-controls-overlay, standalone, minimal-ui', 'Ventana propia sin barra del navegador'],
         ['icons', '192 y 512 px, `any` y `maskable`', 'Ícono nítido y recortable por el sistema'],
         ['theme_color / background_color', '#5B011D / #FFF8F3', 'Colores de la marca en la barra y la pantalla de arranque'],
         ['screenshots', 'narrow 412 × 860 y wide 1280 × 800', 'Diálogo de instalación enriquecido'],
         ['shortcuts', 'Explorar y Equipos (`?pestana=`)', 'Accesos directos desde el ícono instalado'],
         ['lang, dir, categories', 'es-MX, ltr; health, lifestyle, productivity', 'Idioma y clasificación']],
        [4.0, 6.4, 6.6], 'Campos del manifiesto web')
d.h2('6.3 Service Worker y funcionamiento offline (C3)')
d.p('Flutter 3.41 instala un service worker que se desregistra solo, por lo que CEOSMOS usa uno propio (`web/sw.js`). Al compilar, '
    '`scripts/pwa_precache.py` escribe la lista de precarga y una versión calculada con el hash del contenido: si cambia un archivo, se instala '
    'el nuevo service worker y se borra la caché anterior.', alin='j')
d.tabla([['Recurso', 'Estrategia', 'Motivo'],
         ['App shell (HTML, JS, CanvasKit, fuentes, audios, íconos)', 'Precarga en la instalación (31 archivos, 19.1 MB)', 'Abrir sin red desde la primera visita'],
         ['Navegación', 'Red primero; sin red, el `index.html` guardado', 'Siempre la versión más nueva cuando hay red'],
         ['Archivos propios', 'Caché primero y actualización en segundo plano', 'Rapidez'],
         ['API de CEOSMOS, Firebase y peticiones que no sean GET', 'Nunca se guardan', 'Datos personales y tokens; el modo sin conexión los maneja la app'],
         ['Imágenes externas de la biblioteca', 'Caché propia de 60 entradas como máximo', 'Equivalente web de la caché LRU del móvil']],
        [5.4, 5.8, 5.8], 'Estrategias de caché del service worker')
d.p('**Modo sin conexión de la app.** El perfil público y las sesiones pendientes se guardan en el equipo (`lib/data/cache_sin_conexion.dart`), '
    'nunca la contraseña ni el token, que sigue en el almacén seguro. Al volver la red, la app reintenta con espera progresiva y envía cada sesión '
    'con el mismo `clientId`, por lo que el servidor la guarda **una sola vez**. Lo validan `test/sin_conexion_test.dart` y la secuencia de la figura '
    'siguiente.', alin='j')
d.figuras_lado([E('pwa', '01_sin_conexion_perfil_guardado.png'), E('pwa', '02_sesion_sin_conexion.png'),
                E('pwa', '03_reabierta_sin_conexion_pendiente.png'), E('pwa', '04_red_vuelve_sincronizado.png')],
               'PWA sin red: abre con el perfil guardado, termina una sesión, sigue pendiente al reabrir y se sincroniza al volver la red', 7.6,
               'Cuatro capturas de la PWA: sin conexión con perfil guardado, sesión sin conexión, reabierta con la sesión pendiente y red de vuelta sincronizada')
d.h2('6.4 Diseño responsivo e instalabilidad (C4)')
d.p('La interfaz se adapta por ancho de ventana: barra inferior en teléfono y barra lateral fija en tableta y escritorio. Un barrido automático '
    'de **91 tamaños** (240 a 1600 dp de ancho, 320 a 1000 de alto, `test/tamanos_pantalla_test.dart`) no muestra desbordes; la fuente del sistema '
    'al 200 % tampoco los produce.', alin='j')
d.figuras_lado([E('pwa', 'movil_412x860.png'), E('pwa', 'tableta_820x1180.png')],
               'La PWA en teléfono (412 × 860) y en tableta (820 × 1180)', 8.5,
               'La misma pantalla de la PWA en tamaño de teléfono y de tableta')
d.figura(E('pwa', 'escritorio_1280x800.png'), 'PWA en escritorio (1280 × 800): la navegación pasa a una barra lateral', 14.0)
d.p('**Instalación.** En Chrome o Edge de escritorio aparece «Instalar CEOSMOS» en la barra de direcciones y la app se abre en su propia ventana '
    '(verificado el 24/11, 0 errores de instalabilidad). En Android se instala desde el menú ⋮ › «Instalar app» de Chrome con el mismo manifiesto. '
    'La PWA se sirve en `http://localhost:4200`, que el navegador trata como contexto seguro (requisito del service worker y de Web Bluetooth) y que '
    'ya está admitido por CORS en la API de producción.', alin='j')

# ======================= 7. D =======================
d.h1('7. Integración con dispositivos inteligentes')
d.h2('7.1 Comunicación con el dispositivo inteligente (D1)')
d.p('El Galaxy S24 con CEOSMOS es el **central** y la Galaxy Tab S9 ejecuta dos **periféricos GATT** nativos en Kotlin: CEOSMOS Reloj y CEOSMOS TV. '
    'La conexión sigue la secuencia de la §4.5: descubrimiento por UUID de servicio, reto aleatorio, respuesta HMAC-SHA256 con el PIN de 6 dígitos '
    '(solo la primera vez) e intercambio por notificaciones. Como alternativa, un wearable en la misma red Wi-Fi puede enviar lecturas por TCP/IP '
    '(una línea JSON por lectura a IP:puerto).', alin='j')
d.figuras_lado([M('m_equipos_conectar'), M('m_equipos_conectados')],
               'Equipos antes y después de conectar el Reloj y la TV por Bluetooth LE', 9.0,
               'Pestaña Equipos con Reloj y TV desconectados y luego conectados con pulso en vivo')
d.tabla([['Prueba en hardware (S24 + Tab S9)', 'Resultado'],
         ['Conexión con PIN y pulso en vivo', 'Correcto'],
         ['Notificación de la app al Reloj', 'Correcto'],
         ['Inicio de la sesión desde la TV («Siguiente» con el D-pad)', 'Correcto'],
         ['Pausa desde el Reloj y desde la TV', 'Correcto'],
         ['Bluetooth apagado y encendido', 'Reconecta solo en menos de 8 s'],
         ['Permiso denegado', 'Mensaje claro con la ruta en Ajustes, sin cierre'],
         ['Cerrar y abrir las apps Reloj y TV', 'Reautenticación sin PIN en ≈ 4 s (latido, versión 1.2.1)'],
         ['Central sin PIN', 'Escritura rechazada («central no autenticado»); cubierto también por pruebas automáticas']],
        [9.0, 8.0], 'Pruebas de comunicación en los equipos reales')
d.p('**Web Bluetooth en la PWA.** La PWA incluye el mismo flujo sobre Web Bluetooth (Chrome y Edge): en Chromium se abre el selector de '
    'dispositivos filtrado por el servicio de CEOSMOS. La conexión de la PWA con el Reloj y la TV reales **no se probó en hardware**: la '
    'demostración de dispositivos se hace con la app Android, que es el cliente pensado para ese uso (el teléfono es el hub), y la PWA reutiliza '
    'el mismo protocolo, cubierto por las pruebas automáticas con el periférico simulado.', alin='j')
d.h2('7.2 Uso de capacidades o sensores (D2)')
d.tabla([['Capacidad', 'Dónde', 'Uso en CEOSMOS'],
         ['Radio Bluetooth LE', 'S24 y Tab S9', 'Enlace central ↔ periféricos con anuncio, GATT y notificaciones'],
         ['Botón del Reloj', 'App Reloj', 'Pausar y reanudar la sesión desde la muñeca'],
         ['D-pad / control remoto', 'App TV', 'Anterior, Pausar, Terminar y Siguiente; foco visible'],
         ['Vibración', 'App Reloj', 'Aviso al recibir una notificación de CEOSMOS'],
         ['Notificaciones y servicio en primer plano', 'S24', 'La sesión y el enlace siguen vivos con la pantalla apagada'],
         ['Audio en segundo plano', 'S24', 'Ambientes sonoros durante la sesión'],
         ['Almacén seguro (Android Keystore)', 'S24', 'Token de acceso cifrado por hardware'],
         ['Pulso y pasos', 'App Reloj', 'Lecturas generadas por la app con el formato de un reloj real']],
        [5.0, 3.4, 8.6], 'Capacidades y sensores utilizados')
d.p('**Límite declarado: pulso y pasos.** La Tab S9 no tiene sensor de frecuencia cardiaca y no se contó con un reloj físico, así que la app '
    'Reloj genera las lecturas con el mismo formato, rango y frecuencia que un reloj real. Todo lo demás es real: el transporte BLE, la validación '
    '(30–230 bpm), la visualización en vivo y el guardado en el historial. Un wearable por TCP/IP puede enviar lecturas reales sin cambiar la app.', alin='j')
d.figura(M('m_reloj'), 'App Reloj en la Tab S9: pulso, pasos, control de la sesión y registro de mensajes (PIN oculto)', 15.0,
         'Captura anotada de la app CEOSMOS Reloj con el pulso, los pasos, el botón Reanudar y el registro de mensajes')
d.h2('7.3 Intercambio y procesamiento de información (D3)')
d.tabla([['Aspecto', 'Implementación'],
         ['Formato', 'JSON de hasta 180 bytes por mensaje (`lib/core/ble/ble_protocolo.dart` y `Protocolo.kt`, mismo vector HMAC en Dart y Kotlin)'],
         ['Validación', 'Tipo, rango y tamaño; pulso 30–230 bpm; duración máxima 14 400 s; basura binaria descartada sin excepciones'],
         ['Control de flujo', 'Máximo 20 mensajes por segundo; latido cada 5 s'],
         ['Del periférico a CEOSMOS', 'Lecturas de pulso y pasos, botón del Reloj, D-pad de la TV'],
         ['De CEOSMOS al periférico', 'Estado de la sesión (ambiente, tiempo, pausa), notificaciones al Reloj, proyección en la TV'],
         ['Persistencia', 'Resumen de la sesión en `metadata.wearable` (JSONB) en la API; equipos en `/devices` con la dirección estable `CE:05:<id>`'],
         ['Pruebas', '`test/ble/` con periférico simulado; 4 pruebas de regresión de reconexión; regresión DEF-BLE-01']],
        [4.0, 13.0], 'Intercambio y procesamiento de datos con los dispositivos')
d.figura(M('m_tv'), 'App TV en la Tab S9: estado de la sesión, controles del D-pad y registro de mensajes (PIN oculto)', 15.0,
         'Captura anotada de la app CEOSMOS TV con los controles Anterior, Reanudar, Terminar y Siguiente y el registro')
d.h2('7.4 Manejo de permisos y compatibilidad (D4)')
d.tabla([['Plataforma', 'Permisos o requisito', 'Comportamiento'],
         ['Android 12 o posterior', 'BLUETOOTH_SCAN y BLUETOOTH_CONNECT en tiempo de ejecución', 'Se piden al conectar; si se niegan, mensaje con la ruta en Ajustes y «Reintentar»'],
         ['Android 11 o anterior', 'Ubicación (requisito del sistema para escanear BLE)', 'Declarado en el manifiesto Android; no se contó con un equipo con esa versión para probarlo'],
         ['Periféricos (Reloj y TV)', 'BLUETOOTH_ADVERTISE y CONNECT', 'Se piden al abrir cada app'],
         ['Bluetooth apagado', '—', 'Aviso «El Bluetooth está apagado» con botón «Encender»; reconexión automática'],
         ['PWA en Chrome o Edge', 'Selector de Web Bluetooth (gesto del usuario) y contexto seguro', 'El navegador muestra los equipos de CEOSMOS'],
         ['PWA en Firefox o Safari', 'Sin Web Bluetooth', 'La tarjeta de Equipos explica que se use Chrome o Edge; el resto de la app funciona']],
        [3.6, 5.6, 7.8], 'Permisos y compatibilidad')
d.figuras_lado([M('m_permiso'), M('m_bt_apagado')],
               'Permiso de Bluetooth denegado y Bluetooth apagado: mensajes claros y recuperación', 9.0,
               'Capturas anotadas: mensaje de permiso denegado con Reintentar y aviso de Bluetooth apagado con reconexión')

# ======================= 8. E =======================
d.h1('8. Seguridad y calidad del software')
d.h2('8.1 Protección de información y autenticación (E1)')
d.viñetas([
    '**Acceso:** JWT HS256 validado en forma; token en Android Keystore (almacén seguro); mensaje de error genérico que no revela si la cuenta existe; bloqueo por intentos; límite de peticiones.',
    '**Autorización:** roles USER y ADMIN en la API y datos filtrados por usuario (IDOR probado); reglas de Firestore por cuenta y rol en Soporte.',
    '**Transporte:** HTTPS con TLS 1.2+ y HSTS; certificado no confiable rechazado con mensaje claro; CSP `default-src none` en la API.',
    '**Bluetooth:** reto + HMAC-SHA256 con PIN; el PIN nunca viaja; tres fallos bloquean 60 s.',
    '**PWA:** el service worker nunca guarda respuestas de la API ni de Firebase; la copia sin conexión no guarda contraseña ni token y se borra al cerrar sesión.',
    '**Secretos:** historial de git revisado antes de publicar el repositorio; secretos de la API rotados el 22/11; el CI no usa credenciales.',
])
d.tabla([['Conjunto Red Box', 'Dónde', 'Resultado'],
         ['Original (tokens, alg:none, inyección SQL, IDOR, asignación masiva, cuerpo enorme, rol, hash, logout)', 'API local', '13/13'],
         ['Ampliado (tokens expirados y HS512, NoSQL, JSON anidado, XSS, javascript: en medios, CORS, cabeceras, enumeración, fuerza bruta)', 'API local', '37/37 (27/37 antes de corregir)'],
         ['Producción sin credenciales (tokens falsos, inyecciones, JSON anidado, CORS, CSP, mensaje genérico, 429)', 'API de producción, ≤ 4 pet./s', '27/27']],
        [10.0, 3.8, 3.2], 'Red Box: qué se atacó y dónde')
d.p('Las pruebas que exigen iniciar sesión (IDOR, medios javascript:, cambio de rol) se ejecutan en local y en las pruebas de la API con el mismo '
    'código desplegado, para no escribir contraseñas reales en producción.', alin='j')
d.tabla([['Área MASVS', 'Estado', 'Evidencia o motivo'],
         ['Almacenamiento', 'cumple', 'Token en Keystore; respaldo desactivado; SQLite sin credenciales'],
         ['Criptografía', 'cumple con riesgo aceptado', 'TLS 1.2+ y HSTS; JWT solo HS256; BLE con reto + HMAC, carga útil sin cifrar (§10.2)'],
         ['Autenticación y autorización', 'cumple', 'Red Box: tokens, IDOR, roles, sesión tras logout'],
         ['Red', 'cumple', 'Sin texto claro; certificado no confiable rechazado con mensaje claro'],
         ['Plataforma', 'cumple', 'Solo la actividad principal exportada'],
         ['Código', 'cumple', 'Dependencias auditadas (0 vulnerabilidades en lo distribuido); validación de entradas; errores sin trazas'],
         ['Resiliencia', 'riesgo aceptado', 'Compilación AOT, sin ofuscación ni detección de root (app académica sin datos de pago)'],
         ['Privacidad', 'cumple para uso académico', 'Datos mínimos; alojados en EE. UU.']],
        [3.6, 3.6, 9.8], 'Mapa OWASP MASVS (detalle en evidencias/blindaje/masvs.md)')

d.h2('8.2 Pruebas y validación (E2)')
d.p('La validación combina pruebas automatizadas, integración continua, ataques a la API y recorridos en los equipos reales.', alin='j')
d.h3('Caja negra y caja blanca')
d.p('**Caja negra:** 12 requisitos verificables (operaciones, validaciones, persistencia, navegación y roles, manejo de errores) con una suite '
    'automatizada que corre en cada revisión, ampliada con pruebas del Reloj y la TV y con una prueba que recorre la navegación y verifica que '
    'ningún texto visible nombre las prácticas. **Caja blanca:** análisis estático, pruebas por caminos independientes, cobertura de instrucciones, '
    'decisiones y condiciones, códigos HTTP, consultas con EXPLAIN y mediciones de red sobre la app, la API y la base; los defectos encontrados se '
    'corrigieron en el código.', alin='j')
d.h3('Automatización e integración continua')
d.p('Se automatizaron tres componentes críticos: **acceso** (validación de inicio de sesión y registro), **comunicación** (cliente de la API '
    'contra un servidor HTTP local y protocolo BLE reto + HMAC en Dart y Kotlin) y **persistencia** (directorio de alumnos en SQLite con la '
    'migración del campo correo), más una prueba de regresión del defecto DEF-BLE-01 que **falla con el código viejo y pasa con el corregido**. '
    'El pipeline de GitHub Actions (`.github/workflows/ci.yml`) corre en cada push y pull request sin secretos: análisis estático y pruebas de '
    'Flutter con cobertura y reporte JUnit, compilación de la PWA con verificación del service worker, y pruebas y lint de las apps Reloj, TV y '
    'Companion. Ninguna prueba usa la base ni la API de producción.', alin='j')
d.tabla([['ID', 'Tipo', 'Qué valida', 'Resultado'],
         ['AUT-01', 'Unitarias', 'Validación de acceso, directorio y mensajes BLE con entradas válidas, vacías y nulas', '4/4'],
         ['AUT-02', 'Unitarias', 'Límites (contraseña, usuario, código, edad, pulso), vector HMAC Dart = Kotlin, recorte a 180 B', '7/7 Dart, 5/5 Kotlin'],
         ['AUT-03', 'Unitarias / regresión', 'Excepciones controladas y DEF-BLE-01 (TV reiniciada)', '4/4; viejo falla, nuevo pasa'],
         ['AUT-04', 'Integración', 'Cliente HTTP real contra servidor local: 200/201/400/401/404 e IDOR', '4/4'],
         ['AUT-05', 'Integración (widget)', 'Sin servidor: conexión rechazada y tiempo límite → mensaje en pantalla', '2/2'],
         ['AUT-06', 'Persistencia', 'SQLite: CRUD, duplicado y migración v1→v2 sin pérdida', '5/5'],
         ['AUT-07', 'CI', 'Workflow en push', 'Verde'],
         ['AUT-08', 'CI', 'Workflow en pull request y tras una corrección', 'Verde']],
        [1.6, 3.0, 9.2, 3.2], 'Matriz de automatización AUT-01 a AUT-08', tam=9)
d.p('Corridas de referencia: [1.3.0](' + CI_13 + ') · [documentación final](' + CI_DOC + ') · [entrega-v4](' + CI_V4 + ') · '
    '[main tras la automatización de pruebas](' + CI_P13 + '). De 30 corridas, 28 en verde; la única fallida (21/11, aviso del análisis estático en '
    'una herramienta de capturas) se corrigió en la siguiente y la cancelada fue reemplazada por un push posterior.', alin='j')
d.figura(E('p13_14', 'ci_04_actions_main_verde.png'), 'GitHub Actions con la rama main en verde tras integrar las pruebas automatizadas', 15.0,
         'Captura de la página de GitHub Actions con las corridas en verde')
d.h3('Resumen de pruebas y resultados')
d.tabla([['Conjunto', 'Resultado', 'Fecha'],
         ['Pruebas de Flutter', '344/344; análisis estático sin avisos', '25/11'],
         ['Pruebas de la API (Jest)', '79/79 (7 suites)', '25/11'],
         ['Pruebas de Kotlin', 'Reloj, TV y Companion: 14/14 cada una; lint en CI', '25/11'],
         ['Cobertura de líneas', '56.0 % (3 373 de 6 023); núcleo 84.8 %', '25/11'],
         ['Integración continua', '30 corridas, 28 en verde; 1.3.0 y documentación final en verde', '25/11'],
         ['Caja negra', '12 requisitos y suite automatizada', 'cada revisión'],
         ['Caja blanca', 'Caminos independientes, decisiones y condiciones, EXPLAIN y códigos HTTP', '11/11'],
         ['Red Box de la API', '13/13 y 37/37 en local; 27/27 en producción sin credenciales', '22/11'],
         ['Usuario torpe', '12 100 acciones (S24 5 000, Tab S9 5 000 + 2 100)', '22/11'],
         ['Reloj y TV de punta a punta', 'Casos de la §7.1 en hardware; reconexión con latido', '22/11'],
         ['Soporte con roles', 'TC01–TC08 con 4 cuentas en dos equipos', '19 y 22/11'],
         ['PWA y modo sin conexión', 'Instalable (0 errores), sin red y sincronización sin duplicados', '24/11']],
        [4.4, 9.8, 2.8], 'Resumen de pruebas y resultados', tam=9)

d.h2('8.3 Rendimiento, estabilidad y recuperación (E3)')
d.h3('Resiliencia de red')
d.p('El cliente de la API tiene un plazo de 15 s, reintentos con espera exponencial y escrituras idempotentes (`clientId`) para no duplicar '
    'sesiones; la app muestra «Sin conexión», guarda lo pendiente y lo envía sola al volver la red. El Reloj y la TV se reconectan solos tras '
    'apagar el Bluetooth o reiniciar sus apps.', alin='j')
d.tabla([['Servicio', 'Ancho de banda mínimo', 'Latencia máxima (RTT)', 'Por debajo del mínimo'],
         ['API de CEOSMOS', '5 kbps (11.4 s)', '4 s (12.4 s, dentro del límite de 15 s)', 'Aviso de tiempo agotado; las sesiones quedan pendientes y se reenvían sin duplicarse'],
         ['Firestore', '5 kbps (9.8 s)', 'Funciona con 2 s', 'Caché local y sincronización al volver la red'],
         ['Firebase Auth', '5 kbps (10.6 s)', 'Funciona con 2 s', 'Mensaje de error del inicio de sesión']],
        [3.0, 3.4, 4.4, 6.2], 'Red mínima por servicio (medido contra producción, 22/11)')
d.p('En EDGE/2G (50 kbps y 400 ms) la API responde en 2.5 s y con 20 % de pérdida en menos de 5 s. Desde seis continentes la API responde 200 '
    'entre 137 y 763 ms (sondas públicas, 22/11).', alin='j')
d.h3('Estabilidad')
d.p('**Usuario torpe:** una prueba de integración ejecuta acciones al azar (toques, textos inválidos, Atrás y desplazamientos) en una copia '
    'aislada de la app: 5 000 en el S24 sin errores, cierres ni ANR; 5 000 en la Tab S9 sin cierres ni ANR, con 4 desbordes en «Agregar a mi '
    'biblioteca» que se corrigieron; 2 100 de verificación con 0 errores. **Tamaños:** 91 tamaños sin desbordes; en la tablet la ventana flotante '
    'es cómoda desde 260 × 440 dp y no da errores hasta 220 × 380 dp.', alin='j')
d.h3('Recuperación y plan de contingencia')
d.p('El script `arreglo_rapido` (Bash y PowerShell) analiza y prueba el área afectada, compila, instala en los dos equipos sin borrar datos y '
    'muestra el registro de errores. En el ensayo se simularon tres fallos (validación de correo, tiempo de espera de la red y permiso de '
    'Bluetooth): las pruebas detectaron los tres y cada ciclo de corrección y verificación tomó entre 1.9 y 2.4 minutos.', alin='j')
d.h3('Fallas encontradas y corregidas')
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

# ======================= 9. F =======================
d.h1('9. Demostración funcional')
d.h2('9.1 Entorno')
d.tabla([['Elemento', 'Preparación'],
         ['API', 'Producción (`https://ceosmos-api.vercel.app/api`)'],
         ['PWA', '`scripts\\construir_pwa.ps1 -Servir` → `http://localhost:4200` en Chrome'],
         ['Teléfono', 'Galaxy S24 con CEOSMOS y sesión iniciada'],
         ['Periféricos', 'Galaxy Tab S9 con CEOSMOS Reloj y CEOSMOS TV abiertos'],
         ['Respaldo', 'Capturas en `evidencias/`; lista previa en `evidencias/blindaje/Lista de verificacion previa`']],
        [3.4, 13.6], 'Entorno de la demostración')
d.h2('9.2 Guion (≈ 8 minutos)')
d.numerada([
    '**Problema y arquitectura (1 min).** Figuras de arquitectura y despliegue: un código Flutter, dos clientes (APK y PWA), una API, una base, dos periféricos BLE.',
    '**PWA (2 min).** Abrir `http://localhost:4200` → «Instalar» → se abre en su ventana. DevTools › Application: manifiesto y `sw.js` activo. Cambiar el ancho: barra inferior ↔ barra lateral.',
    '**Sin conexión (2 min).** DevTools › Network › Offline → recargar: abre con «Sin conexión». Terminar una sesión corta → recargar (sigue pendiente) → Online: pasa a «Sincronizado» y aparece una sola vez en el historial.',
    '**Dispositivos (2 min).** En el S24: Equipos › Reloj › Conectar (PIN). Pulso en vivo; el botón del Reloj pausa la sesión; la TV proyecta y «Siguiente» inicia la sesión. Apagar y encender el Bluetooth: reconecta solo.',
    '**Seguridad y calidad (1 min).** GitHub Actions en verde (Flutter, PWA, Kotlin); Red Box 27/27 en producción; 344 pruebas.',
])
d.h2('9.3 Plan alterno')
d.viñetas([
    'Sin internet en el aula: la PWA y la app abren en modo sin conexión; la API puede levantarse en local (`scripts\\dev_backend.ps1`).',
    'Si un periférico no aparece: cerrar y abrir su app (la reconexión no pide el PIN) o mostrar el registro de mensajes de la tablet.',
    'Si falla el hardware: secuencia de capturas de la §7 y corridas de CI como evidencia.',
])
d.h2('9.4 Dominio técnico')
d.p('Los fundamentos que sostienen la defensa (por qué un service worker propio, cómo se evita duplicar sesiones, cómo se protege el enlace '
    'BLE, por qué la TV es nativa) están resumidos en el **Anexo C** con la referencia al código que los implementa.', alin='j')

# ======================= 10 =======================
d.h1('10. Conclusiones, limitaciones y trabajo futuro')
d.h2('10.1 Conclusiones')
d.p('El objetivo general se cumplió: un solo código Flutter funciona como app Android y como PWA instalable, usa la misma API y la misma base que '
    'CEOSMOS WEB, se comunica por Bluetooth LE autenticado con el Reloj y la TV y no pierde sesiones sin conexión. Las prácticas del curso dejaron '
    'de ser ejercicios aislados y quedaron como funciones de CEOSMOS, cada una con su menú, su rol y su almacenamiento. La calidad se sostiene con '
    '344 pruebas Flutter, 79 de la API y 42 de Kotlin, integración continua en verde, una API atacada y corregida en producción y pruebas en los '
    'equipos reales.', alin='j')
d.h2('10.2 Limitaciones y riesgos aceptados')
d.tabla([['Aspecto', 'Situación', 'Justificación o mitigación'],
         ['Passkeys en móvil', 'No implementado', 'Android solo acepta passkeys para un dominio verificado con `assetlinks.json`; el proyecto no tiene dominio propio. El acceso usa correo y contraseña con JWT, verificación por correo y bloqueo por intentos'],
         ['Pulso y pasos', 'Generados por la app Reloj', 'La tablet no tiene sensor; el formato, la validación y el guardado son los de un reloj real'],
         ['Web Bluetooth de la PWA con el Reloj y la TV', 'No probado en hardware', 'La demostración de dispositivos usa la app Android; la PWA reutiliza el mismo protocolo, cubierto por pruebas automáticas'],
         ['Android 11 o anterior', 'No probado', 'No se contó con un equipo con esa versión; el permiso de ubicación está declarado'],
         ['Carga útil BLE sin cifrar', 'Riesgo aceptado', 'El PIN nunca viaja; solo viajan pulso, pasos y estado de la sesión a pocos metros'],
         ['APK firmado con la llave de depuración', 'Riesgo aceptado', 'No se publica en Google Play; otra firma obliga a desinstalar y perder datos'],
         ['Limitador de peticiones en memoria por instancia', 'Riesgo aceptado', 'Suficiente para la carga académica; mejora futura con Redis'],
         ['Almacenamiento local sin cifrar', 'Riesgo aceptado', 'No guarda credenciales; el token está en el Keystore']],
        [4.2, 3.4, 9.4], 'Limitaciones y riesgos aceptados', tam=9)
d.h2('10.3 Trabajo futuro')
d.viñetas([
    'Publicar la PWA en un dominio propio (agregándolo a CORS) y, con él, passkeys en móvil (`assetlinks.json`).',
    'Leer pulso real de un reloj Wear OS; BLE con bonding cifrado (LE Secure Connections).',
    'Keystore de publicación, limitador de peticiones en Redis y aviso de privacidad formal.',
])
d.h2('10.4 Referencias')
refs = [
    ('OWASP. Mobile Application Security Verification Standard (MASVS).', 'https://mas.owasp.org/MASVS/'),
    ('OWASP. Mobile Top 10.', 'https://owasp.org/www-project-mobile-top-10/'),
    ('Flutter. Documentación oficial.', 'https://docs.flutter.dev/'),
    ('Flutter. Building a web application with Flutter.', 'https://docs.flutter.dev/platform-integration/web/building'),
    ('MDN Web Docs. Web Bluetooth API.', 'https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API'),
    ('MDN Web Docs. Web app manifests.', 'https://developer.mozilla.org/en-US/docs/Web/Manifest'),
    ('MDN Web Docs. Service Worker API.', 'https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API'),
    ('W3C. Web Application Manifest.', 'https://www.w3.org/TR/appmanifest/'),
    ('Android Developers. Bluetooth Low Energy.', 'https://developer.android.com/develop/connectivity/bluetooth/ble/ble-overview'),
    ('Neon. Documentación.', 'https://neon.com/docs'),
    ('Vercel. Documentación.', 'https://vercel.com/docs'),
    ('Firebase. Documentación.', 'https://firebase.google.com/docs'),
    ('W3C. Web Content Accessibility Guidelines (WCAG) 2.2.', 'https://www.w3.org/TR/WCAG22/'),
]
for i, (t, u) in enumerate(refs, 1):
    d.p(f'[{i}] {t} [{u}]({u})', despues=2)

# ======================= Anexos =======================
d.h1('Anexo A. Matriz de trazabilidad de la rúbrica')
tr = [['Criterio', 'Sección', 'Evidencia en el repositorio'],
      ['A1 Planteamiento y justificación', '§1', '`memoria/01`, `memoria/02`'],
      ['A2 Seguimiento de avances', '§2', '`git log`, etiquetas `entrega-v1…v4`, `memoria/10 - Bitácora.md`, `cifras.md`'],
      ['A3 Decisiones y cambios', '§3', '`memoria/09 - Decisiones técnicas.md`, commits citados'],
      ['B1 Arquitectura', '§4', '`evidencias/diagramas/*.png`, fuentes en `tool/diagramas/`'],
      ['B2 Interfaz y UX', '§5; Manual de usuario', '`memoria/11 - Sistema de diseño.md`, `evidencias/manual/`, `evidencias/pwa/`'],
      ['C1 Funcionamiento', '§6.1', '`lib/`, `scripts/construir_pwa.ps1`, `evidencias/pwa/`'],
      ['C2 Manifiesto', '§6.2', '`web/manifest.json`, `test/pwa_test.dart`'],
      ['C3 Service worker y offline', '§6.3', '`web/sw.js`, `scripts/pwa_precache.py`, `lib/data/cache_sin_conexion.dart`, `test/sin_conexion_test.dart`'],
      ['C4 Responsivo e instalable', '§6.4', '`test/tamanos_pantalla_test.dart`, `evidencias/pwa/`'],
      ['D1 Comunicación', '§4.5, §7.1', '`lib/core/ble/`, `companion/`, `evidencias/ble_*.png`'],
      ['D2 Capacidades o sensores', '§7.2', '`companion/`, `evidencias/manual/m_reloj.png`, `m_tv.png`'],
      ['D3 Intercambio y procesamiento', '§7.3', '`lib/core/ble/ble_protocolo.dart`, `test/ble/`'],
      ['D4 Permisos y compatibilidad', '§7.4', '`android/app/src/main/AndroidManifest.xml`, `evidencias/ble_11_*`, `ble_12_*`'],
      ['E1 Protección y autenticación', '§8.1', '`evidencias/blindaje/masvs.md`, `evidencias/redbox_api.txt`, `evidencias/blindaje/redbox_ampliado.txt`'],
      ['E2 Pruebas y validación', '§8.2', '`test/`, `test/p13_14/`, `.github/workflows/ci.yml`, `evidencias/p13_14/`'],
      ['E3 Rendimiento y recuperación', '§8.3', '`evidencias/blindaje/red/`, `evidencias/blindaje/mono/`, `scripts/arreglo_rapido.*`'],
      ['F1 Demostración', '§9', '`evidencias/blindaje/Lista de verificacion previa`'],
      ['F2 Dominio técnico', '§9.4, Anexo C', '`evidencias/blindaje/Hoja de defensa`']]
d.tabla(tr, [4.4, 3.0, 9.6], 'Trazabilidad: criterio de la rúbrica → sección y evidencia', tam=8.5)

d.h1('Anexo B. Enlaces')
d.viñetas([
    f'Repositorio: [{REPO}]({REPO})',
    f'Integración continua (todas las corridas): [{REPO}/actions]({REPO}/actions)',
    f'Corrida de la versión 1.3.0: [{CI_13}]({CI_13})',
    f'Corrida de la documentación final: [{CI_DOC}]({CI_DOC})',
    f'Corrida de entrega-v4 (1.2.1): [{CI_V4}]({CI_V4})',
    'API de producción (salud): [https://ceosmos-api.vercel.app/api/health](https://ceosmos-api.vercel.app/api/health)',
    'Cifras vigentes: `evidencias/documentacion/cifras.md`',
])

d.h1('Anexo C. Fundamentos técnicos')
qa = [
    ('¿Por qué un service worker propio?', 'En Flutter 3.41 el service worker generado se instala y se desregistra solo; sin uno propio la app no abre sin red (`web/sw.js`).'),
    ('¿Qué guarda el service worker?', 'Solo el app shell (31 archivos, 19.1 MB) e imágenes externas (máximo 60). Nunca la API, Firebase ni peticiones que no sean GET.'),
    ('¿Cómo se actualiza la PWA?', '`scripts/pwa_precache.py` escribe en `sw.js` un hash del contenido; si cambia un archivo, se instala el nuevo service worker y se borra la caché anterior.'),
    ('¿Qué pasa con el token sin conexión?', 'Sigue en el almacén seguro; el servidor lo revalida en la primera petición y un 401 cierra la sesión y borra la copia local.'),
    ('¿Cómo se evita duplicar sesiones?', 'Cada sesión lleva un `clientId` generado una vez; si llega repetida, el servidor devuelve la existente.'),
    ('¿Por qué BLE y no TCP como decía el plan?', 'El plan venía de la inestabilidad del cuatrimestre anterior; con periféricos nativos en Kotlin el enlace fue estable. TCP quedó como alternativa para un wearable en Wi-Fi.'),
    ('¿Cómo se protege el enlace BLE?', 'Reto de un solo uso y respuesta HMAC-SHA256 con el PIN, que nunca viaja; sin autenticar se rechaza (GATT 8) y 3 fallos bloquean 60 s.'),
    ('¿Por qué la TV no es PWA?', 'Web Bluetooth solo puede ser central; la TV debe anunciar y servir GATT como periférico, lo que exige una app nativa.'),
    ('¿Funciona en iPhone?', 'La PWA, la instalación y el modo sin conexión sí; Safari no tiene Web Bluetooth y la tarjeta de Equipos lo explica.'),
    ('¿Cómo se detecta que el periférico se reinició?', 'Un latido cada 5 s; si el periférico responde «sin autorización», CEOSMOS se reautentica sin pedir el PIN (≈ 4 s).'),
]
d.tabla([['Pregunta', 'Respuesta']] + [[q, a] for q, a in qa], [5.0, 12.0], 'Fundamentos técnicos de la solución', tam=9)

salida = os.path.join(R, 'Reporte final - CEOSMOS Movil Integral.docx')
d.guardar(salida)
print(salida)
