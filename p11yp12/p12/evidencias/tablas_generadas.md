### Antes (código original)

Archivo: `fase3_estres/antes_estres.json` · 20 s por escenario · lectura `/focus-sessions?limit=50`

| Escenario | Usuarios | Solicitudes | RPS | Prom. (ms) | P50 | P90 | P95 | P99 | Máx. | Errores | Códigos | CPU API prom./máx. (%) | RAM API máx. (MB) | Consultas SQL por solicitud |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| lectura | 1 | 2,063 | 103.1 | 9.7 | 9.2 | 11.4 | 12.1 | 14.8 | 46.6 | 0 % | 200×2063 | 94.9 / 116.1 | 140.3 | 3.1 |
| lectura | 5 | 4,254 | 212.4 | 23.5 | 21.9 | 29.1 | 32.7 | 45.6 | 64.6 | 0 % | 200×4254 | 174.1 / 212 | 222.2 | 3 |
| lectura | 10 | 3,370 | 168.2 | 59.4 | 55.5 | 85 | 92.2 | 112.2 | 138 | 0 % | 200×3370 | 151.8 / 188 | 231 | 3 |
| lectura | 25 | 4,150 | 206.4 | 121 | 114 | 147.2 | 168.7 | 236.2 | 256 | 0 % | 200×4150 | 167.9 / 200.3 | 239.1 | 3 |
| lectura | 50 | 4,301 | 214.1 | 232.9 | 226.2 | 254.1 | 281.5 | 396.6 | 438.3 | 0 % | 200×4301 | 166.1 / 197.4 | 249.6 | 3 |
| escritura | 1 | 2,097 | 104.8 | 9.5 | 9 | 10.9 | 11.7 | 15 | 50.6 | 0 % | 201×2097 | 87.4 / 118.2 | 252 | 4 |
| escritura | 5 | 3,686 | 184.2 | 27.1 | 24.8 | 37.3 | 42.2 | 58.3 | 146.4 | 0 % | 201×3686 | 148.8 / 192 | 250.6 | 3.9 |
| escritura | 10 | 4,224 | 210.6 | 47.4 | 43.7 | 62 | 71.7 | 91.1 | 123.5 | 0 % | 201×4224 | 159.7 / 200.7 | 247.6 | 4 |
| escritura | 25 | 3,956 | 197.3 | 126.5 | 116.7 | 166.2 | 183.9 | 217.9 | 237.4 | 0 % | 201×3956 | 156 / 193 | 248.5 | 4.1 |
| escritura | 50 | 4,356 | 216.9 | 230.1 | 220.6 | 258.4 | 307.6 | 346 | 365.1 | 0 % | 201×4356 | 162.2 / 196.5 | 254.1 | 4 |

Integridad: 18319 respuestas 201 = 18319 filas insertadas; clientId duplicados: 0.

### Después, misma petición (`?limit=50`)

Archivo: `fase6_optimizacion/despues_estres.json` · 20 s por escenario · lectura `/focus-sessions?limit=50`

| Escenario | Usuarios | Solicitudes | RPS | Prom. (ms) | P50 | P90 | P95 | P99 | Máx. | Errores | Códigos | CPU API prom./máx. (%) | RAM API máx. (MB) | Consultas SQL por solicitud |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| lectura | 1 | 3,009 | 150.4 | 6.6 | 6.4 | 8.1 | 8.4 | 9.6 | 23.9 | 0 % | 200×3009 | 88.7 / 117.1 | 270.4 | 2 |
| lectura | 5 | 5,979 | 298.8 | 16.7 | 15.9 | 21.4 | 24.6 | 34.8 | 61.5 | 0 % | 200×5979 | 153.9 / 194.2 | 270.1 | 2 |
| lectura | 10 | 5,323 | 265.9 | 37.6 | 36.9 | 46.9 | 51.6 | 65.5 | 77.5 | 0 % | 200×5323 | 152.2 / 201.5 | 270.7 | 2 |
| lectura | 25 | 6,650 | 331.9 | 75.2 | 74.3 | 86.9 | 94 | 109.1 | 153.6 | 0 % | 200×6650 | 156.1 / 188.7 | 284.1 | 2 |
| lectura | 50 | 6,630 | 329.4 | 151.3 | 149 | 170.5 | 183.4 | 208.4 | 269.7 | 0 % | 200×6630 | 159.8 / 181.7 | 294.8 | 2 |
| escritura | 1 | 3,824 | 191.2 | 5.2 | 4.9 | 6.4 | 7.4 | 10.7 | 34.3 | 0 % | 201×3824 | 84.9 / 104.7 | 296.8 | 2.9 |
| escritura | 5 | 7,238 | 361.8 | 13.8 | 12.4 | 17.9 | 21.4 | 27.6 | 49.7 | 0 % | 201×7238 | 152 / 189.2 | 286.2 | 3 |
| escritura | 10 | 7,296 | 364.5 | 27.4 | 26.8 | 32.8 | 35.5 | 45.2 | 68 | 0 % | 201×7296 | 150.1 / 182.7 | 286.2 | 3.1 |
| escritura | 25 | 7,217 | 360.2 | 69.3 | 67.5 | 79.1 | 85.7 | 103.1 | 120.6 | 0 % | 201×7217 | 149.7 / 175.8 | 293 | 3 |
| escritura | 50 | 7,012 | 349.4 | 142.8 | 141.5 | 166.7 | 171.1 | 184.4 | 191.7 | 0 % | 201×7012 | 148.4 / 170 | 303.3 | 3 |

Integridad: 32587 respuestas 201 = 32587 filas insertadas; clientId duplicados: 0.

### Después, petición que hace la app optimizada (`?limit=20`)

Archivo: `fase6_optimizacion/despues_estres_app.json` · 20 s por escenario · lectura `/focus-sessions?limit=20`

| Escenario | Usuarios | Solicitudes | RPS | Prom. (ms) | P50 | P90 | P95 | P99 | Máx. | Errores | Códigos | CPU API prom./máx. (%) | RAM API máx. (MB) | Consultas SQL por solicitud |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| lectura | 1 | 5,194 | 259.7 | 3.8 | 3.6 | 4.6 | 5.3 | 6.9 | 32.8 | 0 % | 200×5194 | 93.8 / 108.9 | 298.6 | 2 |
| lectura | 5 | 7,977 | 398.6 | 12.5 | 11.5 | 17.2 | 19.2 | 25.8 | 138 | 0 % | 200×7977 | 146.6 / 177.2 | 298.2 | 2 |
| lectura | 10 | 8,648 | 432.1 | 23.1 | 22.7 | 29.5 | 32.5 | 40.2 | 68.6 | 0 % | 200×8648 | 149.7 / 181.7 | 288.8 | 2 |
| lectura | 25 | 8,502 | 424.3 | 58.9 | 56.2 | 74.1 | 84.9 | 94.4 | 113.1 | 0 % | 200×8502 | 152.2 / 181 | 294.9 | 2 |
| lectura | 50 | 5,502 | 274.3 | 182 | 156.9 | 278.8 | 330.2 | 380.7 | 497.8 | 0 % | 200×5502 | 135.3 / 172.1 | 305.9 | 2 |

Integridad: 0 respuestas 201 = 0 filas insertadas; clientId duplicados: 0.

### Comparación por escenario (antes → después)

| Escenario | Usuarios | RPS antes → después (50) → app (20) | Prom. ms | P95 ms | Errores |
| --- | --- | --- | --- | --- | --- |
| lectura | 1 | 103.1 → 150.4 (+45.9 %) → 259.7 (+151.9 %) | 9.7 → 6.6 → 3.8 | 12.1 → 8.4 → 5.3 | 0 → 0 % |
| lectura | 5 | 212.4 → 298.8 (+40.7 %) → 398.6 (+87.7 %) | 23.5 → 16.7 → 12.5 | 32.7 → 24.6 → 19.2 | 0 → 0 % |
| lectura | 10 | 168.2 → 265.9 (+58.1 %) → 432.1 (+156.9 %) | 59.4 → 37.6 → 23.1 | 92.2 → 51.6 → 32.5 | 0 → 0 % |
| lectura | 25 | 206.4 → 331.9 (+60.8 %) → 424.3 (+105.6 %) | 121 → 75.2 → 58.9 | 168.7 → 94 → 84.9 | 0 → 0 % |
| lectura | 50 | 214.1 → 329.4 (+53.9 %) → 274.3 (+28.1 %) | 232.9 → 151.3 → 182 | 281.5 → 183.4 → 330.2 | 0 → 0 % |
| escritura | 1 | 104.8 → 191.2 (+82.4 %) | 9.5 → 5.2 | 11.7 → 7.4 | 0 → 0 % |
| escritura | 5 | 184.2 → 361.8 (+96.4 %) | 27.1 → 13.8 | 42.2 → 21.4 | 0 → 0 % |
| escritura | 10 | 210.6 → 364.5 (+73.1 %) | 47.4 → 27.4 | 71.7 → 35.5 | 0 → 0 % |
| escritura | 25 | 197.3 → 360.2 (+82.6 %) | 126.5 → 69.3 | 183.9 → 85.7 | 0 → 0 % |
| escritura | 50 | 216.9 → 349.4 (+61.1 %) | 230.1 → 142.8 | 307.6 → 171.1 | 0 → 0 % |

### App en el emulador (antes)

CPU prom. 35 %, máx. 76.8 % · PSS inicial 140.6 MB, máx. 193.4 MB, final 193.4 MB

| Fase | Duración (s) | CPU prom. (%) | CPU máx. (%) | PSS máx. (MB) | Mayor bloqueo del hilo UI (ms) | Bloqueos > 50 ms |
| --- | --- | --- | --- | --- | --- | --- |
| carga_inicial | 1.4 | 14.5 | 22.7 | 148.1 | 42.7 | 0 |
| consulta_repetida | 1.5 | 25.3 | 39.8 | 152.8 | 101.6 | 3 |
| escritura | 0.1 | 39.8 | 39.8 | 152.8 | 5 | 0 |
| navegacion | 59 | 50.7 | 76.8 | 192.8 | 265.9 | 54 |
| procesamiento | 0.1 | 54.2 | 54.2 | 184.6 | 2.5 | 0 |
| sesion_en_curso_reposo | 41.2 | 14 | 27 | 192.4 | 41.1 | 0 |

Carga inicial 1406 ms (50 sesiones) · recarga prom. 40.5 ms (P95 83.5) · historial prom. 21.4 ms · guardar sesión prom. 11.5 ms · procesar 100 sesiones 1.2 ms · navegación 1649 cuadros (build prom. 2.3 ms, raster prom. 14.5 ms) · reposo con sesión: 42 cuadros, build prom. 8.1 ms, total 340.8 ms

### App en el emulador (después)

CPU prom. 32.4 %, máx. 77.8 % · PSS inicial 141.3 MB, máx. 186.2 MB, final 185.1 MB

| Fase | Duración (s) | CPU prom. (%) | CPU máx. (%) | PSS máx. (MB) | Mayor bloqueo del hilo UI (ms) | Bloqueos > 50 ms |
| --- | --- | --- | --- | --- | --- | --- |
| carga_inicial | 0.7 | 15.9 | 24.9 | 142.7 | 5.2 | 0 |
| consulta_repetida | 1.2 | 29.4 | 33.8 | – | 48.6 | 0 |
| escritura | 0.1 | 33.8 | 33.8 | – | 3 | 0 |
| navegacion | 53.4 | 48.4 | 77.8 | 186.2 | 337.2 | 25 |
| procesamiento | 0.2 | 18.5 | 28.9 | 176.1 | 12.8 | 0 |
| sesion_en_curso_reposo | 40.9 | 12.6 | 28.9 | 184.7 | 31.2 | 0 |

Carga inicial 680 ms (20 sesiones) · recarga prom. 34.3 ms (P95 56.6) · historial prom. 15.9 ms · guardar sesión prom. 10.4 ms · procesar 100 sesiones 2.1 ms · navegación 1613 cuadros (build prom. 1.9 ms, raster prom. 14.6 ms) · reposo con sesión: 42 cuadros, build prom. 2 ms, total 84 ms

