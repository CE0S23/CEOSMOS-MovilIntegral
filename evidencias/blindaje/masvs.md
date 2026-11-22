# Mapa OWASP MASVS v2 y Mobile Top 10 (2024) · 22/11/2026

Estado: **cumple** (con evidencia) · **parcial** · **riesgo aceptado** · **no aplica**.

## MASVS v2
| Control | Estado | Evidencia |
|---|---|---|
| STORAGE-1 Datos sensibles en almacenamiento seguro | cumple | JWT en `FlutterSecureStorage` (Keystore): `lib/data/token_store.dart`. SQLite y SharedPreferences guardan datos de funciones (sin credenciales) **sin cifrar**: riesgo aceptado |
| STORAGE-2 Sin fugas (registros, respaldos) | cumple | `allowBackup="false"`; 0 `debugPrint` con token o contraseña (grep); errores globales sin datos sensibles (`lib/core/errores_globales.dart`) |
| CRYPTO-1/2 Criptografía fuerte y bien gestionada | parcial | TLS 1.2+/HSTS; HMAC-SHA256 en el reto BLE; JWT solo HS256 (rama `blindaje-api`). **BLE sin cifrado de carga útil**: riesgo aceptado |
| AUTH-1 Autenticación en el servidor | cumple | JWT + sesión en BD; Red Box RB-01..03, RB-13..20, RB-47 (`redbox_api_entrega.txt`, `redbox_ampliado.txt`) |
| AUTH-2 Autorización por recurso y rol | cumple | IDOR → 403/404 (RB-05..07, 33, 34); USER en `/admin` y `/users` → 403 (RB-11, 35, 36); Firestore con reglas por propietario, salvo `mesaayuda-p7/dispositivos` (ver abajo) |
| AUTH-3 Sesión: expiración, cierre, reutilización | cumple | Token expirado → 401 (RB-14); tras logout → 401 (RB-13, RB-47) |
| NETWORK-1 Todo el tráfico cifrado | cumple | `network_security_config.xml`: sin texto claro salvo localhost; producción HTTP → 308 |
| NETWORK-2 Validación de certificados / interceptación | cumple | El cliente rechaza un certificado autofirmado y muestra un mensaje claro (`test/tls_rechazo_test.dart`, corregido el 22/11); no confía en CA de usuario. mitmproxy en el teléfono no se probó (exige cambiar el proxy del sistema) |
| PLATFORM-1 IPC y componentes exportados | cumple | Solo la actividad principal exportada (`AndroidManifest.xml`) |
| PLATFORM-2 WebViews | no aplica | No hay WebView propia; los enlaces abren el navegador |
| PLATFORM-3 Interfaz: datos sensibles en pantalla | parcial | Contraseña oculta con botón de mostrar; no se usa `FLAG_SECURE` (capturas permitidas) |
| CODE-1 Plataforma actualizada | cumple | targetSdk 36; Android 16/17 en los equipos |
| CODE-2 Dependencias | parcial | `pubspec.lock` fijo; 67 paquetes con versiones nuevas incompatibles; sin escáner de CVE |
| CODE-3 Validación de entradas | cumple | App y API (DTO whitelist); fuzzing RB-21..32 sin 500 tras las correcciones |
| CODE-4 Manejo de errores | cumple | `errores_globales.dart`; errores HTTP traducidos; API sin trazas (RB-43) |
| RESILIENCE-1..4 Anti-manipulación, ofuscación | riesgo aceptado | Dart compilado AOT a código nativo; sin `--obfuscate` ni detección de root |
| PRIVACY-1..4 | parcial | Solo los datos necesarios; datos en EE. UU.; sin aviso RGPD (ver `red/geografia.md`) |

## Mobile Top 10 (2024)
| Riesgo | Estado | Evidencia |
|---|---|---|
| M1 Uso indebido de credenciales | cumple | Sin secretos de servidor en el repo ni en el historial (gitleaks: `secretos_gitleaks.txt`); claves de Firebase de cliente, la de P7 restringida por referente (medido: `API_KEY_HTTP_REFERRER_BLOCKED`) |
| M2 Cadena de suministro | parcial | Versiones fijas; sin escáner de CVE (riesgo aceptado) |
| M3 Autenticación/autorización | cumple | ver AUTH; **hallazgo**: `mesaayuda-p7/dispositivos` se lee sin sesión (3 documentos de presencia: nombre, modelo, rol, última conexión) — regla pendiente del usuario |
| M4 Validación de entradas/salidas | cumple | RB-04, 08–10, 21–32; XSS guardado como texto y la app no interpreta HTML |
| M5 Comunicación insegura | cumple | NETWORK-1/2. Mensajería TCP en LAN en texto plano: riesgo aceptado (demostración local) |
| M6 Privacidad | parcial | ver PRIVACY |
| M7 Protección del binario | riesgo aceptado | AOT nativo; sin ofuscación |
| M8 Configuración incorrecta | cumple | `allowBackup=false`, release no depurable, cabeceras: HSTS, nosniff, DENY, referrer; CSP y CORS sin 500 en la rama `blindaje-api` |
| M9 Almacenamiento inseguro | cumple / aceptado | Token en Keystore; SQLite sin cifrar (sin credenciales) |
| M10 Criptografía insuficiente | parcial | HMAC en BLE sin cifrado de carga útil (aceptado); JWT HS256 fijo |

## Hallazgos corregidos el 22/11 (con prueba de regresión)
| # | Hallazgo | Dónde | Prueba |
|---|---|---|---|
| 1 | Token firmado con otra forma de carga útil o con HS512 → 500 | API `jwt.strategy.ts` | `src/blindaje.spec.ts`, RB-15..17 |
| 2 | CORS con origen ajeno → 500 (medido también en producción) | API `app.factory.ts` | RB-39, RB-40 |
| 3 | JSON anidado 5 000 niveles sin sesión → 500 (también en producción) | API, filtro de errores | `blindaje.spec.ts`, RB-31 |
| 4 | Sin Content-Security-Policy | API `app.factory.ts` | RB-41 |
| 5 | Medio IMAGE aceptaba `javascript:` y longitudes sin límite | API `media.dto.ts` | `blindaje.spec.ts`, RB-28 |
| 6 | El login revelaba si la cuenta existe («N intentos restantes») | API `auth.service.ts` | `p12-auth.spec.ts`, RB-44 |
| 7 | Certificado no confiable → excepción cruda en la app | `lib/data/api_client.dart` | `test/tls_rechazo_test.dart` |

Las correcciones de la API están en la rama `blindaje-api` del repo CEOSMOSV2 (commit 605776c), con 79/79 pruebas y Red Box 13/13 + 37/37 en local. **Producción todavía no las tiene**: hay que promoverlas (tarea del usuario). Rollback: volver a desplegar el commit anterior (`a4d8d6a`) o «Promote» del despliegue previo en Vercel.
