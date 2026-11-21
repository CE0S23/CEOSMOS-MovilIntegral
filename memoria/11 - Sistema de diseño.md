---
tags: [ceosmos, diseño, ui]
estado: vigente
actualizado: 2026-11-21
---

# 11 · Sistema de diseño

Rediseño **solo estético** del 21/11/2026 para CEOSMOS Integral (Flutter), las prácticas
(Flutter y nativas P9/P10/BD) y las apps compañeras Reloj y TV (Kotlin/Compose).
Sin cambios de lógica, navegación, textos, claves ni servicios.

## Dónde vive
| Plataforma | Archivo |
|---|---|
| Flutter (app + prácticas) | `lib/core/theme/` → `colores.dart`, `paleta.dart` (ThemeExtension `CeosmosPaleta`, `context.paleta` / `context.texto`), `tipografia.dart`, `medidas.dart`, `tema.dart` (`CeosmosTema.claro` / `.oscuro`), `curvas.dart` |
| Reloj y TV | `companion/app/src/main/java/com/ceosmos/companion/TemaCeosmos.kt` |
| Prácticas nativas | `android/app/src/main/kotlin/com/ceosmos/practicas/TemaCeosmos.kt` + estilo `CeosmosPracticas` (`res/values*/styles.xml`) |
| Fuentes | `assets/fonts/` (Flutter), `res/font/` (Kotlin); licencias OFL en `assets/fonts/OFL-*.txt` y `companion/licencias-fuentes/` |
| Contraste | `tool/contraste/` (script, pares y `resultado.txt`) |
| Capturas | `evidencias/rediseno/antes_*.png` / `despues_*.png` (arnés `tool/capturas/capturas_test.dart`) |

## Paleta
**Base:** cian `#51D7FD` · guinda `#5B011D`

**Complementarios:** cianOscuro `#0A7FA3` · cianClaro `#DDF7FF` · guindaMedio `#8A1C3D` · guindaClaro `#F6E4EA` · ámbar `#FFB547`
fondo `#FFF8F3` · superficie `#FFFFFF` · tinta `#1E0A12` · textoSecundario `#6B5A60` · borde `#EADDE1`

**Estados:** éxito `#1F9E6E` · advertencia `#E89B12` · error `#D62F45` · info `#0A7FA3`

**Oscuro:** fondo `#16060D` · superficie `#24101A` · superficieAlta `#321623` · tinta `#FCEFF3` · textoSecundario `#C9B3BB` · primary `#51D7FD` · secondary `#F2A3BA` · borde `#4A2635`

### Ajustes de contraste (WCAG AA, verificados con `tool/contraste/contraste.py`)
| Combinación que fallaba | Ratio | Ajuste | Ratio nuevo |
|---|---|---|---|
| cianOscuro `#0A7FA3` como texto sobre crema / cianClaro | 4.36 / 4.11 | **cianTexto `#08708F`** para texto, íconos y enlaces | 5.36 / 5.05 |
| éxito `#1F9E6E` texto sobre blanco | 3.40 | **`#17805A`** (texto); `#1F9E6E` solo de relleno | 4.92 |
| advertencia `#E89B12` sobre blanco | 2.30 | **`#9A5800`** (texto e íconos) | 5.57 |
| error `#D62F45` sobre crema | 4.59 (justo) | **`#C42A3F`** para texto (también AA sobre su fondo suave) | 5.33 |
| error `#D62F45` en modo oscuro | 3.74 | **`#FF7A8C`** | 7.23 |
| borde `#EADDE1` en inputs (3:1) | 1.32 | **bordeControl `#8C7880`** (claro) / `#8E6A79` (oscuro); `#EADDE1` queda para tarjetas | 4.11 / 3.86 |
| ámbar `#FFB547` como texto/ícono | 1.76 | Solo de fondo con texto guinda (8.15) | — |

## Reglas de uso
- Texto sobre cian → **guinda**. Texto sobre guinda → **blanco o cian**.
- Botón primario: guinda + blanco (oscuro: `#F2A3BA` + guinda). Hover/pressed: guindaMedio. Foco: anillo cian (2.5 px).
- Botón secundario (`OutlinedButton`/`ElevatedButton`): fondo cian + texto guinda. Terciario (`TextButton`): texto cianTexto sin fondo.
- Sobre escenas oscuras (hero del Inicio, sesión) el botón principal va en cian para no perderse.
- Encabezados: **fondo crema con título guinda** en toda la app (AppBar de las prácticas incluido). La barra «← Prácticas» y la barra de sesión en curso son guinda con texto blanco y acento cian.
- Error ≠ guinda: siempre **ícono + texto** (widget `Aviso` en Flutter; ícono en `EstadoConexion` del companion).
- Ámbar con mesura: insignia ADMIN y la intención «Inspiración».
- Intenciones: Enfoque = guinda, Relajación = cian, Inspiración = ámbar (en sus variantes legibles).
- Patrón de curvas guinda sobre cian (`CurvasCeosmos`): splash, franja del acceso y panel lateral del acceso en pantallas anchas. Nunca detrás de texto largo.

## Tipografía y escala
- **Bricolage Grotesque** 700/800 (títulos y números grandes, tracking negativo); **DM Sans** 400/500/700 (texto, botones, formularios).
- Empaquetadas (sin descarga en tiempo de ejecución).

| Estilo | Flutter | Reloj | TV |
|---|---|---|---|
| displayLarge | Bricolage 800 · 56 | 46 | 120 (contador) |
| displayMedium | 44 | 36 | 64 (PIN) |
| displaySmall | 36 | — | 52 |
| headlineLarge | 34 | — | 44 |
| headlineMedium | 28 | — | — |
| headlineSmall | 24 | 24 | 26 |
| titleLarge | Bricolage 700 · 21 | 18 | 22 |
| titleMedium / Small | DM Sans 700 · 16 / 14 | 14 | 20 |
| bodyLarge / Medium / Small | DM Sans 400 · 16 / 14 / 12 | 14 / 12 / 11 | 22 / 18 / 14 |
| labelLarge / Medium / Small | DM Sans 700/500/700 · 14 / 12 / 11 | 13 / 12 / 11 | 24 / 16 / 14 |

Espaciado 4/8/12/16/24/32 (`Espacio`), radios 12/16/20 + píldora (`Radios`), sombras suaves teñidas de guinda (`Sombra`).

## Verificación (21/11/2026)
- [x] `flutter analyze` sin issues · `flutter test` 215/215 · `./gradlew test lint` (companion) verde · `flutter build apk --debug` OK.
- [x] Capturas antes/después (claro y oscuro) generadas con la API simulada.
- [x] Recorrido en S24 y Tab S9 (21/11, claro y oscuro) junto con la reestructura; ajustes de TV y tema nativo oscuro detallados en [[12 - Mapa de funciones]].

---
Navegación: [[00 - Índice CEOSMOS]] · [[10 - Bitácora]] · [[09 - Decisiones técnicas]]
