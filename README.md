# CEOSMOS · Móvil Integral

Aplicación Flutter para la **primera revisión de Desarrollo Móvil Integral**, creada a partir del reporte de avances y las memorias de CEOSMOS Web, Flutter y la arquitectura integral.

## Ejecutar

Requiere Flutter 3.41.9 / Dart 3.11.5 o una versión compatible.

```powershell
cd C:\CESAR10cuatri\CEOSMOS.MovilIntegral
flutter pub get
flutter run -d chrome
```

Para Android, conecta un teléfono con depuración USB o inicia un emulador:

```powershell
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`. Las carpetas iOS y Windows también están generadas; para compilarlas se necesitan macOS/Xcode y Visual Studio con C++, respectivamente.

## Entrar a la app

Pulsa **Explorar demo**: no requiere correo, contraseña ni servicios externos. También puedes crear una cuenta local y después entrar con ese correo y contraseña, mientras no cierres/reinicies la aplicación.

**No hay base de datos, Firebase ni llamadas a servidores.** Cuentas, favoritos, preferencias, historial y dispositivos se conservan únicamente en memoria. Cerrar sesión no borra el espacio de cada usuario; reiniciar la aplicación sí. No uses contraseñas personales reales en una demostración.

## Incluido

- Identidad cósmica común, interfaz en español y diseño adaptable: barra inferior móvil y navegación lateral en escritorio.
- Registro, inicio/cierre de sesión y validación de errores locales; sesión de acceso con caducidad de dos horas.
- Inicio con modos de concentración, relajación e inspiración.
- Catálogo de seis experiencias, búsqueda sin distinción de acentos, filtros combinables y favoritos por cuenta.
- Tres paisajes adicionales y tres bucles MP3 originales de 30 segundos. Todos los paisajes se dibujan en Flutter y todos los audios están incluidos.
- Sesiones de 5, 15, 25 y 45 minutos, pausa, continuación, finalización automática y manual, historial y preferencia de duración.
- Un solo reproductor de audio global, control de volumen y mensajes de error. El audio se activa explícitamente desde Mi sesión.
- Barra de sesión activa al navegar; temporizador basado en tiempo transcurrido, que no cuenta las pausas.
- Vista del ecosistema con vinculación/desvinculación **simulada** de Band y TV, métricas ficticias identificadas y vista previa de la sesión en TV.
- Modelos separados de usuario, acceso autenticado, sesión de enfoque, contenido y dispositivo vinculado, con contratos JSON.

## Alcance real respecto al Word

El Word también plantea conectar NestJS/PostgreSQL y migrar JWT/WebAuthn en el primer parcial. Por la indicación de desarrollar **sin base de datos por ahora**, esos puntos se documentan como pendientes: esta app entrega la base y los flujos locales, **no acredita todavía la integración real con producción**. Las passkeys muestran una explicación; no simulan una verificación biométrica.

Consulta [la matriz de entrega](docs/PRIMERA_REVISION.md), [la arquitectura y contratos](docs/ARQUITECTURA.md) y [el guion de presentación](docs/DEMO.md).

## Estructura

```text
lib/
  main.dart                   Arranque
  app.dart                    App, navegación y composición
  domain/models.dart          Contratos unificados
  data/auth_repository.dart    Interfaz de auth + implementación en memoria
  data/catalog.dart           Catálogo y búsqueda única
  core/app_state.dart         Estado, cuentas, sesiones y dispositivos
  core/sound_controller.dart  Único reproductor de audio
  ui/                         Pantallas, widgets y tokens Cosmos
assets/audio/                 Audios MP3 propios, sin red
scripts/                      Generación reproducible de audios
test/                         Pruebas de lógica y recorridos de interfaz
docs/                         Alcance, decisiones y guion
```

## Verificar

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

Para la Práctica 8, ejecuta `powershell -File scripts/practica8_blackbox.ps1`.
El script corre 21 verificaciones de caja negra y genera JSONL, CSV y un
reporte en `docs/evidencias/practica8/`.

La compilación web incluye CanvasKit local para evitar su descarga desde CDN. Para abrir `build/web` usa un servidor HTTP, por ejemplo `python -m http.server 8080 --directory build/web`, y visita `http://localhost:8080`. La app no necesita una API; la versión web debe haberse servido antes de utilizarla y no implementa instalación/caché PWA offline persistente.

## Límites deliberados

- Los paisajes son ilustraciones vectoriales generadas por código; no se descargan imágenes externas.
- No existe carga de archivos, caché LRU, notificaciones ni audio de fondo. El audio se detiene al ocultar la app; el temporizador se recalcula al volver.
- Los bucles tienen entrada/salida suave y no equivalen a canciones completas o grabaciones naturales.
- Sin conexiones TCP/IP/BLE físicas, sensores reales ni sincronización entre equipos.
- La autenticación en memoria es educativa: guarda resúmenes con sal en RAM, no tokens JWT ni credenciales en disco. No sustituye al servidor de autenticación.
- El APK debug es para revisión académica; una distribución pública requiere firma de producción y las integraciones pendientes.

