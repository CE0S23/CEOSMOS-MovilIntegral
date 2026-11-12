
### p11yp12/p11/evidencias/fase5_red/s24_red_despues.txt
Fecha 2026-11-11T20:22:51.268212 · android BP4A.251205.006.S721BXXSEDZI1 · API http://localhost:8080/api

| Solicitud | Código HTTP | Tiempo (ms) | Tamaño (bytes) |
|---|---|---|---|
| 1 | 200 | 34.3 | 28851 |
| 2 | 200 | 14.5 | 28851 |
| 3 | 200 | 18.4 | 28851 |
| 4 | 200 | 17.1 | 28851 |
| 5 | 200 | 18.6 | 28851 |
| 6 | 200 | 17.7 | 28851 |
| 7 | 200 | 17.2 | 28851 |
| 8 | 200 | 16.9 | 28851 |
| 9 | 200 | 16.9 | 28851 |
| 10 | 200 | 17.1 | 28851 |

Promedio 18.9 ms · mín 14.5 · máx 34.3 · desv. estándar 5.5 · sin la 1.ª (conexión nueva) 17.2 ms · éxito 10/10 · tamaño prom. 28851 B (28.2 KB)

| descarga | origen/destino | bytes | tiempo (s) | Mbps |
|---|---|---|---|---|
| 1 | API local (USB, adb reverse) | 28851 | 0.016 | 14.16 |
| 2 | API local (USB, adb reverse) | 28851 | 0.018 | 12.65 |
| 3 | API local (USB, adb reverse) | 28851 | 0.021 | 10.83 |
| 1 | Sitio web CEOSMOS (Vercel, Wi-Fi + Internet) | 637412 | 0.571 | 8.93 |
| 2 | Sitio web CEOSMOS (Vercel, Wi-Fi + Internet) | 637412 | 0.431 | 11.83 |
| 3 | Sitio web CEOSMOS (Vercel, Wi-Fi + Internet) | 637412 | 0.359 | 14.20 |
Promedio API local (USB, adb reverse): 12.55 Mbps (agregado 12.40 Mbps; 0.019 s por transferencia)
Promedio Sitio web CEOSMOS (Vercel, Wi-Fi + Internet): 11.65 Mbps (agregado 11.24 Mbps; 0.454 s por transferencia)

| subida | origen/destino | bytes | tiempo (s) | Mbps |
|---|---|---|---|---|
| 1 | POST /api/focus-sessions (USB, adb reverse) | 3976 | 0.081 | 0.39 |
| 2 | POST /api/focus-sessions (USB, adb reverse) | 3976 | 0.028 | 1.12 |
| 3 | POST /api/focus-sessions (USB, adb reverse) | 3976 | 0.029 | 1.08 |
Promedio POST /api/focus-sessions (USB, adb reverse): 0.86 Mbps (agregado 0.69 Mbps; 0.046 s por transferencia)
interrupcion: {"tipo":"interrupcion","detectado":true,"ms_hasta_error":47.324,"mostrada_como_guardada":false,"pendientes":1,"aviso":"La sesión se guardará cuando vuelva la conexión (No hay conexión con el servidor de CEOSMOS. Revisa tu red.)"}
reintento_sin_red: {"tipo":"reintento_sin_red","pendientes":1,"error":"No hay conexión con el servidor de CEOSMOS. Revisa tu red."}
recuperacion: {"tipo":"recuperacion","s_hasta_reconectar":5.478,"pendientes":0,"sesiones_antes":0,"sesiones_despues":1,"duplicados":0,"sincronizada":true}
