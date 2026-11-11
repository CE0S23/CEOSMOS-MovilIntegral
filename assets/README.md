# Audios de demostración

Los tres MP3 fueron sintetizados específicamente para este proyecto con FFmpeg. No contienen música descargada, grabaciones de terceros ni voces.

- orbit.mp3: senoides a 130.81, 196 y 261.63 Hz.
- forest.mp3: ruido rosa filtrado; es una textura sintética, no una grabación de bosque.
- dawn.mp3: senoides a 174.61, 220 y 349.23 Hz.

Duración: 30 segundos. Compresión: MP3 96 kbps. Peso aproximado: 353 KiB por archivo, por debajo del límite de audio de 10 MB propuesto en el reporte. Entrada y salida de 2 segundos. El reproductor repite el archivo durante la sesión.

Generar de nuevo: `powershell -File scripts/generar_audio.ps1` (requiere FFmpeg).
