Ventana flotante real · Tab S9 (densidad 300) · release v2 (22/11, con las correcciones del día) · pantalla de Acceso
Resultado: en los 14 tamaños, sin recortes ni desbordes; el formulario se desplaza cuando no cabe.
- 1200x750 y 900x700: diseño de dos columnas (panel de marca + formulario).
- 700x500 a 500x300 (apaisadas bajas): una columna; en 500x300 solo cabe el encabezado y el formulario queda bajo el pliegue (se alcanza desplazando).
- 412x780 a 320x560: todo el formulario visible o a un desplazamiento.
- 300x500 a 240x420: título en dos líneas; campos tras desplazar. Usable.
- 240x320 y 220x380: se dibuja sin errores pero la cabecera ocupa casi toda la ventana; incómodo.
Mínimo cómodo: 260 x 440 dp. Mínimo funcional (sin errores): 220 x 380 dp.
Las pestañas con sesión iniciada se verificaron en el barrido automático de 91 tamaños (test/tamanos_pantalla_test.dart): sin desbordes desde 240 dp de ancho.
No verificado en el equipo: pestañas con sesión en ventana flotante (la tablet mostraba Acceso y no se usaron credenciales).
Hoja de contacto: hoja_contacto.png · tamaños pedidos y reales: tamanos.txt
