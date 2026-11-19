---
tags: [ceosmos, practica]
estado: cumple
actualizado: 2026-11-19
---

# Práctica 07 · Roles y mensajería (Sistema de tickets)

**En CEOSMOS:** P7 Sistema de tickets; Firebase `practica7-8-941cb` (app con nombre `practica7`), roles admin/agente/usuario1/usuario2 por URL preasignada (`https://practica7.app/rol/<rol>`), chat con adjuntos ≤ 300 KB, presencia. Real-time solo para admin y agente (los usuarios usan «Actualizar»), como pide la práctica.

## Preparación
- [x] Código: roles por URL, mensajes con hora, contador, limpiar historial, validación de vacíos, reportes con turnos y política ante id repetido; reglas de Firestore por rol (las publicadas son idénticas a `Practica para implementar en la app/practica7/firestore.rules`, comprobado el 19/11).
- [x] 4 cuentas en Firebase Auth (18/11): `admin|agente|usuario1|usuario2.ceosmos.p7@example.com` (contraseña en `.devdb/CUENTAS_DEV.txt`, nunca en la memoria).
- [x] Documento de rol en `dispositivos/{uid}` de las 4 cuentas (19/11, desde la consola: `rol`, `nombre`, `conectado: false`) → `evidencias/p07_01_firestore_dispositivos_4_roles.jpg`.
- [x] API key restringida (paquete + SHA-1) aceptada por Firebase Auth: con contraseña errónea responde «Correo o contraseña incorrectos», no clave bloqueada (`p07_02`); con la correcta entran los 4 roles.
- Nota: en `dispositivos` siguen los 4 documentos de las cuentas originales (`*.p7@example.com`, contraseña desconocida); aparecen como duplicados «desconectado» en la lista de presencia. Borrarlos es decisión del usuario → [[08 - Pendientes]].

## Recorrido con los 4 roles (S24 `R5CXA1DRLAF` + Tab S9 `R52W80BXQHP`, 19/11)
- [x] Ronda 1 — S24 usuario1, tablet admin: alta, chat en tiempo real (admin recibe sin refrescar), respuesta, adjunto 53 KB aceptado y descargado íntegro en la tablet (53 031 bytes), 430 KB rechazado, solicitud directa al admin, presencia (conectado ↔ desconectado al pasar a segundo plano), eliminación.
- [x] Ronda 2 — S24 admin, tablet agente: agente ve sus tickets asignados, mensaje en tiempo real al admin, **asignación**: agente «Pasar al administrador» → aparece en «Asignados a mí» del admin; admin «Devolver al agente» → vuelve al agente; agente lo marca Resuelto (chat cerrado).
- [x] Ronda 3 — S24 usuario2, tablet agente: usuario2 no ve el ticket de usuario1 (REP101 → «Reporte no encontrado»), crea REP103 (reutiliza el turno 1 liberado), conversación con el agente; admin limpia el historial (contadores a 0 en los dos equipos).

## Matriz TC01–TC08
- [x] TC01 Alta válida: REP101 guardado y visible para el admin en tiempo real (`p07_04`, `p07_05`).
- [x] TC02 Campos vacíos: 4 validaciones en pantalla (`p07_03`).
- [x] TC03 ID repetido: «El ID ya existe, no se sobrescribe» (`p07_12`).
- [x] TC04 Actualización: admin Media → Alta; usuario1 la consulta y se conserva (`p07_10`, `p07_11`).
- [x] TC05 Eliminación: admin elimina REP102; ya no aparece ni por consulta (`p07_20`).
- [x] TC06 Inexistente: REP999 → «Reporte no encontrado» sin bloquear (`p07_13`).
- [x] TC07 Sin conexión: aviso «Sin conexión…» y chip «Pendiente»; al volver la red se sincroniza y el admin lo ve (`p07_14`, `p07_15`).
- [x] TC08 Persistencia: cerrar la app (force-stop) y reabrir; REP101 con su prioridad y mensajes (`p07_16`).

## Fallas encontradas y corregidas (19/11)
- [x] La pantalla de acceso solo admitía los correos viejos `*.p7@example.com` → `_correosPorRol` apunta a las cuentas `*.ceosmos.p7@example.com` (`rol_screen.dart`).
- [x] Con el teclado abierto el formulario quedaba en blanco (la barra de CEOSMOS y la práctica descontaban el teclado) → `resizeToAvoidBottomInset: false` en `PracticaHost` (`practica_host.dart`). No se pudo reproducir en una prueba de widget; verificado en el S24.
- [x] Un mensaje propio del admin/agente se quedaba en «Pendiente» aunque el servidor ya lo tenía → el chat escucha también cambios de metadatos (`mensaje_service.dart`).
- [x] El rechazo de adjuntos mostraba «Invalid argument(s): …» → solo el mensaje (`chat_screen.dart`).

Evidencias: `evidencias/p07_01` … `p07_29`.

Volver: [[00 - Índice CEOSMOS]] · Pruebas: [[07 - Pruebas (Black, White, Red Box)]]
