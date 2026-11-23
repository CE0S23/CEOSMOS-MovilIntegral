---
tags: [ceosmos, pendientes]
estado: abierto
actualizado: 2026-11-22
---

# Pendientes

Única lista de lo que falta. Todo lo demás está hecho y verificado (ver [[10 - Bitácora]] › Estado de las tareas).

## 1. Para cerrar la revisión (lo siguiente que se hace)
- [x] Cuentas P7 nuevas en Firebase Auth `practica7-8-941cb` (`admin|agente|usuario1|usuario2.ceosmos.p7@example.com`; contraseña en `.devdb/CUENTAS_DEV.txt`).
- [x] Documento de rol en Firestore › `dispositivos` para las 4 cuentas (19/11, desde la consola; ID = UID; `rol`, `nombre`, `conectado: false`):
  - `eWgOEvECUeUpay6x7DBAxGmp6Hf2` → `admin` · `Administrador`
  - `ExbVHgydDjRABO4xCGYx5eKNv8J2` → `agente` · `Agente`
  - `YX9spcWR4vg7rZoye679FKO3cF82` → `usuario1` · `Usuario 1`
  - `0VXUbHkzoxSpQk3tcCVYlh2uqD42` → `usuario2` · `Usuario 2`
- [x] Recorrido de la P7 con los 4 roles en S24 + tablet y matriz TC01–TC08 aprobada (19/11; capturas `evidencias/p07_01…29`; 4 fallas corregidas). → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]
- [x] P7 marcada como cumplida en su nota, en [[07 - Pruebas (Black, White, Red Box)]] y en el Word (sin «No aplicado por completo»; respaldo en `C:/CESAR10cuatri/memoria_respaldo_2026-11-19/`).
- [x] Rediseño + reestructura (21/11): recorrido en S24 y Tab S9 en claro/oscuro hecho. → [[12 - Mapa de funciones]]
- [ ] **Usuario (opcional):** la incidencia de prueba «CEOSMOS_P9_001» de la base compartida muestra «P9» en su título (es un dato, no la interfaz); borrarla si se quiere.
- [ ] **Antes de la entrega final:** `mostrarReferenciasAcademicas = false` en `lib/core/referencias_academicas.dart`. → [[12 - Mapa de funciones]]
- [ ] **Usuario:** decidir si se borran los 4 documentos viejos de `dispositivos` (cuentas originales `*.p7@example.com`, sin contraseña conocida); hoy salen duplicados como «desconectado» en la presencia de la P7. → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]

## 2. Requieren al usuario (permiso o acceso)
- [ ] Cuenta ADMIN en Neon (escritura en producción). → [[02 - Requerimientos]]
- [x] Push de `main` (este repo) a https://github.com/CE0S23/CEOSMOS-MovilIntegral (18/11, P13-14).
- [x] PR #1 fusionado a `main`; CI de main en verde (18/11). → [[Práctica 13-14 - Automatización de pruebas y CI]]
- [x] Entregables P13-14 cerrados (19/11): logs de los runs de main, #7 y #8, captura de Actions con main en verde, Word completado y push a `main`. → [[Práctica 13-14 - Automatización de pruebas y CI]]
- [x] Borrado el `.bundle` de respaldo con secretos y purgado el `.git` local (18/11).
- [ ] Claves Firebase: practica7-8 y reportes-movil restringidas [x]; falta restringir la clave de `mesaayuda-p7` (otra cuenta).
- [x] P7 terminada y probada con la clave restringida (19/11). → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]
- [ ] Frontend Angular (`ceosmos-t8ee.vercel.app`) apuntando a `https://ceosmos-api.vercel.app/api`. → [[03 - Arquitectura y stack]]
- [ ] Passkeys WebAuthn en móvil (`assetlinks.json` en el dominio). → [[02 - Requerimientos]]
- [ ] Keystore propio para firmar el release (hoy llave de depuración; aceptado para la entrega, ver [[13 - Blindaje]]). → [[07 - Pruebas (Black, White, Red Box)]]
- [ ] Borrar los `.env` temporales con credenciales de prod del scratchpad de la sesión del 12/11, si siguen ahí. → [[Notas varias]]

- [ ] **Blindaje:** regla de Firestore de `mesaayuda-p7/dispositivos` (legible sin sesión, medido 22/11 noche): exigir `request.auth != null`; la hace el dueño de ese proyecto. → [[13 - Blindaje]]
- [ ] **Blindaje:** cerrar las sesiones de prueba de Soporte (S24: admin · Tab S9: agente).

- [ ] **Blindaje · F-14:** registro real en producción (no verificado: requiere acceso al correo del código).

## 3. Mejoras opcionales
- [ ] Servicio en primer plano para audio muy largo. → [[02 - Requerimientos]]
- [ ] Limitador de la API en Redis (Upstash). → [[07 - Pruebas (Black, White, Red Box)]]
- [ ] P10: cesión con aceptación del receptor. → [[Práctica 10 - Seguridad y control de acceso]]
- [ ] BLE con bonding cifrado (LE Secure Connections). → [[06 - BLE Wearable y TV]]
- [ ] Lint del companion: 14 advertencias por app (dependencias, `StaticFieldLeak`, `UseKtx`). → [[Práctica 13-14 - Automatización de pruebas y CI]]

---
Navegación: [[00 - Índice CEOSMOS]] · [[10 - Bitácora]] · [[07 - Pruebas (Black, White, Red Box)]]
