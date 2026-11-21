---
tags: [ceosmos, blindaje, calidad]
estado: en curso
actualizado: 2026-11-21
---

# 13 · Blindaje

Plan de blindaje en 3 etapas antes de la evaluación. **Esta nota no existía cuando se pidió la Etapa 3**: no hay registro de las Etapas 1 y 2 en el repositorio, en otras ramas ni en `evidencias/`. Con autorización del usuario (21/11) se hizo la Etapa 3 sin inventar sus resultados. **No se consolida** hasta que las tres etapas estén completas.

## Reglas comunes (deducidas de las peticiones del usuario)
- Las pruebas se hacen **solo dentro de la app**: nada de eventos al sistema (brillo, barra de notificaciones, bloqueo). Lección del 21/11: `adb monkey` sacó al usuario de la app y bloqueó el S24.
- No se pierden datos: nada de desinstalar ni de tocar datos reales en la nube.
- Lo medido se separa de lo inferido, y lo no hecho se dice.
- Commit y push a `main` con CI en verde al cerrar cada etapa.

## Etapa 1 · Usabilidad y conectividad
- [ ] Usabilidad con usuarios reales (método, tareas, hallazgos) — **sin registro**.
- [ ] Red mínima por API y tabla por continente medida — **sin registro** (en el dossier va como inferencia).
- [x] Tamaño mínimo funcional con ventana flotante: **320 × 560 dp** (medido en la Tab S9 el 21/11; encabezado y etiqueta BLE corregidos a 280 dp, con prueba).

## Etapa 2 · Seguridad ampliada
- [ ] Red Box ampliado y mapa MASVS completo — **sin registro**. Existe el Red Box de la API (13/13, repetido el 21/11) y un mapa MASVS parcial en el dossier.

## Etapa 3 · Documentación, contingencia y cierre (21/11)
- [x] `flutter analyze` sin avisos · `flutter test` 217/217 · cobertura de líneas 52.9 % · companion `./gradlew test lint` en verde.
- [x] «Usuario torpe» dentro de la app (`integration_test/mono_usuario_test.dart`), 20 000 acciones por equipo: resultado en [[#Resultados]].
- [x] Red Box de la API local: 13/13 (`evidencias/blindaje/redbox_api_entrega.txt`).
- [x] API de producción: 200 en `/health`, HSTS, HTTP → 308, sin token → 401 (`evidencias/blindaje/api_produccion_health.txt`).
- [x] Ningún texto visible con «Práctica», «P#», «Examen» ni «Eval.» (prueba automática). Interruptor ⓘ: `mostrarReferenciasAcademicas = true`.
- [x] Recorrido de usuario novato: login, Soporte (admin), reportes, mensajería, Reloj y TV (ver [[12 - Mapa de funciones]]).
- [ ] Registro de una cuenta nueva en producción: no se puede completar (código por correo); cubierto con la API simulada.
- [ ] Soporte con el agente y los 2 usuarios: requiere las contraseñas del usuario.
- [x] APK de release firmado con llave propia: `release/CEOSMOS-entrega-v1-release.apk` (verificado con `apksigner`). **No instalado** en los equipos: exige desinstalar y perder datos locales; el usuario pidió no perder datos. Respaldo instalable encima: `release/CEOSMOS-entrega-v1-release-llave-depuracion.apk`.
- [ ] Rotación de secretos: no hecha (sigue en [[08 - Pendientes]]), así que no se verificó el 401 del token anterior.
- [x] Dossier, hoja de defensa, guía de fallos y lista previa en `evidencias/blindaje/`; sección de blindaje en el Reporte de avances.
- [x] `scripts/arreglo_rapido.sh` / `.ps1` probados; ensayo de 3 fallos: 1.9–2.4 min por ciclo (`evidencias/blindaje/ensayo/resumen.md`).
- [x] Tag `entrega-v1`.
- [ ] Consolidación de la memoria: **no se hace** porque faltan las Etapas 1 y 2.

## Resultados
Ver «Dossier de blindaje - CEOSMOS.md» y «Hoja de defensa.md» en `evidencias/blindaje/`.

---
Navegación: [[00 - Índice CEOSMOS]] · [[07 - Pruebas (Black, White, Red Box)]] · [[08 - Pendientes]] · [[09 - Decisiones técnicas]] · [[12 - Mapa de funciones]]
