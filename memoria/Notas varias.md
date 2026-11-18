---
tags: [ceosmos, varios]
estado: vigente
actualizado: 2026-11-18
---

# Notas varias

- Cuentas de prueba: solo en `.devdb/CUENTAS_DEV.txt` (fuera de git). Neon: `delivered@resend.dev`. Local: `usuario@ceosmos.test`, `admin@ceosmos.test`, `p11_*`, `p12_*`.
- P10 (Firebase `mesaayuda-p7`): cuentas creadas el 18/11 `a.ceosmos1118@p10.test` y `b.ceosmos1118@p10.test` (misma contraseña que las cuentas P10 de prueba en `.devdb/CUENTAS_DEV.txt`).
- Pruebas de carga solo contra la API local, nunca contra Neon, Resend o Vercel.
- Para no depender del cable se puede usar adb por Wi-Fi en la tablet (`adb tcpip 5555` + `adb connect <ip>:5555`); se desactivó al terminar el 18/11 (`adb usb`).
- Guion de demostración de la primera revisión (08/10): acceso, Inicio, Explorar («orbita» sin tilde), sesión, perfil, dispositivos. Hoy ya no hay «Explorar demo».
- Huella de la integración: adaptaciones de cada práctica marcadas con `[CEOSMOS]` en el código.
