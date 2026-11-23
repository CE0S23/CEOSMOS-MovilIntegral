---
tags: [ceosmos, blindaje, calidad]
estado: completado
actualizado: 2026-11-22 (noche)
---

# 13 · Blindaje

**Único registro del blindaje.** 21–22/11/2026, antes de la evaluación (1 de 4 profesores: usabilidad, funcionalidad, redes o seguridad; 20 min para arreglar en vivo). Entrega: `entrega-v4`, app **1.2.1** (`release/CEOSMOS-entrega-v4-release-llave-depuracion.apk`) en S24 y Tab S9. Detalle completo: `evidencias/blindaje/Dossier de blindaje - CEOSMOS.pdf` · `Hoja de defensa.pdf` · `masvs.md`. Registro detallado anterior respaldado en `C:\CESAR10cuatri\respaldos\blindaje_2026-11-22\`.

## Qué se hizo, por área
- **Usabilidad:** errores globales con aviso amigable, 48 dp y fuente al 200 %, barrido de 91 tamaños (sin desbordes desde 240 dp), ventana flotante real cómoda desde 260 × 440 dp, usuario torpe en copia aislada `.monkey` (S24 5 000 acciones sin errores; Tab S9 5 000 → 4 desbordes corregidos).
- **Funcionalidad:** recorridos en hardware; Reloj y TV de punta a punta (6/7; la reconexión sin PIN falló y se corrigió con un latido BLE en 1.2.1); Soporte F-05 con admin, agente y usuario1 (ticket, chat, adjunto 203 KB / 434 KB rechazado, asignación, presencia).
- **Redes:** red mínima (API: 5 kbps o RTT 4 s; Firebase falla con RTT 4 s), 6 continentes y Madrid 373 ms, regiones (Vercel iad1, Neon us-east-1, Firestore us-central1 / nam5), BT apagado → reconexión ≤ 8 s.
- **Seguridad:** Red Box 13/13 + 37/37 en local; 6 correcciones de la API **en producción** (PR CEOSMOSV2 #1, `c07b01f`) y Red Box de producción sin credenciales 27/27 (`scripts/redbox_produccion.sh`); secretos de Vercel/Neon rotados por el usuario; gitleaks y OSV/npm (0 en lo distribuido); 4 alertas de secret scanning cerradas; mapa MASVS / Top 10.
- **Contingencia:** `scripts/arreglo_rapido.*` (ciclo 164 s) con verificación de producción (`verificar_produccion.*`, ya robusta en la tablet), guía de fallos y lista previa.

## Cifras clave
331/331 pruebas Flutter · analyze limpio · companion test + lint · API 79/79 · Red Box 13 + 37 (local) y 27 (producción) · CI verde.

## Límites y riesgos aceptados (con motivo)
- **Incidente 22/11:** el usuario torpe desinstaló la app real del S24 y de la tablet (aislamiento no aplicado); se perdieron datos locales. Corregido con marcador, comprobación aapt2 y alarma (`test/blindaje_scripts_test.dart`).
- No verificado: F-14 (requiere el correo), usuario2 de Soporte (mismo rol que usuario1), tercer central BLE en hardware (sin tercer equipo), pruebas con sesión de la API en producción (el asistente no escribe contraseñas en producción; cubiertas en local), TalkBack, usuarios reales, transitivas de Gradle.
- Aceptado: 5 000 acciones por equipo y no 20 000; APK con llave de depuración (decisión del usuario); BLE sin cifrado de carga útil; SQLite sin cifrar (sin credenciales); limitador por instancia; 19 moderadas solo de desarrollo; al abrir CEOSMOS hay que pulsar «Conectar» (sin PIN).

## Pendientes manuales (del usuario; en [[08 - Pendientes]])
- [ ] Regla de `mesaayuda-p7/dispositivos` (sigue legible sin sesión el 22/11) y restricción de su clave: las hace el dueño de ese proyecto.
- [ ] F-14 con un correo propio.
- [ ] Cerrar las sesiones de prueba de Soporte (S24: admin; tablet: agente).

---
Navegación: [[00 - Índice CEOSMOS]] · [[07 - Pruebas (Black, White, Red Box)]] · [[08 - Pendientes]] · [[06 - BLE Wearable y TV]] · [[10 - Bitácora]]
