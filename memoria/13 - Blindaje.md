---
tags: [ceosmos, blindaje, calidad]
estado: en curso
actualizado: 2026-11-22 (tarde)
---

# 13 · Blindaje

Plan en 3 etapas antes de la evaluación (1 de 4 profesores: usabilidad, funcionalidad, redes o seguridad; 20 min para arreglar en vivo). La Etapa 3 se hizo primero (21/11); el 22/11 se auditó cada casilla contra código, pruebas y `evidencias/` y se ejecutaron las etapas 1 y 2. **Solo hay [x] en lo verificado.** No se consolida: quedan casillas que dependen del usuario.

## Reglas
- Nada de `adb shell monkey`, ajustes del sistema ni desinstalar la app real. El usuario torpe corre en la copia aislada `com.ceosmos.ceosmos_movil_integral.monkey` (`scripts/mono_bloques.ps1`), que mantiene la pantalla encendida solo con una bandera de su ventana.
- Nada de `C:\CESAR10cuatri\llaves\`; ningún secreto en chat, commits ni evidencias.
- Producción: solo lecturas, ≤ 1 petición/s; los cambios de API van en rama + preview y producción la promueve el usuario.
- No repetir lo ya probado (pedido del usuario, 22/11).

## Etapa 1 · Robustez, usabilidad y funcionalidad
- [x] Manejo global de errores y aviso amigable — `lib/core/errores_globales.dart`, `test/errores_globales_test.dart`.
- [x] Timeouts (15 s, un solo plazo) y errores HTTP/TLS sin texto crudo — `lib/data/api_client.dart`, `test/tls_rechazo_test.dart`.
- [x] Anti doble toque — `test/doble_toque_test.dart` (login), `test/p12_optimizaciones_test.dart` (Terminar).
- [x] Usuario torpe — S24: 5 000 acciones, 0 errores/crash/ANR (`evidencias/blindaje/mono/bloques_R5CXA1DRLAF.txt`). Tab S9: 5 000 acciones, 0 crash/ANR, 4 desbordes en el diálogo de biblioteca → corregido, misma semilla 2 100 acciones con 0 errores (`verificacion_R52W80BXQHP_semilla4101.txt`). **Aceptado:** no se completaron 20 000 (S24 sin batería; el usuario pidió no repetir). La corrida del 21/11 no había terminado.
- [x] Tamaños de pantalla — barrido de 91 tamaños sin desbordes desde 240 dp (`evidencias/blindaje/ventana/barrido_tamanos.md`); ventana flotante real en 14 tamaños, cómoda desde 260 × 440 dp (`ventana/v2/`).
- [x] Accesibilidad básica — 48 dp, etiquetas, fuente al 200 % (`test/accesibilidad_test.dart`). TalkBack de punta a punta: no probado.
- [x] Integration tests con fallas inyectadas — `integration_test/p12_resiliencia_test.dart` (RES-01…09, evidencia en `p11yp12/p12/evidencias/fase5_resiliencia/`).
- [x] Validación en el servidor — DTO whitelist; Red Box 13/13 + 37/37.
- [ ] F-05 y recorrido con sesión — **no verificado**: requieren escribir contraseñas en Firebase/API de producción; el asistente no lo hace aunque esté autorizado (regla de seguridad). Pasos en [[08 - Pendientes]].
- [x] F-14 — **no verificado: requiere acceso al correo** (código de verificación). En la lista del usuario.

## Etapa 2 · Redes y seguridad
- [x] Inventario de APIs — dossier §4 + 47 rutas.
- [x] Red mínima medida — `evidencias/blindaje/red/red_minima.md` (API: 5 kbps o RTT 4 s; Firebase falla con RTT 4 s).
- [x] Geografía por continente y España — `evidencias/blindaje/red/geografia.md` (6 continentes, Madrid 373 ms).
- [x] Caída de dependencias — sin red/timeout (P12 RES), Firestore con caché.
- [x] TLS y cabeceras — HSTS, nosniff, DENY y referrer en producción; CSP en la rama `blindaje-api`.
- [x] Sesión y autorización — RB-01..03, 13..20, 33..36, 47.
- [x] Rate limiting — RB-46 (429). **Aceptado:** el contador es por instancia en Vercel.
- [x] Dependencias y secretos — gitleaks (`secretos_gitleaks.txt`) y auditoría OSV/npm del 22/11 (`evidencias/blindaje/dependencias.md`): 0 en lo distribuido; `brace-expansion` (alta, dev) y `org.json` (pruebas de companion) corregidos. **Aceptado:** 19 moderadas solo de desarrollo; transitivas de Gradle **no verificadas**.
- [x] Red Box ampliado — `scripts/redbox_ampliado.sh` 27/37 → 37/37; 6 correcciones de la API en la rama `blindaje-api` (CEOSMOSV2 `605776c`, 79/79 Jest).
- [x] Mapa MASVS / Top 10 — `evidencias/blindaje/masvs.md`.
- [x] Cifrado en reposo — **aceptado:** token en Keystore; SQLite/SharedPreferences sin cifrar y sin credenciales.
- [x] Cifrado BLE — **aceptado:** reto + HMAC y PIN que nunca viaja; la carga útil no va cifrada (no se tocó a días de la entrega).
- [ ] **Secretos y despliegue de la API** — usuario. 22/11 tarde: producción sigue en `a4d8d6a` (12/11) y Vercel muestra `JWT_SECRET`/`DATABASE_URL`/`DIRECT_URL` «Added Nov 12»: sin redeploy, los secretos nuevos no aplican y los tokens viejos siguen válidos (inferido; no había un token viejo para probarlo). El usuario decidió dejarlo para después. Falta: guardar secretos → desplegar `blindaje-api` (`3617c0d`) → token viejo 401 → Red Box contra producción. Rollback: promover `a4d8d6a`.
- [ ] Regla de `mesaayuda-p7/dispositivos` (legible sin sesión) — dueño de ese proyecto (la sesión de Chrome del usuario no tiene acceso). CEOSMOS no usa esa colección; la presencia de Soporte (`practica7-8/dispositivos`) da 403 sin sesión (medido).
- [x] Región de Firestore — `practica7-8` us-central1, `reportes-movil` nam5 (consola, 22/11); `mesaayuda-p7` **no verificado** (sin acceso).
- [x] Release con llave propia — **aceptado (decisión del usuario)**: listo en `release/CEOSMOS-entrega-v1-release.apk`, exige registrar su SHA-1 y desinstalar. La entrega usa `release/CEOSMOS-entrega-v3-release-llave-depuracion.apk` (1.2.0+3).

## Etapa 3 · Documentación, contingencia y cierre
- [x] Dossier (.md/.docx/.pdf), hoja de defensa y Reporte de avances actualizados el 22/11; PDF revisados página por página (sin páginas en blanco: se corrigió `scripts/md_a_docx.py`). Respaldo previo: `C:\CESAR10cuatri\respaldos\blindaje_2026-11-22\`.
- [x] `scripts/arreglo_rapido.*` y ensayo de 20 min (21/11).
- [x] Tags `entrega-v1` (21/11) y `entrega-v2` (22/11).
- [x] Tab S9: release v2 instalado encima (misma firma, datos conservados) y Reloj reinstalado con su última compilación; TV ya estaba al día. **Ojo:** la primera v2 se compiló sin `--dart-define=CEOSMOS_API_URL=https://ceosmos-api.vercel.app/api` y apuntaba a `10.0.2.2`; se recompiló con la URL (verificada dentro de `libapp.so`) y en la tablet un login con un correo inexistente responde «Correo o contraseña incorrectos.» (llega a producción). La tablet muestra Acceso: hay que iniciar sesión con la cuenta de la demo.
- [x] S24: v3 (1.2.0) instalada el 22/11 15:53 y `verificar_produccion.ps1` OK.
- [ ] Tab S9: instalar v3 (no estaba conectada): `adb -s R52W80BXQHP install -r release/CEOSMOS-entrega-v3-release-llave-depuracion.apk` y revisar su `firstInstallTime` (probable reinstalación por el incidente).
- [x] **Incidente usuario torpe** — la app real del S24 se desinstaló (firstInstallTime 22/11 14:03; datos locales perdidos). Causa reproducida: `ORG_GRADLE_PROJECT_ceosmosMonkey` no llega a Gradle. Corregido: marcador `android/app/.ceosmos_monkey`, comprobación aapt2 y alarma de reinstalación (`scripts/mono_bloques.ps1`, `test/blindaje_scripts_test.dart`).
- [x] `arreglo_rapido` sin `adb monkey` y con paso 6 de verificación de producción; ciclo medido 164 s en el S24. Release usa producción por defecto (`test/config_api_test.dart`).
- [x] Tag `entrega-v3`; `release/SHA256SUMS.txt` actualizado.
- [ ] Consolidación de la memoria — **no se hace** hasta cerrar las casillas de arriba.

---
Navegación: [[00 - Índice CEOSMOS]] · [[07 - Pruebas (Black, White, Red Box)]] · [[08 - Pendientes]] · [[09 - Decisiones técnicas]] · [[12 - Mapa de funciones]]
