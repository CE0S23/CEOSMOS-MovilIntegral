# Lista de verificación previa a la evaluación · CEOSMOS

Revísala 30 minutos antes. Cada punto tiene el comando o la pantalla que lo comprueba.

## Equipos
- [ ] Batería del S24 (`R5CXA1DRLAF`) y de la Tab S9 (`R52W80BXQHP`) al 80 % o más, con cargador a la mano. Comando: `adb -s <serial> shell dumpsys battery | grep level`.
- [ ] Los dos aparecen en `adb devices` como `device`. Si alguno sale `offline`: `adb reconnect offline`.
- [ ] Modo No molestar activado y brillo cómodo, ajustados a mano. La app no los toca.
- [ ] Bluetooth encendido y Wi-Fi en la **misma red** en los dos equipos: Mensajería entre equipos lo necesita.
- [ ] Internet: `curl -s https://ceosmos-api.vercel.app/api/health` responde `200`.

## Apps abiertas, en este orden
1. [ ] Tab S9: **CEOSMOS TV** y **CEOSMOS Reloj** abiertas (anunciando). Anota los PIN.
2. [ ] S24: **CEOSMOS** con la sesión iniciada; en Equipos, Reloj y TV en «Conectado» (si falla, *Reintentar*).
3. [ ] Tab S9: **CEOSMOS** con la cuenta ADMIN; se ve **Administración** en Perfil.

## Cuentas y roles (las contraseñas no se escriben aquí: están en `.devdb/CUENTAS_DEV.txt` y en tu gestor)
- [ ] CEOSMOS: cuenta QA en el S24 (USER) y cuenta ADMIN en la tablet.
- [ ] Soporte (Tickets y chat interno): administrador, agente, usuario 1 y usuario 2. Cada uno entra con su URL de rol.
- [ ] Mis incidencias y acceso: usuario A y usuario B.

## Datos iniciales
- [ ] Soporte: al menos un ticket abierto por usuario y uno asignado al agente.
- [ ] Incidencias en tiempo real: la lista carga en los dos equipos con el mismo número de incidencias.
- [ ] Directorio de alumnos: 2 o 3 alumnos de ejemplo.
- [ ] Opcional: borrar la incidencia de prueba «CEOSMOS_P9_001», cuyo título contiene «P9».

## Servicios
- [ ] API de producción: `200` en `/api/health` y `401` en `/api/devices` sin token.
- [ ] Firestore: Reportes compartidos muestra un UID y «Consultar desde servidor» responde.
- [ ] Citas de bienestar (solo si se va a mostrar): `scripts\dev_backend.ps1` levantado y `adb reverse tcp:3443 tcp:3443`.

## Computadora
- [ ] El proyecto abierto en el editor, en `main` y sin cambios: `git status` limpio y `git log -1` igual a `entrega-v1` o posterior.
- [ ] Terminal lista en la raíz del proyecto, con `scripts/arreglo_rapido.sh` probado.
- [ ] APK de respaldo en `release\` por si hay que reinstalar.
- [ ] `mostrarReferenciasAcademicas` con el valor decidido (`lib/core/referencias_academicas.dart`).
