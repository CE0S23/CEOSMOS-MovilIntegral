# Barrido de tamaños de ventana (prueba automática)

`flutter test test/tamanos_pantalla_test.dart` · densidad 1 · Acceso + 6 pestañas por tamaño.
✓ = sin desbordes · ✗n = n pantallas con desborde.

| alto \ ancho | 200 | 240 | 280 | 300 | 320 | 360 | 412 | 600 | 768 | 900 | 1024 | 1280 | 1600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **320** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **400** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **480** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **560** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **640** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **800** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **1000** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Detalle de desbordes
- 200x320: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x400: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x480: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x560: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x640: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x800: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x1000: Inicio: Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
