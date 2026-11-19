---
tags: [ceosmos, pendientes]
estado: abierto
actualizado: 2026-11-18
---

# Pendientes

Única lista de lo que falta. Todo lo demás está hecho y verificado (ver [[10 - Bitácora]] › Estado de las tareas).

## 1. Para cerrar la revisión (lo siguiente que se hace)
- [x] Cuentas P7 nuevas en Firebase Auth `practica7-8-941cb` (`admin|agente|usuario1|usuario2.ceosmos.p7@example.com`; contraseña en `.devdb/CUENTAS_DEV.txt`).
- [ ] Crear en Firebase Console › practica7-8 › Firestore › `dispositivos` un documento por cuenta (ID = UID; campos `rol`, `nombre`, `conectado: false`). Las reglas solo permiten crearlo desde la consola:
  - `eWgOEvECUeUpay6x7DBAxGmp6Hf2` → `admin` · `Administrador`
  - `ExbVHgydDjRABO4xCGYx5eKNv8J2` → `agente` · `Agente`
  - `YX9spcWR4vg7rZoye679FKO3cF82` → `usuario1` · `Usuario 1`
  - `0VXUbHkzoxSpQk3tcCVYlh2uqD42` → `usuario2` · `Usuario 2`
- [ ] Recorrido de la P7 con los 4 roles en S24 + tablet y matriz TC01–TC08 (capturas `evidencias/p07_*`). → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]
- [ ] Marcar la P7 como cumplida en su nota, en [[07 - Pruebas (Black, White, Red Box)]] y en el Word (quitar «No aplicado por completo»).

## 2. Requieren al usuario (permiso o acceso)
- [ ] Cuenta ADMIN en Neon (escritura en producción). → [[02 - Requerimientos]]
- [x] Push de `main` (este repo) a https://github.com/CE0S23/CEOSMOS-MovilIntegral (18/11, P13-14).
- [ ] Fusionar el PR #1 (`practica-13-14` → `main`). → [[Práctica 13-14 - Automatización de pruebas y CI]]
- [ ] Rotar el `JWT_SECRET` y la contraseña de `neondb_owner` que aparecían en la nota histórica de la web (ya redactados del historial) si siguen vigentes. → [[Histórico - CEOSMOS Web (auditoría)]]
- [ ] Push de `movil-integral` (WEBANGULAR, repo CEOSMOSV2). → [[10 - Bitácora]]
- [ ] Frontend Angular (`ceosmos-t8ee.vercel.app`) apuntando a `https://ceosmos-api.vercel.app/api`. → [[03 - Arquitectura y stack]]
- [ ] Passkeys WebAuthn en móvil (`assetlinks.json` en el dominio). → [[02 - Requerimientos]]
- [ ] Keystore propio para firmar el release (hoy llave de depuración). → [[07 - Pruebas (Black, White, Red Box)]]
- [ ] Borrar los `.env` temporales con credenciales de prod del scratchpad de la sesión del 12/11, si siguen ahí. → [[Notas varias]]

## 3. Mejoras opcionales
- [ ] Servicio en primer plano para audio muy largo. → [[02 - Requerimientos]]
- [ ] Limitador de la API en Redis (Upstash). → [[07 - Pruebas (Black, White, Red Box)]]
- [ ] P10: cesión con aceptación del receptor. → [[Práctica 10 - Seguridad y control de acceso]]
- [ ] BLE con bonding cifrado (LE Secure Connections). → [[06 - BLE Wearable y TV]]
- [ ] Lint del companion: 14 advertencias por app (dependencias, `StaticFieldLeak`, `UseKtx`). → [[Práctica 13-14 - Automatización de pruebas y CI]]

---
Navegación: [[00 - Índice CEOSMOS]] · [[10 - Bitácora]] · [[07 - Pruebas (Black, White, Red Box)]]
