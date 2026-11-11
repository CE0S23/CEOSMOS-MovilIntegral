# Prácticas integradas en CEOSMOS

Cada práctica conserva su código y su lógica tal como se entregaron. Las únicas
modificaciones están marcadas en el código con `[CEOSMOS]` y se listan aquí.

| ID | Origen | Dónde vive en CEOSMOS | Cómo se abre |
| --- | --- | --- | --- |
| `p03_04` | `practica_3_4/lib` | `lib/practicas/p03_04/` | Ruta Flutter con su `MaterialApp` |
| `p05` | `practicas5y6/Practica_5_AccesoSeguro` | `lib/practicas/p05/` + `android/.../practicas/p05/AccesoSeguroChannel.kt` | Ruta Flutter |
| `p06` | `practicas5y6/Practica_6_MobileConnect` | `lib/practicas/p06/` + `android/.../practicas/p06/` | Ruta Flutter |
| `examen1` | `AppExamen1/incidencias_app/lib` | `lib/practicas/examen1/` | Ruta Flutter |
| `p07` | `practica7/lib` | `lib/practicas/p07/` | Ruta Flutter (`Practica7Entrada`) |
| `bd_flutter` | `reportes_flutter` | `lib/practicas/bd_flutter/` + `android/.../practicas/bdflutter/` | Ruta Flutter |
| `bd_nativo` | `firestore_reportes_android/app` | `android/.../practicas/bdnativo/` | Actividad Android |
| `p09` | `PRACTICA 9 - DMI.zip` | `android/.../practicas/p09/` | Actividad Android (Compose) |
| `p10` | `PRACTICA 10 - DMI.zip` | `android/.../practicas/p10/` | Actividad Android (Compose) |
| `eval2` | `Evaluacion2/mediconnect/mobile/lib` | `lib/practicas/eval2/` | Ruta Flutter |

`android/...` = `android/app/src/main/kotlin/com/ceosmos/practicas`.

## Contenedor común

- `registro_practicas.dart`: lista de prácticas (número, nombre, descripción, stack, BD).
- `practicas_screen.dart`: ventana «Prácticas».
- `practica_host.dart`: barra «← Prácticas» + la app de la práctica con su propio
  `MaterialApp` (Navigator, tema y estado propios). El botón Atrás de Android se
  reenvía primero al navegador interno de la práctica.
- `BarraPracticas.kt`: misma barra para las actividades nativas, insertada al
  crearse la actividad sin modificar su código.
- `FirebasePracticas.kt`: apps de Firebase con nombre para las prácticas nativas.

## Adaptaciones por práctica

### P3-4 ConsultaWeb
- `main.dart`: la base SQLite se llama `p03_04_usuarios.db` (antes `usuarios.db`).
- Pruebas: imports `package:consultaweb/…` → `package:ceosmos_movil_integral/practicas/p03_04/…`.

### P5 AccesoSeguro
- `MainActivity.kt` → `AccesoSeguroChannel.kt`: deja de heredar de
  `FlutterActivity`; `configureFlutterEngine` pasa a `register(messenger)`.
  Canal `acceso_seguro/login` y validaciones sin cambios. Paquete
  `com.ceosmos.practicas.p05`.

### P6 MobileConnect
- `MainActivity.kt` → `MobileConnectChannels.kt`: recibe el `Context` de la
  actividad de CEOSMOS (`getSystemService` → `context.getSystemService`);
  `onDestroy` → `dispose()` (lo llama `MainActivity` de CEOSMOS). Canales
  `mobile_connect/network` y `mobile_connect/events` sin cambios.
  `TcpChatTransport.kt` y `ConnectionFailure.kt` solo cambian de paquete.
- `chat_session.dart`: llaves en un `if` (lint, misma lógica).
- Pruebas: se incluye `local_network_test.dart`. `chat_session_test.dart` y
  `conversation_page_test.dart` ya fallaban en el proyecto original (11 de 21
  casos, esperan textos que su código ya no tiene; su README indica que la
  última revisión no se probó) y no se incluyeron para no alterar la lógica.

### Examen 1 Incidencias
- `main.dart`: la clave de SharedPreferences es `examen1.incidencias` (antes
  `incidencias`) para no compartir el almacén común de la app. La prueba se
  ajustó a la nueva clave.

### P7 Sistema de tickets
- `firebase_p07.dart` (nuevo): app de Firebase con nombre `practica7` con los
  valores de su `google-services.json`; persistencia de Firestore igual que el
  original. Como CEOSMOS no tiene app `[DEFAULT]`, se registra el delegado base
  de `cloud_firestore` con la app de la práctica.
- `services/*.dart`: `FirebaseAuth.instance` / `FirebaseFirestore.instance` →
  `FirebaseP07.auth` / `FirebaseP07.db`. Se quitaron dos imports sin uso.
- `main.dart`: `main()` usa la app con nombre; se agrega `Practica7Entrada`
  (misma inicialización que `main()` y libera `AuthService` al salir).

### Reportes Firestore (Flutter + Kotlin)
- `MainActivity.kt` → `ReportesFirestoreChannel.kt` (mismo patrón que P5) y
  `FirebaseApp.initializeApp(context)` → `FirebasePracticas.app(context, "bd_flutter")`;
  `FirebaseAuth`/`FirebaseFirestore.getInstance(app)`.
- `FirestoreReportes.kt` y `Reporte.kt`: solo paquete
  `com.ceosmos.practicas.bdflutter`.

### Reportes Firestore (nativo)
- `MainActivity.kt`: app de Firebase con nombre `bd_nativo` en lugar de
  `[DEFAULT]`. Paquete `com.ceosmos.practicas.bdnativo`. Interfaz sin cambios.

### P9 Incidencias compartidas
- Paquete `com.ceosmos.practicas.p09` (P9 y P10 usaban el mismo paquete).
- `IncidenciasViewModel.kt`: SharedPreferences `p09_local` (antes `local`);
  `Repositorio` recibe `FirebaseFirestore.getInstance(app «p09»)`.
- `Repositorio.kt`: proyecto/appId se leen de `db.app` en lugar de `[DEFAULT]`.

### P10 Incidencias seguras
- Paquete `com.ceosmos.practicas.p10`.
- `IncidenciasViewModel.kt`: SharedPreferences `p10_local`.
- `Repositorio.kt`: `FirebaseAuth`/`FirebaseFirestore.getInstance(app «p10»)`.

### Evaluación 2 MediConnect
- `api_client.dart`: `(_, __, ___)` → `(_, _, _)` (lint de Dart 3, mismo efecto).
- Sin cambios de URL: el certificado fijado solo es válido para
  `localhost`/`127.0.0.1`; en el emulador se usa `adb reverse tcp:3443 tcp:3443`.
- Su `flutter_secure_storage` sigue usando el almacén por defecto; CEOSMOS
  guarda su token en un espacio de nombres propio, así que el `deleteAll()` de
  MediConnect no afecta la sesión de CEOSMOS.

## Dependencias unificadas

- `intl: ^0.20.2` (MediConnect pedía `^0.20.3`; `flutter_localizations` fija 0.20.2).
- `flutter_secure_storage: ^10.3.4` (la 11.x exige `win32` 6 y choca con `file_picker` 10 de P7).
- Firebase Android BoM 34.19.0 (la de FlutterFire); Compose BoM 2024.12.01 (P9/P10).
- `cloud_firestore_platform_interface` explícito para el delegado de P7.
