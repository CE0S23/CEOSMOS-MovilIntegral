# Adenda 1.4.0 · CEOSMOS Móvil Integral (26/11/2026)

Complementa los documentos entregados de la 1.3.0 (Reporte final y Manual), que **no se regeneraron**. Lo que aquí dice «no verificado» no se probó. Cifras únicas: `evidencias/documentacion/cifras.md`.

## Cambios

| Área | Qué cambió |
|---|---|
| Campos de usuario | Correo, nombre de usuario, contraseña, código y token **sin espacios** en acceso, registro, recuperación, verificación, Perfil, Seguridad de la cuenta (nativo), Directorio, Citas y Soporte (Flutter y Compose). La barra espaciadora no escribe, lo pegado se limpia y se avisa con ícono y texto. Nombres de persona del Directorio: sin espacio inicial ni dobles. Administración en la app no tiene campos de texto. |
| API | `@SinEspacios` en los DTO de acceso, perfil y administración + Jest (10 casos). **PR CE0S23/CEOSMOSV2#2 abierto, sin fusionar**: producción todavía acepta contraseñas con espacios. |
| Reloj | 8 modos: Reposo 60–75, Durmiendo 48–60 (sin pasos), Caminando 85–105 (~100 pasos/min), Trotando 120–145 (~150), Corriendo 150–175 (~170), Frecuencia alta 150–190 y baja 35–45 (en reposo), Automático (ciclo de 30 s por etapa). Transición gradual, ruido leve, siempre 30–230 bpm, rótulo «Pulso simulado: no es una medición médica». «Sensor real» para pasos (contador → detector → acelerómetro). |
| Protocolo | Campo opcional `act` en las lecturas (compatible hacia atrás, ≤ 180 bytes) y mensaje `alert` para Reloj y TV. Mismo vector en Dart y Kotlin. |
| Alertas de salud | Reglas: alto sostenido ~10 s en reposo (>100), durmiendo (>90) o caminando (>130); muy alto ≥185 (3 s); bajo ≤45 despierto (10 s); correr con su pulso no alerta. Enfriamiento 60 s por tipo, tope 5 por sesión. Entrega: notificación del canal «Alertas de salud» (POST_NOTIFICATIONS con explicación previa y ruta en Ajustes si se niega), aviso en la app, Reloj (vibración y texto) y TV, y `metadata.wearable` (`activitySeconds`, `alerts`, `maxHeartRate`, `simulated`). Interruptor en Perfil › Cuenta y herramientas. |
| Robustez Reloj/TV | Cola de notificaciones GATT (una en vuelo, botones primero, lecturas sin atraso, reintento), botón de la TV con un solo objetivo de foco, rebote de 350 ms, feedback «Enviando… / recibido por CEOSMOS / No llegó», central con una operación GATT a la vez por enlace, reintento ante fallo transitorio, reautenticación única y redescubrimiento de servicios del enlace compartido. |
| Inicio | Tarjeta «Tu Reloj y TV» (Android y PWA): estado de cada equipo, pulso con corazón, pasos, actividad, «hace N s», alerta activa, proyección de la TV, estado vacío con botón a Equipos, «Conectar» y motivo del fallo. |

## Cifras nuevas

Flutter **374/374** (cobertura 58.1 %, núcleo 84.7 %) · analyze 0 avisos · Kotlin companion **30/30** por variante · Kotlin de la app **5/5** · API **89/89** (rama del PR) · barrido de 91 tamaños sin desbordes desde 240 dp con la tarjeta cargada · Lighthouse móvil 61/92/82/100 y escritorio 70/92/81/100 · instalabilidad 0 errores.

## Botones del Reloj y la TV (S24 + Tab S9, 26/11)

| Prueba | Antes (companion 1.0) | Después (1.4.0) |
|---|---|---|
| Reloj, toque en «Reanudar» (50) | 50/50 aceptadas por el periférico; confirmación y latencia no registradas | **50/50 confirmadas**, mediana 34,5 ms, p95 64 ms |
| TV, toque en «▶ Reanudar» (50) | 50/50 aceptadas; sin confirmación | **50/50 confirmadas**, mediana 34 ms, p95 73 ms |
| TV, centro del D-pad | **foco perdido tras cada pulsación (5/5)**: la siguiente tecla no hacía nada | **30/30 confirmadas, foco conservado**, mediana 85,5 ms, p95 104 ms |

Causas raíz: foco del D-pad (doble objetivo de foco con `onKeyEvent` + `.focusable()`), notificaciones sin esperar `onNotificationSent` (riesgo de «ocupado» con una lectura en vuelo; en la medición no apareció) y, hallado en el equipo, el Reloj que no podía reconectar si la TV había abierto antes el enlace compartido. Solo se midieron «toggle» y «stop»: «Siguiente/Anterior» habrían creado sesiones en la cuenta real. Archivos: `botones_*.txt`, script `scripts/medir_botones.sh`.

## Equipos

- APK 1.4.0 con `install -r` (sin desinstalar, misma fecha de primera instalación) en el S24 (CEOSMOS) y la Tab S9 (CEOSMOS, Reloj, TV). Sesión, datos, PIN e id del Reloj y la TV intactos. En el S24 el primer arranque tras instalar mostró «No hay conexión» y entró al reiniciar la app.
- Tab S9: contador y detector de pasos de Samsung y acelerómetro (`sensores_tab_s9.txt`); «Sensor real» probado (permiso concedido).
- Alertas de punta a punta: el CEOSMOS del S24 (en segundo plano) alertó al Reloj y a la TV (`reloj_modo_alta_alerta.png`, `tv_alerta.png`). Se observó una alerta legítima al pasar de Corriendo a Reposo (pulso aún alto en la recuperación).

## Pendiente o no verificado

- **Web Bluetooth con el Reloj y la TV reales** y **PWA instalada en el S24**: no verificados; el S24 se bloqueó con su PIN de pantalla durante la sesión.
- Notificación del sistema y su permiso en el S24, aviso dentro de la app y capturas del S24 (Inicio con la tarjeta conectada, alerta, PWA instalada): no verificados por la misma razón. Explorar, Perfil e Inicio (tarjeta vacía) se capturaron en la tablet.
- Modo sin conexión en Chrome de escritorio con DevTools: no repetido en esta versión.
- Producción de la API: falta fusionar el PR #2 y correr `scripts/verificar_produccion.ps1` y `scripts/redbox_produccion.sh` (hoy 28/29; P-25 falla hasta fusionar).
- Lighthouse: accesibilidad y buenas prácticas quedan en 92 y 82 por el `meta viewport` (sin zoom) y `Intl.v8BreakIterator`, ambos del motor de Flutter web; el rendimiento (TBT) es el costo de CanvasKit.

## Capturas

`reloj_modo_*.png` (7 modos + alerta en «Frecuencia alta»), `reloj_sensor_real.png`, `tv_alerta.png`, `tablet_inicio_tarjeta_vacia.png`, `tablet_explorar.png`, `tablet_perfil_alertas.png`. Recortadas por encima del PIN (sin recuadros negros).
