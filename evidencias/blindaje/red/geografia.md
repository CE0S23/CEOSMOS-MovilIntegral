# Geografía · ¿funciona en cada continente? (medido el 22/11/2026)

**Método:** sondas públicas de Globalping (HTTPS real desde cada ciudad). Datos crudos: `globalping_api.json`, `globalping_firestore.json`, `globalping_dns_*.json`. «Total» = DNS + TCP + TLS + primera respuesta, en una petición nueva (sin conexión reutilizada).

| Continente | Ciudad (red) | API CEOSMOS `/api/health` | Firestore (lectura sin sesión → 403 esperado) | ¿Funciona? |
|---|---|---|---|---|
| Norteamérica | Los Ángeles, Búfalo (EE. UU.) | 200 · 137–258 ms | 403 · 304 ms | sí (medido) |
| Sudamérica | São Paulo, Campinas (Brasil) | 200 · 337–379 ms | 403 · 973 ms | sí (medido) |
| **Europa · España** | **Madrid (Oracle), Logroño (IONOS)** | **200 · 373–400 ms** | **403 · 783 ms (Madrid)** | **sí (medido)** |
| Europa | Helsinki (Finlandia) | 200 · 396 ms | — | sí (medido) |
| Asia | Singapur, Tokio | 200 · 572–697 ms | 403 · 238 ms (Tokio) | sí (medido) |
| África | Lagos (Nigeria), Johannesburgo | 200 · 652–763 ms | 403 · 2 068 ms (Lagos) | sí (medido) |
| Oceanía | Sídney (Australia) | 200 · 561–566 ms | 403 · 438 ms | sí (medido) |
| México (laptop, referencia) | — | 200 · 214–343 ms | 403 · 301 ms | sí (medido) |

Todas las respuestas están muy por debajo del timeout de 15 s y del mínimo medido en `red_minima.md`.

## Ubicación de los servicios
| Servicio | Región | Cómo se sabe |
|---|---|---|
| API (Vercel) | `iad1` (Washington D. C., EE. UU. Este) | medido: cabecera `X-Vercel-Id` |
| Base de datos (Neon) | `us-east-1` | medido: host de `DATABASE_URL` del `.env` local; que producción use el mismo host es **inferido** |
| Firestore (3 proyectos) | **no verificado** (no se puede leer sin sesión de la consola) | la red de borde de Google atiende desde cerca del usuario; la base vive en la región elegida al crear el proyecto |

## ¿Funcionaría en España / Europa?
**Sí, medido desde Madrid y Logroño (200 en 373–400 ms).** Además:
- **DNS e IPv4/IPv6:** la API solo publica IPv4 (sin AAAA, medido desde España y EE. UU.); Firestore sí tiene IPv6. En redes móviles europeas solo IPv6, Android traduce con 464XLAT/CLAT y NAT64 (inferido: es estándar en Android, no se probó una red solo IPv6).
- **Redes corporativas y portales cautivos:** todo va por HTTPS 443, que estas redes permiten. Con un portal cautivo sin aceptar, la app muestra «No hay conexión… Revisa tu red» (prueba de timeout). Un proxy que intercepte TLS es rechazado porque la app no confía en certificados de usuario (`network_security_config.xml`).
- **VPN y roaming:** solo cambian la ruta y la latencia; con RTT de hasta 4 s la API responde (medido con el proxy).
- **Formatos de fecha y número, zona horaria y horario de verano:** la API guarda en UTC (`createdAt` ISO 8601) y la app muestra con la hora local del dispositivo (inferido de la revisión del código; no se probó con el teléfono en hora de Madrid).
- **Idioma:** la interfaz está en español fijo; en un teléfono en inglés sigue en español.
- **RGPD:** los datos se guardan en EE. UU. (Vercel/Neon y Google). Para usuarios reales en la UE haría falta aviso de privacidad, base legal y cláusulas de transferencia (SCC); para la evaluación académica no aplica. **No es un bloqueo técnico.**
- **Google Play Services y Firebase en la UE:** disponibles sin restricción; los teléfonos de la UE los traen.
- **BLE (Reloj y TV):** es local, no depende de la región.
