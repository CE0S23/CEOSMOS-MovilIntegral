#!/usr/bin/env bash
# Blindaje · red mínima MEDIDA por API (producción, solo lecturas, ≤ 1 petición/s).
# Pasa cada petición por scripts/red_degradada.js (latencia, ancho de banda,
# pérdida emulada y cortes) y anota código HTTP, bytes y tiempo total.
#   bash scripts/medir_red.sh > evidencias/blindaje/red/red_minima.tsv
# Las claves de cliente de Firebase se leen del código y nunca se imprimen.
cd "$(dirname "$0")/.."
KEY=$(grep -oE "AIza[0-9A-Za-z_-]{30,}" lib/practicas/p07/firebase_options.dart | head -1)
API_HOST=ceosmos-api.vercel.app
FS_HOST=firestore.googleapis.com
ID_HOST=identitytoolkit.googleapis.com
PUERTO=18443

# nombre | latencia por sentido (ms) | kbps | pérdida | corte (s)
PERFILES="
sin_degradar|0|0|0|0
4G|25|10000|0|0
3G|100|750|0|0
EDGE_2G|200|50|0|0
3G_perdida_5|100|750|0.05|0
3G_perdida_20|100|750|0.20|0
3G_cortes_3s|100|750|0|3
lat_1000|500|750|0|0
lat_2000|1000|750|0|0
lat_4000|2000|750|0|0
bw_20k|200|20|0|0
bw_10k|200|10|0|0
bw_5k|200|5|0|0
"

pedir() { # $1 nombre, $2 host, resto: argumentos de curl
  local nombre=$1 host=$2; shift 2
  curl -s -o /dev/null --max-time 30 --connect-to "$host:443:127.0.0.1:$PUERTO" \
    -w "$nombre\t%{http_code}\t%{size_download}\t%{time_total}\n" "$@" || true
}

printf "perfil\tendpoint\thttp\tbytes\tsegundos\n"
echo "$PERFILES" | while IFS='|' read -r perfil lat kbps perdida corte; do
  [ -z "$perfil" ] && continue
  for destino in "$API_HOST" "$FS_HOST" "$ID_HOST"; do
    node scripts/red_degradada.js $PUERTO "$destino" 443 --lat "$lat" --kbps "$kbps" --perdida "$perdida" --corte "$corte" >/dev/null &
    PID=$!; sleep 0.7
    case $destino in
      "$API_HOST")
        pedir "$perfil	api_health" "$destino" "https://$API_HOST/api/health"; sleep 1
        pedir "$perfil	api_devices_sin_token" "$destino" "https://$API_HOST/api/devices"; sleep 1 ;;
      "$FS_HOST")
        pedir "$perfil	firestore_reportes_sin_auth" "$destino" "https://$FS_HOST/v1/projects/reportes-movil-20261019/databases/(default)/documents/reportes?pageSize=1"; sleep 1
        pedir "$perfil	firestore_tickets_sin_auth" "$destino" "https://$FS_HOST/v1/projects/practica7-8-941cb/databases/(default)/documents/conversaciones?pageSize=1"; sleep 1 ;;
      "$ID_HOST")
        pedir "$perfil	firebase_auth_login_falso" "$destino" -X POST -H 'Content-Type: application/json' \
          -d '{"email":"no-existe-blindaje@example.com","password":"Incorrecta#1","returnSecureToken":true}' \
          "https://$ID_HOST/v1/accounts:signInWithPassword?key=$KEY"; sleep 1 ;;
    esac
    kill $PID 2>/dev/null; wait $PID 2>/dev/null
  done
done | sed 's/|/\t/'
