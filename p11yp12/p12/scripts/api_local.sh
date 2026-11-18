#!/usr/bin/env bash
# Práctica 12 · Arranca la API de CEOSMOS SOLO contra la base local (.devdb, 127.0.0.1:5433).
# Nunca contra Neon: DATABASE_URL/DIRECT_URL se fijan aquí y dotenv no las sobrescribe.
#   bash api_local.sh <archivo_log>
# Con P12_PERFIL_DISPARO y P12_PERFIL_SALIDA definidos carga el profiler de CPU
# (perfil_cpu_preload.js), que se activa al crear el archivo de disparo.
# THROTTLE_LIMIT (6000 por omisión; 10000000 en la prueba de capacidad) solo en este entorno
# de pruebas: las rutas /auth siguen en 10/min y producción conserva 120/min.
API="${CEOSMOS_API:-/c/Users/cesar/OneDrive/Escritorio/8°/DesarrolloWEB/WEBANGULAR/ceosmos-api}"
LOG="${1:?falta archivo de log}"
AQUI="$(cd "$(dirname "$0")" && pwd -W 2>/dev/null || pwd)"
export DATABASE_URL='postgresql://ceosmos@127.0.0.1:5433/ceosmos_dev'
export DIRECT_URL="$DATABASE_URL"
export PORT=8080 THROTTLE_LIMIT="${THROTTLE_LIMIT:-6000}"
cd "$API" || exit 1
if [ -n "$P12_PERFIL_DISPARO" ]; then
  exec node -r "$AQUI/perfil_cpu_preload.js" dist/main.js >"$LOG" 2>&1
fi
exec node dist/main.js >"$LOG" 2>&1
