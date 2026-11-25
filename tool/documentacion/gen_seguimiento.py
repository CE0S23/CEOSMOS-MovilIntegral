# -*- coding: utf-8 -*-
"""Genera «Documento de seguimiento del proyecto - CEOSMOS.docx» (criterios A1–A3, B1, B2 y resumen C–F).
Cifras: evidencias/documentacion/cifras.md. Uso: python tool/documentacion/gen_seguimiento.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from docgen import Doc, REPO  # noqa: E402

R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
E = lambda *p: os.path.join(R, 'evidencias', *p)  # noqa: E731
CI_13 = REPO + '/actions/runs/45686893198'
CI_V4 = REPO + '/actions/runs/45099965435'

d = Doc(os.path.join(R, 'Manual de usuario - CEOSMOS.docx'), 'Documento de seguimiento del proyecto')
d.margenes()
d.propiedades('Documento de seguimiento del proyecto - CEOSMOS',
              'Planteamiento, seguimiento, decisiones, arquitectura e interfaz de CEOSMOS Móvil Integral 1.3.0',
              'CEOSMOS; seguimiento; arquitectura; PWA; BLE; rúbrica')
d.encabezado_pie('Documento de seguimiento · versión 1.3.0')

d.portada(E('documentacion', 'logo_portada.png'), 'Documento de seguimiento del proyecto',
          'Planteamiento, avances, decisiones, arquitectura e interfaz',
          ['Versión de la app: 1.3.0 · Versión del documento: 1.0', 'Fecha: 25 de noviembre de 2026'],
          ['César Osvaldo Ramírez Pérez', 'Matrícula 2023371167 · Grupo IDGS16',
           'Profesor: M.C.C. Emmanuel Martínez Hernández', 'Repositorio: github.com/CE0S23/CEOSMOS-MovilIntegral'])

d.h1('Control de versiones')
d.tabla([['Versión', 'Fecha', 'Cambios', 'Autor'],
         ['0.1', '18/11/2026', 'Secciones de seguimiento, decisiones y arquitectura dentro del Reporte de avances.', 'C. O. Ramírez Pérez'],
         ['0.2', '24/11/2026', 'Revisión contra la rúbrica: planteamiento, objetivos, PWA, dispositivos y diagramas (aún dentro del Reporte).', 'C. O. Ramírez Pérez'],
         ['1.0', '25/11/2026', 'Documento propio. Se mueven aquí los apartados A1–A3, B1 y B2 del Reporte; se agregan diagramas de despliegue y de datos, alternativas y evidencia por decisión, incidentes, indicadores de la versión 1.3.0 y matriz de trazabilidad.', 'C. O. Ramírez Pérez']],
        [1.6, 2.2, 10.4, 3.0], 'Control de versiones del documento')
d.p('Todas las cifras de este documento salen de `evidencias/documentacion/cifras.md` (corte del 25/11/2026). '
    'Lo que no se probó se marca **no verificado**; los riesgos aceptados se dicen tal cual.')
d.indice()
d.lista_figuras()
d.lista_tablas()

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
d.h2('1.5 Objetivo general')
d.p('Desarrollar CEOSMOS Móvil Integral: una aplicación Flutter que se distribuye como app Android y como aplicación web progresiva (PWA) '
    'instalable, conectada a la API y a la base de datos de CEOSMOS WEB y a los dispositivos inteligentes Reloj y TV por Bluetooth LE, segura, '
    'probada y capaz de funcionar sin conexión.', alin='j')
d.h2('1.6 Objetivos específicos y su estado')
d.tabla([['Objetivo específico', 'Estado al 25/11/2026', 'Dónde se demuestra'],
         ['1. Unificar acceso, usuarios, sesiones de enfoque y dispositivos en la API NestJS + PostgreSQL (Neon) con JWT y roles.', 'Cumplido', '§4; Reporte › Seguridad verificada'],
         ['2. Comunicar la app con el Reloj y la TV por BLE (GATT) con reto + HMAC, y con un wearable por TCP/IP.', 'Cumplido en Android (hardware). **Parcial** en la PWA: Web Bluetooth no verificado en hardware', '§4.5; §6.2'],
         ['3. Usar datos y controles de los dispositivos (pulso, pasos, botón, D-pad) para conducir la sesión y guardarla en el historial.', '**Parcial**: flujo completo y probado, pero el pulso y los pasos son **simulados** por la app Reloj', '§6.2'],
         ['4. Publicar la app como PWA instalable con manifiesto, service worker propio y modo sin conexión.', 'Cumplido en `localhost:4200` (Chromium, 24/11). Sin dominio público (decisión pendiente)', '§6.1'],
         ['5. Diseño responsivo y accesible (240 a 1600 dp, contraste AA, áreas de 48 dp, fuente al 200 %).', 'Cumplido', '§5'],
         ['6. Validar con pruebas automatizadas, integración continua, pruebas de seguridad y pruebas en equipos reales.', 'Cumplido (344 pruebas Flutter, CI en verde); APK 1.3.0 **no instalado** en los equipos', '§2.4; Reporte › Calidad y pruebas'],
         ['7. Migrar las passkeys WebAuthn al móvil (plan del primer parcial).', '**No cumplido**: requiere publicar assetlinks.json en un dominio propio', '§2.3']],
        [7.6, 5.4, 4.0], 'Objetivos específicos y estado')
d.h2('1.7 Alcance')
d.tabla([['Incluye', 'No incluye'],
         ['App Android (APK) y PWA desde una sola base de código Flutter', 'Publicación en Google Play o en un dominio propio'],
         ['Acceso, registro con código por correo, recuperación de contraseña, roles USER y ADMIN', 'Passkeys en móvil'],
         ['Sesiones de enfoque, Explorar, favoritos, biblioteca propia e historial', 'Sensor de pulso real (la Tab S9 no tiene)'],
         ['Reloj y TV como apps Kotlin con BLE; wearable por TCP/IP', 'Cifrado de la carga útil BLE (bonding LE Secure Connections)'],
         ['Funciones de Soporte, mensajería, seguridad de la cuenta, directorio y citas, cada una con su almacenamiento', 'Funciones de Soporte (Firebase) verificadas dentro de la PWA'],
         ['Modo sin conexión, pruebas automatizadas, CI y blindaje de seguridad', 'Firma del APK con llave propia (se entrega con llave de depuración)']],
        [8.5, 8.5], 'Alcance del proyecto')
d.h2('1.8 Limitaciones')
d.viñetas([
    'Hardware disponible: un Galaxy S24 (central) y una Galaxy Tab S9 (Reloj y TV a la vez). Sin reloj físico con sensor: el pulso es simulado.',
    'Un solo desarrollador y un cuatrimestre: el plan inicial de 20 000 acciones del «usuario torpe» se recortó a 12 100.',
    'Uno de los proyectos de Firebase usados por Soporte pertenece a otra cuenta: su regla de presencia y la restricción de su clave no se pueden cambiar desde este proyecto.',
    'La PWA usa Web Bluetooth, disponible solo en Chrome y Edge; Firefox y Safari muestran un aviso.',
    'Las pruebas que exigen iniciar sesión en producción no se ejecutaron allí (no se escriben contraseñas reales en producción); se cubren en local con el mismo código.',
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
d.h1('2. Seguimiento de avances')
d.p('Cronología tomada del historial de git del repositorio público (42 commits del 11/11 al 25/11/2026) y, para la primera revisión, de la bitácora '
    '(`memoria/10 - Bitácora.md`), porque es anterior al repositorio.', alin='j')
d.h2('2.1 Cronología')
d.tabla([['Fecha', 'Avance', 'Commit / evidencia', 'Estado'],
         ['08/10', 'Primera revisión: app Flutter local sin base de datos, catálogo y sesiones; 11 pruebas.', 'Bitácora (anterior al repositorio)', 'Superado'],
         ['11/11', 'Línea base; plan de integración e inventario de prácticas; cada práctica con su propia BD; app conectada a la API real (NestJS + PostgreSQL); registro con correo; pruebas en el S24; caja blanca.', '7417fdf … aa5f34e, 4d68d88, 0cd2ce7', 'Cumplido'],
         ['18/11', 'Optimización, estrés y resiliencia (reintentos, idempotencia); central BLE y apps Reloj y TV probadas en S24 + Tab S9; Red Box de la API; memoria reestructurada; pruebas automatizadas, CI y repositorio público (PR #1).', '3860019, 8105d26, 1a8f98c, 7ed7df2, 546bf30, 77dd4fd', 'Cumplido'],
         ['19/11', 'Evidencias de CI; Soporte con 4 roles en dos equipos (TC01–TC08 aprobados).', '829919a, ec83dbf', 'Cumplido'],
         ['21/11', 'Sistema de diseño (paleta AA, claro y oscuro); prácticas convertidas en funciones de CEOSMOS; blindaje etapa 3 (contingencia, usuario torpe en la app); `entrega-v1`.', '2930619, 6bdfd5f, c431e0e, 7c6715e', 'Cumplido'],
         ['22/11', 'Blindaje: Red Box ampliado, API corregida en producción, 91 tamaños, red mínima, reconexión BLE con latido; 1.2.1 en los dos equipos; Reporte y Manual; `entrega-v2` a `entrega-v4`.', 'ce1d0d1, be6b0ba, 2167f30, c265ec7', 'Cumplido'],
         ['24/11', 'Revisión contra la rúbrica: PWA con service worker propio, modo sin conexión, Web Bluetooth, diagramas, cabecera de tabletas (1.3.0).', 'Trabajo local (sin commit ese día)', 'Cumplido'],
         ['25/11', 'Commit y CI de la 1.3.0; documentación final (este documento, Reporte, Manual, Matriz).', 'fc37eed; [CI en verde](' + CI_13 + ')', 'Cumplido; APK 1.3.0 sin instalar']],
        [1.5, 8.7, 4.3, 2.5], 'Cronología del proyecto (fechas de git)', tam=9)
d.h2('2.2 Hitos y versiones')
d.tabla([['Hito', 'Fecha', 'Commit', 'Contenido'],
         ['entrega-v1', '21/11', '7c6715e', 'Código de entrega del blindaje etapa 3: contingencia y usuario torpe dentro de la app'],
         ['entrega-v2', '22/11', 'ce1d0d1', 'Blindaje etapas 1 y 2: robustez, accesibilidad, tamaños, red, geografía y Red Box ampliado'],
         ['entrega-v3', '22/11', 'be6b0ba', 'Aislamiento del usuario torpe, verificación de producción y dependencias'],
         ['entrega-v4', '22/11', '2167f30', 'App 1.2.1: API en producción, reconexión BLE con latido; instalada en el S24 y la Tab S9'],
         ['1.3.0 (sin etiqueta)', '25/11', 'fc37eed', 'PWA con service worker propio, modo sin conexión y Web Bluetooth; CI en verde']],
        [3.2, 1.6, 2.0, 10.2], 'Etiquetas de entrega y versiones')
d.h2('2.3 Plan por parcial contra lo entregado')
d.tabla([['Parcial', 'Compromiso del plan', 'Resultado', 'Estado'],
         ['1.°', 'Proyecto Flutter unificado y UI de feeds visuales y auditivos', 'Una base de código para Android y web', 'Cumplido'],
         ['1.°', 'Conexión con la API REST y migración del acceso (correo y contraseña + passkeys)', 'Correo y contraseña, JWT y verificación por correo. Passkeys no: requieren assetlinks.json en un dominio propio', 'Parcial'],
         ['1.°', 'Modelos unificados en un esquema relacional con JSONB', '`metadata` de sesiones y `configuration` de dispositivos en JSONB', 'Cumplido'],
         ['2.°', 'Wearable con TCP/IP primario y BLE de respaldo', 'Cambió: BLE es el canal del Reloj y la TV; TCP/IP queda para un wearable en Wi-Fi (§3.2)', 'Cumplido con cambio'],
         ['2.°', 'Métricas en vivo y sincronizadas con el historial', 'Pulso y pasos en vivo y resumen en `metadata.wearable`; lecturas **simuladas**', 'Parcial'],
         ['3.°', 'PostgreSQL en producción, audio en segundo plano, carga diferida y caché LRU de 150–200 MB', 'Cumplido; en la PWA la caché es la del service worker (60 imágenes como máximo)', 'Cumplido'],
         ['3.°', 'Profiling y pruebas de integración de punta a punta', 'Estrés, profiling, prueba de integración crítica; 344 pruebas automatizadas', 'Cumplido'],
         ['Prácticas', 'Laboratorios de consumo de API, IoT, caché y profiling planteados en la propuesta', 'Integrados como funciones y como pruebas (ver Reporte de avances)', 'Cumplido']],
        [1.8, 5.2, 7.6, 2.4], 'Plan por parcial contra lo entregado', tam=9)
d.h2('2.4 Indicadores')
d.tabla([['Indicador', 'Valor vigente (25/11)', 'Evolución'],
         ['Pruebas Flutter', '344/344; análisis estático sin avisos', '11 (08/10) → 215 (18/11) → 331 (22/11) → 344 (24/11)'],
         ['Pruebas de la API (Jest)', '79/79', 'Sin cambios desde el 22/11'],
         ['Pruebas Kotlin', 'Reloj, TV y Companion: 14/14 cada una', '5 nuevas en las prácticas de automatización'],
         ['Cobertura de líneas', '56.0 % de toda la app; núcleo 84.8 %', '49.5 % (18/11) → 52.9 % / 78.9 % (22/11)'],
         ['Integración continua', '29 corridas: 27 en verde, 1 fallida, 1 cancelada; la de la 1.3.0 en verde', '[Corrida de la 1.3.0](' + CI_13 + ')'],
         ['Red Box', '13/13 original, 37/37 ampliado (local), 27/27 en producción', '27/37 antes de corregir 6 fallos'],
         ['Usuario torpe', '12 100 acciones sin cierres ni ANR', 'Plan de 20 000 no completado'],
         ['Tamaños de ventana', '91 sin desbordes', 'Barra lateral corregida el 22/11']],
        [3.6, 6.4, 7.0], 'Indicadores de calidad')
d.h2('2.5 Pendientes')
d.tabla([['Pendiente', 'Quién', 'Estado'],
         ['Instalar el APK 1.3.0 en el S24 y la Tab S9 (`adb install -r`, sin desinstalar)', 'Equipo de desarrollo', 'En curso (equipos no conectados el 24 y 25/11)'],
         ['Probar la PWA con Web Bluetooth contra el Reloj y la TV reales', 'Equipo de desarrollo', 'No verificado'],
         ['Publicar la PWA en un dominio propio (agregar el origen a CORS de la API)', 'Decisión del autor', 'Pendiente de decidir'],
         ['Passkeys en móvil (assetlinks.json en el dominio)', 'Autor', 'No cumplido'],
         ['Keystore propio para firmar el release', 'Autor', 'Riesgo aceptado'],
         ['Regla de presencia y restricción de clave del proyecto de Firebase ajeno', 'Dueño de ese proyecto', 'Pendiente del dueño'],
         ['Registro real con código por correo en producción (F-14)', 'Autor', 'No verificado'],
         ['Segunda cuenta de usuario de Soporte con 1.2.1 o posterior', 'Autor', 'No verificado'],
         ['Capturas reales de Explorar, Perfil (parte superior), Administración y la PWA instalada en el teléfono para el Manual', 'Autor con los equipos', 'En curso'],
         ['Ocultar el botón ⓘ «Referencia académica» (`mostrarReferenciasAcademicas = false`) si así se decide para la entrega', 'Autor', 'Pendiente de decidir']],
        [9.0, 3.4, 4.6], 'Pendientes al 25/11/2026')

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
       ['22/11', 'Versiones release apuntan a producción por defecto', 'Exigir la URL al compilar', 'Un release sin URL apuntaba al emulador', 'Prueba de la regla de URL', 'memoria/13'],
       ['22/11', 'Entregar el APK con la llave de depuración (riesgo aceptado)', 'Keystore propio', 'Con otra firma hay que desinstalar (se pierden datos) y registrar su SHA-1 en Firebase', 'Instalación encima conservando datos', 'memoria/13'],
       ['24/11', 'Service worker propio (`sw.js`)', 'El de Flutter', 'El de Flutter 3.41 se desregistra solo: sin modo sin conexión', 'La PWA abre sin red', 'fc37eed'],
       ['24/11', 'Modo sin conexión: perfil y pendientes en el equipo; token en almacén seguro', 'Exigir red para abrir', 'Una sesión terminada sin red se perdía al cerrar la app', 'Sesión enviada una sola vez al volver la red', 'fc37eed'],
       ['24/11', 'PWA servida en `localhost:4200` para la demostración', 'Dominio propio', 'Origen ya admitido por CORS y contexto seguro', 'Un dominio exige tocar CORS', 'memoria/14'],
       ['24/11', 'Pulso del Reloj simulado y declarado como límite', 'Reloj Wear OS con sensor', 'La tablet no tiene sensor; código de sensores sin hardware para probar era un riesgo', 'Límite declarado', 'memoria/09']]
d.tabla(dec, [1.3, 3.5, 2.8, 3.6, 3.2, 2.0], 'Registro de decisiones técnicas', tam=8)
d.h2('3.2 Cambios de plan')
d.viñetas([
    '**De TCP/IP a BLE.** El plan ponía TCP/IP como transporte primario por la inestabilidad del BLE del cuatrimestre anterior. Este cuatrimestre, con el S24 como central y periféricos GATT nativos en Kotlin en la Tab S9, el enlace fue estable; BLE pasó a ser el canal principal y TCP/IP la alternativa.',
    '**Reloj y TV nativos, no PWA.** Web Bluetooth solo puede actuar como central; una TV que anuncia y sirve GATT tiene que ser nativa. Las dos apps conviven en la tablet.',
    '**Rediseño y reubicación de las prácticas.** El 21/11 se aplicó un sistema de diseño único y las prácticas dejaron de vivir en una ventana «Prácticas»: ahora son funciones con nombre propio en Soporte, Equipos y Perfil (detalle en el Reporte de avances).',
    '**Firestore → API propia.** La base de CEOSMOS es la de la API NestJS + PostgreSQL; Firestore se conserva solo para las funciones de Soporte.',
    '**PWA con service worker propio y modo sin conexión** (24/11), porque el de Flutter 3.41 no daba funcionamiento sin red.',
])
d.h2('3.3 Incidentes y lecciones aprendidas')
d.tabla([['Fecha', 'Incidente', 'Cómo se corrigió', 'Lección'],
         ['18/11', 'La TV reiniciada seguía marcando «Conectado» y rechazaba cada proyección (DEF-BLE-01)', 'Reautenticación al recibir «sin autorización»; prueba de regresión que falla con el código viejo', 'Todo defecto de hardware queda con su prueba automática'],
         ['18/11', 'Un secreto antiguo estaba en el historial de git antes de publicar el repositorio', 'Historial redactado antes de publicar; secretos rotados el 22/11; análisis de secretos sin hallazgos de servidor', 'Revisar el historial antes de hacer público un repositorio'],
         ['21/11', 'Corrida de CI fallida: el análisis estático marcó un aviso en el arnés de capturas de `tool/`', 'Corregido en 0f30c8c; la siguiente corrida pasó', 'Correr `flutter analyze` también tras tocar herramientas'],
         ['22/11', '**Una prueba de estrés («usuario torpe») desinstaló la app real del S24 y de la tablet**: su aislamiento no se aplicó y se perdieron los datos locales de los equipos (no los de la nube)', 'Copia aislada con archivo marcador, comprobación del paquete antes de correr y alarma si la app real se reinstala; desde entonces cada versión se instala encima (be6b0ba)', 'Nunca ejecutar pruebas en un equipo sin confirmar el paquete; probar el aislamiento antes que la prueba'],
         ['22/11', 'Un release compilado sin URL apuntaba al emulador (10.0.2.2)', 'Producción por defecto en release y prueba de la regla', 'Los valores por defecto deben ser los de producción'],
         ['22/11', 'Reloj y TV en «Conectado» con lecturas congeladas tras reiniciar sus apps', 'Latido cada 5 s y reautenticación sin PIN (1.2.1)', 'Un enlace físico vivo no significa sesión viva'],
         ['22/11', 'El Red Box ampliado halló 6 fallos en la API (500 ante CORS ajeno o JSON anidado, sin CSP, enlaces javascript:, login que revelaba cuentas)', 'Corregidos y desplegados a producción; 27/27 allí', 'Atacar también producción, sin credenciales y a baja tasa'],
         ['22/11', 'Un toque automatizado con coordenadas viejas pulsó «Cerrar sesión» en un equipo', 'Volver a leer la pantalla antes de cada toque', 'No reutilizar coordenadas entre pantallas'],
         ['24/11', 'El service worker de Flutter 3.41 se desregistra solo: la PWA no abría sin red', '`web/sw.js` propio con precarga versionada', 'Verificar el modo sin conexión de punta a punta, no solo la instalación']],
        [1.4, 5.0, 5.6, 5.0], 'Incidentes y lecciones aprendidas', tam=8.5)

# ======================= 4. B1 =======================
d.h1('4. Diseño y arquitectura')
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
d.h2('4.7 Resumen de seguridad')
d.viñetas([
    '**Acceso:** JWT HS256 validado en forma; token en Keystore (almacén seguro); mensaje de error genérico; bloqueo por intentos; límite de peticiones.',
    '**Autorización:** roles USER y ADMIN en la API, datos filtrados por usuario (IDOR probado); reglas de Firestore por cuenta y rol en Soporte.',
    '**Transporte:** HTTPS con TLS 1.2+ y HSTS; certificado no confiable rechazado con mensaje claro; CSP `default-src none` en la API.',
    '**Bluetooth:** reto + HMAC con PIN; la carga útil no va cifrada (**riesgo aceptado**).',
    '**PWA:** el service worker nunca guarda respuestas de la API ni de Firebase; la copia sin conexión no guarda contraseña ni token y se borra al cerrar sesión.',
    'Detalle de ataques y resultados (Red Box, MASVS) en el Reporte de avances › Blindaje.',
])

# ======================= 5. B2 =======================
d.h1('5. Interfaz y experiencia de usuario')
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
    'TalkBack de punta a punta con usuarios reales: **no verificado** (cubierto por pruebas automáticas y recorridos manuales).',
])
d.h2('5.5 Decisiones de UX surgidas de las pruebas como usuario novato')
d.tabla([['Hallazgo', 'Decisión'],
         ['El botón Atrás cerraba la app dentro de algunas funciones (Android 16/17)', 'Atrás regresa a la sección anterior; prueba de navegación'],
         ['El diálogo «Agregar a mi biblioteca» se desbordaba con entradas al azar (usuario torpe)', 'Contenido desplazable; prueba de regresión'],
         ['El avatar quedaba a media cabecera en tabletas', 'Cabecera con Expanded + Align (24/11)'],
         ['Permiso de Bluetooth denegado sin salida clara', 'Mensaje con la ruta exacta en Ajustes, botón «Reintentar» y «Olvidar» el PIN'],
         ['Terminar una sesión por accidente', 'Confirmación antes de terminar'],
         ['Errores técnicos crudos (certificado, red)', 'Mensajes en lenguaje claro con qué hacer'],
         ['Textos de «Práctica», «P#» o «Examen» visibles', 'Nombres funcionales; prueba que impide que vuelvan a aparecer'],
         ['Al abrir hay que pulsar «Conectar» para el Reloj y la TV', 'Límite aceptado: no pide el PIN otra vez y las caídas en uso se reconectan solas']],
        [8.0, 9.0], 'Decisiones de UX tomadas a partir de pruebas')
d.h2('5.6 Capturas reales')
d.figuras_lado([E('manual', 'm_inicio.png'), E('manual', 'm_equipos_conectados.png'), E('manual', 'm_soporte.png')],
               'Inicio, Equipos con Reloj y TV conectados y Soporte en el Galaxy S24 (app Android 1.2.1)', 9.0,
               'Capturas del teléfono: pantalla de Inicio, pestaña Equipos con Reloj y TV conectados y pestaña Soporte')
d.figuras_lado([E('pwa', 'movil_412x860.png'), E('pwa', 'tableta_820x1180.png')],
               'La PWA en teléfono (412 × 860) y en tableta (820 × 1180), Chromium', 8.5,
               'La misma pantalla de la PWA en tamaño de teléfono y de tableta')
d.figura(E('pwa', 'escritorio_1280x800.png'), 'PWA en escritorio (1280 × 800): la navegación pasa a una barra lateral', 14.0)
d.p('Faltan capturas reales en el teléfono de Explorar, Perfil (parte superior), Administración y la PWA instalada: los equipos no estuvieron '
    'conectados el 24 ni el 25/11 (**en curso**).', alin='j')

# ======================= 6. C–E =======================
d.h1('6. Resumen técnico por bloque de la rúbrica')
d.p('Resumen breve; la evidencia completa está en la Matriz de cumplimiento (`evidencias/rubrica/Matriz de cumplimiento - CEOSMOS.pdf`) y en el '
    'Reporte de avances.', alin='j')
d.h2('6.1 Aplicación web progresiva (PWA)')
d.tabla([['Elemento', 'Implementación', 'Verificación'],
         ['Manifiesto', '`web/manifest.json`: id, scope, start_url, display standalone (+ window-controls-overlay, minimal-ui), íconos 192/512 normales y maskable, theme #5B011D, capturas narrow y wide, atajos Explorar y Equipos, es-MX', 'Chrome: 0 errores de instalabilidad (24/11); `test/pwa_test.dart`'],
         ['Service worker', '`web/sw.js` propio: precarga del app shell (31 archivos, 19.1 MB) con versión por hash; navegación red primero; archivos propios caché primero; API, Firebase y no-GET nunca; imágenes externas máx. 60', 'Activo y controlando; al cambiar la versión se borra la caché anterior'],
         ['Sin conexión', 'Perfil público y sesiones pendientes en el equipo (`lib/data/cache_sin_conexion.dart`); reconexión con espera progresiva', 'Sesión terminada sin red enviada una sola vez al volver la red; `test/sin_conexion_test.dart`'],
         ['Responsivo', 'Barra inferior ↔ barra lateral; 91 tamaños de 240 a 1600 dp', '`test/tamanos_pantalla_test.dart`; figuras 6 y 7'],
         ['Instalación', 'Chrome o Edge › «Instalar CEOSMOS»; en Android menú ⋮ › «Instalar app»', 'Escritorio verificado; PWA instalada en el teléfono: **no verificado**']],
        [2.8, 8.6, 5.6], 'Resumen de la PWA', tam=9)
d.h2('6.2 Dispositivos inteligentes')
d.tabla([['Aspecto', 'Resumen', 'Estado'],
         ['Comunicación', 'BLE GATT S24 ↔ Tab S9 (Reloj y TV) con reto + HMAC; TCP/IP para un wearable en Wi-Fi; Web Bluetooth en la PWA', 'Android probado en hardware; Web Bluetooth **no verificado en hardware** (solo se abrió el selector en Chromium)'],
         ['Sensores y capacidades', 'Radio BLE, botón del Reloj, D-pad de la TV, vibración, notificaciones, servicio en primer plano, audio en segundo plano, Keystore', 'Reales y probados'],
         ['Pulso y pasos', 'Generados por la app Reloj con el formato de un reloj real', '**Simulados** (la tablet no tiene sensor de frecuencia cardiaca)'],
         ['Intercambio de datos', 'JSON ≤ 180 bytes validado, 20 msg/s, pulso 30–230 bpm; resumen en `metadata.wearable`; equipos en `/devices` con `CE:05:<id>`', 'Probado; 4 pruebas de regresión de reconexión'],
         ['Permisos y compatibilidad', 'Android 12+: BLUETOOTH_SCAN y CONNECT; ≤ 11: ubicación; periféricos: ADVERTISE; PWA: selector de Web Bluetooth; Firefox y Safari: aviso', 'Android 12+ probado (permiso denegado → mensaje y Ajustes); Android ≤ 11 declarado, **no probado**']],
        [3.2, 8.4, 5.4], 'Resumen de la integración con dispositivos', tam=9)
d.h2('6.3 Seguridad y calidad')
d.tabla([['Aspecto', 'Resumen'],
         ['Autenticación y protección', 'JWT HS256, Keystore, Red Box 13/13 y 37/37 en local y 27/27 en producción sin credenciales; HMAC en BLE; mapa MASVS'],
         ['Pruebas', '344 Flutter, 79 API, 42 Kotlin; cobertura 56.0 % (núcleo 84.8 %); análisis estático sin avisos'],
         ['Integración continua', 'GitHub Actions en cada push y PR: Flutter, PWA y Kotlin (Reloj, TV, Companion); [corrida de la 1.3.0 en verde](' + CI_13 + ')'],
         ['Rendimiento y recuperación', 'Reintentos con espera exponencial, sesiones idempotentes, modo sin conexión, red mínima de 5 kbps o RTT de 4 s, usuario torpe de 12 100 acciones, plan de contingencia de 1.9 a 2.4 min por fallo']],
        [4.0, 13.0], 'Resumen de seguridad y calidad')

# ======================= 7 =======================
d.h1('7. Conclusiones, riesgos y trabajo futuro')
d.h2('7.1 Conclusiones')
d.p('El objetivo general se cumplió en lo esencial: un solo código Flutter funciona como app Android y como PWA instalable, usa la misma API y la '
    'misma base que CEOSMOS WEB, se comunica por Bluetooth LE autenticado con el Reloj y la TV y no pierde sesiones sin conexión. Quedan dos '
    'objetivos parciales (pulso simulado y Web Bluetooth no verificado en hardware) y uno no cumplido (passkeys en móvil), dichos tal cual. '
    'El proceso dejó 344 pruebas automatizadas, una integración continua en verde y una API corregida en producción tras atacarla.', alin='j')
d.h2('7.2 Limitaciones y riesgos aceptados')
d.viñetas([
    'Carga útil BLE sin cifrar (riesgo aceptado); SQLite y almacenamiento local sin cifrar, sin credenciales (riesgo aceptado).',
    'APK firmado con llave de depuración (riesgo aceptado); limitador de peticiones en memoria por instancia (riesgo aceptado).',
    'Pulso y pasos simulados (límite); Web Bluetooth, PWA instalada en el teléfono, F-14, segunda cuenta de Soporte y tercer teléfono sin PIN: no verificados.',
    'Datos alojados en EE. UU. sin aviso RGPD formal (no aplica al uso académico).',
])
d.h2('7.3 Trabajo futuro')
d.viñetas([
    'Instalar la 1.3.0 en los equipos y probar Web Bluetooth con el Reloj y la TV reales.',
    'Publicar la PWA en un dominio propio (CORS) y, con él, passkeys en móvil (assetlinks.json).',
    'Leer pulso real de un reloj Wear OS; BLE con bonding cifrado (LE Secure Connections).',
    'Keystore propio, limitador de peticiones en Redis y aviso de privacidad.',
])
d.h2('7.4 Referencias')
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

d.h1('Anexo A. Matriz de trazabilidad de la rúbrica')
tr = [['Criterio', 'Documento y sección', 'Evidencia', 'Estado documental'],
      ['A1 Planteamiento y justificación', 'Seguimiento §1', 'memoria/01, 02', 'Cubierto'],
      ['A2 Seguimiento de avances', 'Seguimiento §2', 'git log, tags, memoria/10, cifras.md', 'Cubierto'],
      ['A3 Decisiones y cambios', 'Seguimiento §3', 'memoria/09, commits citados', 'Cubierto'],
      ['B1 Arquitectura', 'Seguimiento §4', 'evidencias/diagramas/*.png, tool/diagramas/', 'Cubierto'],
      ['B2 Interfaz y UX', 'Seguimiento §5; Manual de usuario', 'memoria/11, evidencias/manual, evidencias/pwa', 'Cubierto (faltan 4 capturas en el teléfono)'],
      ['C1 Funcionamiento PWA', 'Seguimiento §6.1; Matriz C1', 'evidencias/pwa/', 'Cubierto (Chromium)'],
      ['C2 Manifiesto', 'Seguimiento §6.1', 'web/manifest.json, test/pwa_test.dart', 'Cubierto'],
      ['C3 Service worker y sin conexión', 'Seguimiento §6.1', 'web/sw.js, test/sin_conexion_test.dart, evidencias/pwa/01–04', 'Cubierto'],
      ['C4 Responsivo e instalable', 'Seguimiento §5, §6.1', 'test/tamanos_pantalla_test.dart', 'Parcial (instalación en el teléfono no verificada)'],
      ['D1 Comunicación', 'Seguimiento §4.5, §6.2', 'evidencias/ble_*.png', 'Cubierto en Android; Web Bluetooth no verificado'],
      ['D2 Sensores', 'Seguimiento §6.2', 'Reporte › Riesgos', 'Parcial (pulso simulado, declarado)'],
      ['D3 Intercambio y procesamiento', 'Seguimiento §4.5, §6.2', 'lib/core/ble/, test/ble/', 'Cubierto'],
      ['D4 Permisos y compatibilidad', 'Seguimiento §6.2', 'evidencias/ble_11_*, ble_12_*', 'Cubierto (Android ≤ 11 no probado)'],
      ['E1 Protección y autenticación', 'Seguimiento §4.7; Reporte §4', 'evidencias/blindaje/masvs.md, redbox_*.txt', 'Cubierto'],
      ['E2 Pruebas y validación', 'Reporte §3; Prácticas 13-14', 'test/, .github/workflows/ci.yml, CI', 'Cubierto'],
      ['E3 Rendimiento y recuperación', 'Reporte §4', 'evidencias/blindaje/red, mono', 'Cubierto'],
      ['F1 Demostración', 'Matriz › Guion de 8 min', 'evidencias/blindaje/Lista de verificacion previa', 'Cubierto (ensayo pendiente del autor)'],
      ['F2 Dominio técnico', 'Hoja de defensa; Matriz › Preguntas', 'evidencias/blindaje/Hoja de defensa', 'Cubierto']]
d.tabla(tr, [4.0, 4.4, 5.4, 3.2], 'Trazabilidad: criterio de la rúbrica → documento, sección y evidencia', tam=8.5)

d.h1('Anexo B. Enlaces', salto=False)
d.viñetas([
    f'Repositorio: [{REPO}]({REPO})',
    f'Integración continua (todas las corridas): [{REPO}/actions]({REPO}/actions)',
    f'Corrida de la versión 1.3.0: [{CI_13}]({CI_13})',
    f'Corrida de entrega-v4 (1.2.1): [{CI_V4}]({CI_V4})',
    'API de producción (salud): [https://ceosmos-api.vercel.app/api/health](https://ceosmos-api.vercel.app/api/health)',
    'Cifras vigentes: `evidencias/documentacion/cifras.md`',
])

salida = os.path.join(R, 'Documento de seguimiento del proyecto - CEOSMOS.docx')
d.guardar(salida)
print(salida)
