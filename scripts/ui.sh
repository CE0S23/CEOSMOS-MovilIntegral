#!/usr/bin/env bash
# Utilidad de pruebas en dispositivo (Black Box por adb): toca elementos por su texto
# usando `uiautomator dump`. Flutter expone la semántica de sus widgets a accesibilidad.
#   source scripts/ui.sh <serial>
#   ui_tap "Iniciar sesión"      # toca el primer nodo cuyo text/content-desc contiene el texto
#   ui_has "Conectado"           # 0 si aparece en pantalla
#   ui_shot evidencias/x.png     # captura
SERIAL="${1:?serial}"
export MSYS_NO_PATHCONV=1  # Git Bash: no convertir /sdcard en una ruta de Windows
ui_dump() {
  adb -s "$SERIAL" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb -s "$SERIAL" exec-out cat /sdcard/ui.xml
}
# Imprime "x y" del centro del primer nodo que contenga el texto (en text, content-desc o hint).
ui_find() {
  ui_dump | python -c '
import sys,re,html
t=sys.argv[1]; x=sys.stdin.buffer.read().decode("utf-8","replace")
for m in re.finditer(r"<node [^>]*>", x):
    n=m.group(0)
    campos=" ".join(html.unescape(v) for v in re.findall(r"(?:text|content-desc|hint)=\"([^\"]*)\"", n))
    if t in campos:
        b=re.search(r"bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"", n)
        if b:
            x1,y1,x2,y2=map(int,b.groups()); print((x1+x2)//2,(y1+y2)//2); break
' "$1"
}
ui_tap() {
  local p; p=$(ui_find "$1")
  if [ -z "$p" ]; then echo "NO ENCONTRADO: $1" >&2; return 1; fi
  adb -s "$SERIAL" shell input tap $p; sleep "${2:-1}"
}
ui_type() { adb -s "$SERIAL" shell "input text '$1'"; }
ui_has() { [ -n "$(ui_find "$1")" ]; }
ui_shot() { adb -s "$SERIAL" exec-out screencap -p > "$1"; }
ui_back() { adb -s "$SERIAL" shell input keyevent 4; sleep 1; }
# Oculta el teclado solo si está visible (BACK con el teclado cerrado navegaría hacia atrás).
ui_hidekb() {
  if adb -s "$SERIAL" shell dumpsys input_method | grep -q "mInputShown=true"; then
    adb -s "$SERIAL" shell input keyevent 4; sleep 1
  fi
}
# Escribe en el campo que contiene el texto, borrando lo que tenga (Ctrl+A, Supr).
ui_fill() {
  ui_tap "$1" || return 1
  adb -s "$SERIAL" shell input keycombination 113 29; adb -s "$SERIAL" shell input keyevent 67
  ui_type "$2"; ui_hidekb
}
ui_list() {
  ui_dump > .ui_tmp.xml; python -c '
import re,html,sys
x=open(".ui_tmp.xml","rb").read().decode("utf-8","replace")
for n in re.findall(r"<node [^>]*>", x):
    c=" ".join(re.findall(r"(?:text|content-desc|hint)=\"([^\"]+)\"", n))
    if c.strip(): sys.stdout.buffer.write((html.unescape(c)[:70]+" "+re.search(r"bounds=\"([^\"]*)\"",n).group(1)+"\n").encode("utf-8"))
'; rm -f .ui_tmp.xml
}
