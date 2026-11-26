#!/usr/bin/env bash
# 1.4.0 · Medición de los botones del Reloj y la TV (Fase 3), sin monkey ni estrés:
# N pulsaciones por botón con 1,2 s entre una y otra; antes de CADA toque se vuelve a
# leer la pantalla (uiautomator dump) y se busca el botón por su resource-id/texto.
# Requisitos: CEOSMOS conectado al Reloj y a la TV (teléfono), app Reloj o TV al frente
# en la tablet. No escribe nada en el teléfono ni toca credenciales.
#
# Uso: bash scripts/medir_botones.sh <serie-tablet> <reloj|tv> [N=50] > evidencias/v1_4/botones_<etapa>_<rol>.txt
#
# Resultado por botón: pulsaciones, confirmadas (GATT), fallidas, sin respuesta y
# latencia pulsación→confirmación (mediana y p95) a partir de las líneas «MEDICION»
# del companion 1.4.0. Con un companion ANTERIOR (sin esas líneas) solo se puede contar
# las pulsaciones (la confirmación GATT no queda registrada): la columna «antes» de la
# tabla se toma con la reacción visible en CEOSMOS, contada a mano o por captura.
set -u
SERIE="${1:?serie de la tablet}"; ROL="${2:?reloj|tv}"; N="${3:-50}"
A=(adb -s "$SERIE")
case "$ROL" in
  reloj) PAQ=com.ceosmos.companion.reloj; BOTONES=("accion");;
  tv)    PAQ=com.ceosmos.companion.tv;    BOTONES=("tv-▶ Reanudar|tv-❚❚ Pausar" "tv-Siguiente ▶" "tv-◀ Anterior");;
  *) echo "rol inválido"; exit 2;;
esac
"${A[@]}" shell pidof "$PAQ" >/dev/null || { echo "La app $PAQ no está abierta en $SERIE"; exit 3; }

centro() { # $1 = patrón de resource-id (alternativas con |); imprime "x y" o nada
  "${A[@]}" shell uiautomator dump /sdcard/ceosmos_ui.xml >/dev/null 2>&1
  "${A[@]}" exec-out cat /sdcard/ceosmos_ui.xml | python -c '
import re,sys
xml=sys.stdin.read(); pats=sys.argv[1].split("|")
for m in re.finditer(r"<node [^>]*>", xml):
    n=m.group(0)
    rid=re.search(r"resource-id=\"([^\"]*)\"", n); b=re.search(r"bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"", n)
    en=re.search(r"enabled=\"(true|false)\"", n)
    if rid and b and rid.group(1) in pats and (not en or en.group(1)=="true"):
        x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break
' "$1"
}

echo "Medición de botones · $ROL · $(date '+%F %T') · N=$N por botón · tablet $SERIE"
"${A[@]}" logcat -c
for b in "${BOTONES[@]}"; do
  pulsadas=0; sin_boton=0
  for i in $(seq 1 "$N"); do
    xy=$(centro "$b")
    if [ -z "$xy" ]; then sin_boton=$((sin_boton+1)); sleep 1; continue; fi
    "${A[@]}" shell input tap $xy
    pulsadas=$((pulsadas+1))
    sleep 1.2
  done
  sleep 2
  LOG=$("${A[@]}" logcat -d -s CeosmosCompanion:I | grep "MEDICION $ROL" || true)
  echo "--- botón: $b"
  echo "pulsaciones: $pulsadas · botón no encontrado/deshabilitado: $sin_boton"
  echo "$LOG" | python -c '
import sys,statistics
ok=[];fallo=0
for l in sys.stdin:
    p=l.split()
    if "MEDICION" not in p: continue
    k=p.index("MEDICION")
    if p[k+3]=="ok": ok.append(int(p[k+4]))
    else: fallo+=1
print("confirmadas:",len(ok),"· fallidas:",fallo)
if ok:
    ok.sort(); p95=ok[min(len(ok)-1,int(len(ok)*0.95))]
    print("latencia ms · mediana:",statistics.median(ok),"· p95:",p95,"· máx:",ok[-1])
'
  "${A[@]}" logcat -c
done
"${A[@]}" shell rm -f /sdcard/ceosmos_ui.xml
