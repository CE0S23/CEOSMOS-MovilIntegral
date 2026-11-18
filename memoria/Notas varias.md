---
tags: [ceosmos, varios]
estado: vigente
actualizado: 2026-11-18
---

# Notas varias

- Cuentas de prueba: solo en `.devdb/CUENTAS_DEV.txt` (fuera de git). Neon: `delivered@resend.dev`. Local: `usuario@ceosmos.test`, `admin@ceosmos.test`, `p11_*`, `p12_*`.
- P10 (Firebase `mesaayuda-p7`): cuentas creadas el 18/11 `a.ceosmos1118@p10.test` y `b.ceosmos1118@p10.test` (misma contraseña que las cuentas P10 de prueba en `.devdb/CUENTAS_DEV.txt`).
- Pruebas de carga solo contra la API local, nunca contra Neon, Resend o Vercel.
- La tablet quedó con adb por Wi-Fi (`192.168.100.39:5555`) para no depender del cable; se desactiva con `adb -s <ip>:5555 usb` o reiniciando la tablet.
- Guion de demostración de la primera revisión (08/10): acceso, Inicio, Explorar («orbita» sin tilde), sesión, perfil, dispositivos. Hoy ya no hay «Explorar demo».
- Huella de la integración: adaptaciones de cada práctica marcadas con `[CEOSMOS]` en el código.
