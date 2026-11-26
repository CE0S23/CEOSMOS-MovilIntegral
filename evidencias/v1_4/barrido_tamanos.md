# Barrido de tamaños de ventana (prueba automática)

`flutter test test/tamanos_pantalla_test.dart` · densidad 1 · Acceso + Inicio con la tarjeta «Tu Reloj y TV» cargada (Reloj y TV conectados, alerta, TV proyectando) + 6 pestañas por tamaño (1.4.0).
✓ = sin desbordes · ✗n = n pantallas con desborde.

| alto \ ancho | 200 | 240 | 280 | 300 | 320 | 360 | 412 | 600 | 768 | 900 | 1024 | 1280 | 1600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **320** | ✗3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **400** | ✗3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **480** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **560** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **640** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **800** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **1000** | ✗2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Detalle de desbordes
- 200x320: Inicio (tarjeta Reloj y TV): Multiple exceptions (3) were detected during the running of ; Equipos: A RenderFlex overflowed by 16 pixels on the right.; Perfil: Multiple exceptions (5) were detected during the running of 
- 200x400: Inicio (tarjeta Reloj y TV): Multiple exceptions (3) were detected during the running of ; Equipos: A RenderFlex overflowed by 16 pixels on the right.; Perfil: Multiple exceptions (5) were detected during the running of 
- 200x480: Inicio (tarjeta Reloj y TV): Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x560: Inicio (tarjeta Reloj y TV): Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x640: Inicio (tarjeta Reloj y TV): Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x800: Inicio (tarjeta Reloj y TV): Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
- 200x1000: Inicio (tarjeta Reloj y TV): Multiple exceptions (2) were detected during the running of ; Perfil: Multiple exceptions (4) were detected during the running of 
