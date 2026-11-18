---
tags: [ceosmos, pendientes]
estado: abierto
actualizado: 2026-11-18
---

# Pendientes

Todo lo que falta, con su nota de origen.

- [x] Cuentas P7 nuevas creadas en Firebase Auth (`*.ceosmos.p7@example.com`, 18/11; datos en `.devdb/CUENTAS_DEV.txt`).
- [ ] **P7 (siguiente paso, en curso 18/11 15:10):** crear en Firebase Console › practica7-8 › Firestore › `dispositivos` un documento por cuenta (ID = UID; campos `rol`, `nombre`, `conectado:false`):
  - `eWgOEvECUeUpay6x7DBAxGmp6Hf2` → rol `admin`, nombre `Administrador`
  - `ExbVHgydDjRABO4xCGYx5eKNv8J2` → rol `agente`, nombre `Agente`
  - `YX9spcWR4vg7rZoye679FKO3cF82` → rol `usuario1`, nombre `Usuario 1`
  - `0VXUbHkzoxSpQk3tcCVYlh2uqD42` → rol `usuario2`, nombre `Usuario 2`
  - Se iba a hacer con la extensión de Chrome (pestaña de la consola ya abierta); el usuario pausó para retomar luego.
- [ ] **P7 después:** recorrido con sesión de los 4 roles en S24 + tablet (mensajes, archivos, asignación) y matriz TC01–TC08; capturas `evidencias/p07_*`.
- [ ] **Al cerrar P7:** marcarla `cumple` en [[Práctica 07 - Roles y mensajería (Sistema de tickets)]], en [[07 - Pruebas (Black, White, Red Box)]] y en el Word (quitar «No aplicado por completo» de la P7). → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]
- [ ] **Cuenta ADMIN en Neon** (escritura en producción, la hace el usuario o con autorización). → [[02 - Requerimientos]]
- [ ] **Frontend Angular** (`ceosmos-t8ee.vercel.app`) apuntando a `https://ceosmos-api.vercel.app/api`. → [[03 - Arquitectura y stack]]
- [ ] **Push** de `main` (este repo, sin remoto) y de `movil-integral` (WEBANGULAR) — solo con autorización. → [[10 - Bitácora]]
- [ ] **Passkeys WebAuthn** en móvil (`assetlinks.json` en el dominio RP). → [[02 - Requerimientos]]
- [ ] **Servicio en primer plano** para audio muy largo. → [[02 - Requerimientos]]
- [ ] **Keystore propio** para firmar el release (hoy llave de depuración). → [[07 - Pruebas (Black, White, Red Box)]]
- [ ] **Limitador** de la API en Redis (opcional). → [[07 - Pruebas (Black, White, Red Box)]]
- [ ] **P10 cesión con aceptación** del receptor (opcional). → [[Práctica 10 - Seguridad y control de acceso]]
- [ ] **BLE con bonding cifrado** (opcional). → [[06 - BLE Wearable y TV]]
- [ ] Borrar los `.env` temporales con credenciales de prod del scratchpad de la sesión del 12/11 si siguen ahí. → [[Notas varias]]
