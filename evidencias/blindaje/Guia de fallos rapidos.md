# Guía de fallos rápidos · CEOSMOS

Una línea por paso: **falló X → dónde mirar → cómo corregir → cómo verificar → cómo subir**.
Script base (cronometra cada paso, instala en los 2 equipos sin borrar datos y muestra el logcat de la app):

```bash
bash scripts/arreglo_rapido.sh <area> [segundos_logcat]                                # Git Bash
powershell -ExecutionPolicy Bypass -File scripts\arreglo_rapido.ps1 -Area <area>       # PowerShell
```

Áreas: `login`, `red`, `ble`, `soporte`, `reportes`, `directorio`, `mensajeria`, `incidencias`, `seguridad`, `navegacion` y `todo`.
Para subir cualquier arreglo, siempre igual: `git add -A && git commit -m "Arreglo: <qué>" && git push origin main && gh run watch`.
Para volver a la versión entregada: `git checkout entrega-v1` (o instalar `release\CEOSMOS-entrega-v1-release-llave-depuracion.apk`).

| Falló | Dónde mirar | Cómo corregir | Cómo verificar | Área del script |
|---|---|---|---|---|
| **La app no llega a producción** (todo da «No hay conexión» aunque /api/health responde) | `powershell -File scripts\verificar_produccion.ps1 -Serial <serial>` (correo inexistente → debe decir «Correo o contraseña incorrectos.») · URL en `lib/core/config.dart` | Compilar con `--dart-define=CEOSMOS_API_URL=https://ceosmos-api.vercel.app/api` (el release ya usa producción por defecto) o reinstalar `release\CEOSMOS-entrega-v4-release-llave-depuracion.apk` | «VERIFICACION OK» (paso 6 de `arreglo_rapido`) | `red` |
| **Red**: «Sin conexión» o la app tarda mucho | `curl -s -o /dev/null -w "%{http_code} %{time_total}\n" https://ceosmos-api.vercel.app/api/health` · `lib/data/api_client.dart` (timeout de 15 s) · `lib/core/reintentos.dart` | Si la API da 5xx, es del servidor (Vercel/Neon): esperar o reintentar. Si la API da 200, revisar `timeout` y `PoliticaReintento` | La etiqueta «Sincronizado» aparece en Inicio. Pruebas: `flutter test test/whitebox/wb_comunicacion_test.dart test/p12` | `red` |
| **Login**: no entra o el mensaje es incorrecto | `lib/ui/auth_screen.dart`, validadores en `lib/data/auth_repository.dart`, mensajes del servidor traducidos en `api_client.dart` | Ajustar el validador o el mensaje, nunca la regla del servidor | `flutter test test/widget_test.dart test/whitebox/wb_validacion_test.dart`, y entrar con la cuenta QA | `login` |
| **BLE**: «Conectado» pero el pulso no cambia (se cerró la app Reloj o TV) | Contador de lecturas en Equipos · registro de la app Reloj/TV («esperando PIN») | Desde 1.2.1 se reautentica solo en ~4 s (latido). En 1.2.0: *Desconectar* y *Conectar* (no pide PIN) | Lecturas avanzando | `ble` |
| **BLE**: el Reloj o la TV no conectan | Equipos › tarjeta del Reloj/TV (mensaje de error) · `adb -s <serial> logcat -s flutter` · `lib/core/ble/ecosistema_ble.dart` | `ANDROID_SPECIFIC_ERROR` o «no expone el servicio»: abrir la app Reloj/TV **antes** y tocar *Reintentar* (es transitorio). Sin permiso: Ajustes › Apps › CEOSMOS › Permisos › Dispositivos cercanos | Estado «Conectado» y lecturas en bpm. `flutter test test/ble` | `ble` |
| **Firestore**: Soporte o Reportes no cargan | Banner «Sin conexión» dentro de la función · `adb logcat -s flutter FirebaseFirestore` · consola de Firebase del proyecto de esa función | Sin red: esperar (la escritura se sincroniza sola). `PERMISSION_DENIED`: la cuenta no tiene documento de rol (Soporte) o no es su incidencia (Mis incidencias): es el comportamiento esperado | Crear un reporte en un equipo y verlo en el otro | `soporte` / `reportes` |
| **Permisos** (Bluetooth, notificaciones, archivos) | Diálogo del sistema · Ajustes › Apps › CEOSMOS › Permisos | Concederlos. Si se negaron «siempre», abrir Ajustes desde la tarjeta del aviso | El aviso desaparece de la tarjeta | `ble` |
| **Formularios** (campo vacío, texto raro, desborde) | La pantalla de la función · validadores de su carpeta en `lib/practicas/<función>/` | Agregar o ajustar el validador y escribir la prueba del caso | `flutter test test/practicas/<función>` | `directorio` / `incidencias` / `seguridad` |
| **Pantalla** desbordada (franjas amarillas o texto cortado) | La pantalla en ventana flotante; mínimo funcional medido: **320 × 560 dp** | Envolver en `Flexible`/`Expanded` o reducir a la variante compacta | `flutter test test/widget_test.dart` (prueba sin desbordes a 280, 320, 768 y 1440 px) | `navegacion` |
| **La app se cierra** (crash) | `adb -s <serial> logcat -b crash -d` | Corregir la excepción y escribir su prueba de regresión | El usuario torpe dentro de la app: `flutter test integration_test/mono_usuario_test.dart -d <serial>` | `todo` |
