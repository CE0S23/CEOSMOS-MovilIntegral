# Validación de la entrega

Fecha: 8 de octubre de 2026. Entorno: Windows, Flutter 3.41.9 y Dart 3.11.5.

| Comprobación | Resultado |
| --- | --- |
| `flutter analyze --no-pub` | Sin observaciones |
| `flutter test --no-pub` | 11 pruebas aprobadas |
| `flutter build web --release --no-pub --no-web-resources-cdn` | Compilación correcta |
| `flutter build apk --debug --no-pub` | Compilación correcta |
| Navegador local | Acceso demo, Inicio, selección de 5 minutos, temporizador, reproducción de MP3, pausa, finalización e historial comprobados |
| Consola del navegador durante el recorrido | Sin errores ni advertencias registradas |

## Casos automatizados

1. Registro y normalización de correo; duplicados y contraseñas incorrectas rechazados.
2. Tiempo pausado excluido; finalización automática registrada una sola vez.
3. Favoritos, dispositivos, preferencias e historial aislados por cuenta; conservación tras logout en la misma ejecución y pérdida al reiniciar repositorio.
4. Caducidad del acceso y cierre de la sesión activa.
5. Cambio de ambiente guarda la sesión anterior; duración inválida no altera el estado.
6. Búsqueda por acentos, modo, tipo, favoritos y ausencia de resultados.
7. Validación de formulario y explicación de passkeys.
8. Recorrido móvil completo: demo → favorito → filtros → sesión → pausa → continuación → finalización → perfil → logout.
9–11. Navegación y simulación de dispositivos a 320, 768 y 1440 píxeles de ancho. El recorrido completo adicional se ejecuta a 390 píxeles.

Las pruebas detectaron desbordamientos en el banner de Inicio y las etiquetas; fueron corregidos antes del resultado de 11/11.

## Límites de la verificación

- El plugin de audio está sustituido por canales de prueba en widget tests; se comprobó además su reproducción real en navegador con el MP3 local.
- El APK está compilado, pero no se instaló ni ejecutó en un teléfono físico o emulador durante esta entrega.
- iOS y Windows incluyen estructura de proyecto; no se compilaron. iOS requiere macOS/Xcode y Windows requiere Visual Studio C++ (no instalado).
- `flutter doctor` advierte sobre licencias Android pendientes y versiones de herramientas XML del SDK; no impidieron generar el APK debug con los componentes ya disponibles. No se aceptaron licencias ni se instalaron herramientas adicionales.
- No hay validación contra API, base de datos, WebAuthn ni dispositivos reales, porque están fuera del alcance local solicitado.

## Artefactos

- `build/app/outputs/flutter-apk/app-debug.apk`: paquete Android de revisión, firmado con clave de depuración.
- `build/web/`: aplicación web compilada para servir por HTTP local.
- `pubspec.lock`: versiones de dependencias resueltas.
