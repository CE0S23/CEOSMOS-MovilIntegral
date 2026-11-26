#!/usr/bin/env bash
# 1.4.0 · Medición de las alertas de salud en equipos reales (sin monkey ni estrés).
# El Reloj (app al frente en la tablet) pasa a Reposo 20 s, luego al modo de la alerta
# y se mide desde el registro «Simulación: <modo>» hasta «CEOSMOS → Reloj: Alerta» (ambos
# en el logcat de la tablet, mismo reloj). CEOSMOS en el teléfono conectado al Reloj y con
# las alertas activadas. Antes de cada toque se vuelve a leer la pantalla.
#
# Uso: bash scripts/medir_alertas.sh <serie-tablet> <N=10> <plazo_s=70> [casos]
#   casos por omisión: "alta:alta:alto muy_alta:muy_alta:muy_alto baja:baja:bajo"
#   (nombre:modo:alerta esperada). Companion anterior, sin el modo «muy alta»:
#   "alta:alta:alto muy_alta:alta:muy_alto baja:baja:bajo".
set -u
export MSYS_NO_PATHCONV=1 PYTHONIOENCODING=utf-8
T="${1:?serie de la tablet}"; N="${2:-10}"; PLAZO="${3:-70}"
CASOS="${4:-alta:alta:alto muy_alta:muy_alta:muy_alto baja:baja:bajo}"
A=(adb -s "$T")

dump() { "${A[@]}" shell uiautomator dump /sdcard/ceosmos_ui.xml >/dev/null 2>&1; "${A[@]}" exec-out cat /sdcard/ceosmos_ui.xml; }
centro() { dump | python -c '
import re,sys
x=sys.stdin.buffer.read().decode("utf-8","replace")
m=re.search(r"<node [^>]*resource-id=\"%s\"[^>]*bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"" % sys.argv[1], x)
if m: a,b,c,d=map(int,m.groups()); print((a+c)//2,(b+d)//2)' "$1"; }
alerta_visible() { dump | python -c '
import re,sys,html
x=html.unescape(sys.stdin.buffer.read().decode("utf-8","replace"))
m=re.search(r"Pulso (muy alto|alto|bajo)", x)
print(m.group(1).replace(" ", "_") if m else "")'; }
tocar() { local xy; xy=$(centro "modo-$1"); [ -n "$xy" ] || { echo "sin botón modo-$1"; return 1; }; "${A[@]}" shell input tap $xy; }
ms() { "${A[@]}" logcat -d -v epoch -s CeosmosCompanion:I | grep -F "$1" | tail -1 | awk '{split($1,a,"."); print a[1]*1000+substr(a[2]"000",1,3)}'; }

echo "Medición de alertas · $(date '+%F %T') · N=$N · plazo ${PLAZO}s · casos: $CASOS"
for r in $(seq 1 "$N"); do
  for c in $CASOS; do
    IFS=: read -r nombre modo esperado <<< "$c"
    tocar reposo || exit 3; sleep 20
    "${A[@]}" logcat -c
    tocar "$modo" || exit 3
    t0=""; for k in 1 2 3 4 5; do sleep 0.5; t0=$(ms "Simulación:"); [ -n "$t0" ] && break; done
    lat="FALLÓ"; vistos=""
    fin=$(( $(date +%s) + PLAZO ))
    n_prev=0
    while [ "$(date +%s)" -lt "$fin" ]; do
      sleep 1
      n=$("${A[@]}" logcat -d -s CeosmosCompanion:I | grep -c "CEOSMOS → Reloj: Alerta")
      if [ "$n" -gt "$n_prev" ]; then
        n_prev=$n; tipo=$(alerta_visible); vistos="$vistos $tipo"
        if [ "$tipo" = "$esperado" ]; then
          t1=$(ms "CEOSMOS → Reloj: Alerta"); lat=$(( (t1 - t0) )); break
        fi
      fi
    done
    echo "ronda $r · $nombre · modo $modo · esperado $esperado · latencia_ms $lat · alertas vistas:${vistos:- ninguna}"
  done
done
tocar reposo
