# Red mínima por API · medido el 22/11/2026

**Método:** `scripts/red_degradada.js` (proxy TCP en la laptop, TLS intacto de punta a punta) + `scripts/medir_red.sh`. Cada petición se hizo contra **producción**, solo lecturas, 1 petición/s. Datos crudos: `red_minima.tsv`. La «pérdida» se **emula** retrasando un RTO de 1 s el fragmento perdido (como una retransmisión TCP); no es pérdida real de paquetes. Base desde México sin degradar: API 0.26 s (primer arranque en frío: 2.4 s), Firestore 0.30–0.52 s y Firebase Auth 0.17 s.

| Perfil (RTT añadido · ancho de banda) | API CEOSMOS `/health` y `/devices` | Firestore (lectura) | Firebase Auth (login) |
|---|---|---|---|
| 4G (50 ms · 10 Mbps) | 0.42–0.45 s | 0.70 s (1 de 2 falló en el arranque del proxy) | 0.32 s |
| 3G (200 ms · 750 kbps) | 0.93–0.95 s | 1.08–1.19 s | 0.80 s |
| EDGE / 2G (400 ms · 50 kbps) | 2.46–2.48 s | 2.35–2.41 s | 2.31 s |
| 3G + 5 % de pérdida | 0.97–1.99 s | 1.14–3.07 s | 1.80 s |
| 3G + 20 % de pérdida | 3.95–4.95 s | 2.13–4.02 s | 2.79 s |
| 3G con corte cada 3 s | 0.93–0.94 s (termina antes del corte) | 0.88–1.04 s | 0.81 s |
| RTT 1 s | 3.33–3.34 s | 3.43–3.47 s | 3.21 s |
| RTT 2 s | 6.33 s | 6.23–6.47 s | 6.19 s |
| **RTT 4 s** | **12.3–12.4 s (responde)** | **falla a los 10 s** | **falla a los 10 s** |
| 20 kbps (RTT 400 ms) | 3.92–3.94 s | 3.60–3.75 s | 3.63 s |
| 10 kbps | 6.36–6.39 s | 5.60–5.74 s | 5.97 s |
| **5 kbps** | **11.36 s** | **9.70–9.84 s** | **10.56 s** |

## Mínimos
| API | Ancho de banda mínimo | Latencia máxima (RTT) | Timeout | Por debajo del mínimo |
|---|---|---|---|---|
| API CEOSMOS (respuestas pequeñas) | **5 kbps** medido (11.4 s) | **4 s** medido (12.4 s) | 15 s en la app (`ApiClient`, un solo plazo) | Aviso «El servidor de CEOSMOS tardó demasiado en responder. Intenta de nuevo.»; las sesiones de enfoque quedan pendientes y se reenvían sin duplicar (`clientId`) |
| API CEOSMOS (historial de 50 sesiones, 24–28 KB) | ≈ 20 kbps **calculado** (28 KB a 20 kbps ≈ 11 s + 4 s de saludo) | 4 s | 15 s | igual |
| Firestore | **5 kbps** medido (9.8 s) | entre 2 s (OK) y 4 s (falla): el servidor de Google corta el saludo TLS a los ~10 s | del SDK | Caché local: las pantallas siguen con los datos guardados y sincronizan al volver la red (P9, tablet sin red) |
| Firebase Auth | **5 kbps** medido (10.6 s) | entre 2 s y 4 s | del SDK | Mensaje de error del inicio de sesión de esa función |

**Conclusión:** la app funciona en EDGE/2G (≈ 2.5 s por petición), con 20 % de pérdida (≤ 5 s) y con cortes intermitentes si la petición cabe entre cortes. El límite real lo pone la latencia: con RTT de 4 s la API todavía responde dentro de los 15 s, pero Firebase no.

Nota: Firebase Auth respondió 403 a la petición desde la laptop con `API_KEY_HTTP_REFERRER_BLOCKED`: la clave de cliente de `practica7-8` está **restringida por referente HTTP**, así que no se puede usar desde fuera de sus orígenes permitidos; la medición de tiempo sigue siendo válida (viaje completo al servidor de Google).
