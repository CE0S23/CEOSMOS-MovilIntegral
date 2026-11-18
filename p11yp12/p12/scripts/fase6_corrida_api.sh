#!/usr/bin/env bash
# Práctica 12 · Una sola corrida secuencial de las mediciones de la API (para antes o después):
#   1) profiling de CPU con 10 usuarios de lectura + pg_stat_statements
#   2) estrés completo (lectura y escritura, 1–50 usuarios) con la petición de comparación
#   3) opcional: solo lectura con la petición que hace la app (P12_LECTURA_APP)
#   bash fase6_corrida_api.sh <prefijo_salida> <tokens.json> <archivo_disparo_perfil>
# Requisitos: API ya arrancada con api_local.sh (THROTTLE_LIMIT=10000000 y el preload del
# profiler) y NADA más ejecutándose en el equipo (ni emulador ni otras cargas).
set -u
PREF="$1"; TOKENS="$2"; DISPARO="$3"
cd "$(dirname "$0")/../../.."
PSQL="/c/Program Files/PostgreSQL/16/bin/psql.exe"
PID=$(netstat -ano | grep ":8080 .*LISTENING" | awk '{print $5}' | head -1)
reset() { "$PSQL" -h 127.0.0.1 -p 5433 -U ceosmos -d ceosmos_dev -Atc "select pg_stat_statements_reset()" >/dev/null; }
stats() { "$PSQL" -h 127.0.0.1 -p 5433 -U ceosmos -d ceosmos_dev -c "select calls, round(mean_exec_time::numeric,3) as prom_ms, round(total_exec_time::numeric,1) total_ms, rows, left(regexp_replace(query,'\s+',' ','g'),120) consulta from pg_stat_statements where dbid=(select oid from pg_database where datname='ceosmos_dev') order by calls desc limit 8" > "$1"; }
echo "API pid $PID"
reset
# El profiler (Node en Windows) necesita la ruta en formato C:/…
( sleep 11; echo "$(cygpath -m "${PREF}")_api.cpuprofile" > "$DISPARO" ) &
P12_VUS=10 P12_SOLO=lectura P12_DUR=20 node p11yp12/p12/scripts/fase3_estres.js http://127.0.0.1:8080/api "$PID" "$TOKENS" "${PREF}_api_perfil_carga.json" perfil 2>&1 | grep -v muestreador
stats "${PREF}_api_perfil_pg_stat_statements.txt"
sleep 8
node p11yp12/p12/scripts/analizar_cpuprofile.js "${PREF}_api.cpuprofile" "${PREF}_api_cpuprofile_resumen.txt" > /dev/null
reset
node p11yp12/p12/scripts/fase3_estres.js http://127.0.0.1:8080/api "$PID" "$TOKENS" "${PREF}_estres.json" estres 2>&1 | grep -v muestreador | tee "${PREF}_estres_salida.txt"
stats "${PREF}_estres_pg_stat_statements.txt"
if [ -n "${P12_LECTURA_APP:-}" ]; then
  P12_SOLO=lectura P12_LECTURA="$P12_LECTURA_APP" node p11yp12/p12/scripts/fase3_estres.js http://127.0.0.1:8080/api "$PID" "$TOKENS" "${PREF}_estres_app.json" estres-app 2>&1 | grep -v muestreador | tee "${PREF}_estres_app_salida.txt"
fi
echo FIN
