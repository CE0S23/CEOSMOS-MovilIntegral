#!/usr/bin/env bash
# Verificación automática tras instalar: ¿la app instalada llega a la API de PRODUCCIÓN?
# Igual que verificar_produccion.ps1: correo inexistente → «Correo o contraseña incorrectos.»
#   bash scripts/verificar_produccion.sh R52W80BXQHP
S="$1"; PAQ=com.ceosmos.ceosmos_movil_integral
volcar() { adb -s "$S" shell uiautomator dump /sdcard/ceosmos_ui.xml >/dev/null; adb -s "$S" shell cat /sdcard/ceosmos_ui.xml; adb -s "$S" shell rm -f /sdcard/ceosmos_ui.xml >/dev/null; }
adb -s "$S" shell am force-stop $PAQ; adb -s "$S" shell am start -n "$PAQ/.MainActivity" >/dev/null; sleep 6
B=$(volcar | grep -o '<node [^>]*class="android.widget.EditText"[^>]*>' | head -1 | grep -o 'bounds="[^"]*"' | grep -oE '[0-9]+')
if [ -z "$B" ]; then echo "VERIFICACION OMITIDA: la app tiene sesión iniciada"; exit 0; fi
set -- $B; adb -s "$S" shell input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); sleep 1
adb -s "$S" shell input text 'verificacion.blindaje@example.com'
adb -s "$S" shell input keyevent 61; sleep 1   # Tab: sin tocar la pantalla con el teclado abierto
adb -s "$S" shell input text 'NoExiste2026x'
adb -s "$S" shell input keyevent 66            # Enter envía el formulario
OK=1
for _ in 1 2 3 4 5 6 7 8 9 10; do
  sleep 2; UI=$(volcar)
  if echo "$UI" | grep -qE 'Correo o contrase(ñ|&#241;)a incorrectos'; then OK=0; break; fi
  if echo "$UI" | grep -qE 'No hay conexi|demasiado|conexi(ó|&#243;)n segura'; then break; fi
done
adb -s "$S" shell am force-stop $PAQ; adb -s "$S" shell am start -n "$PAQ/.MainActivity" >/dev/null
[ $OK = 0 ] && echo "VERIFICACION OK: la app llega a la API de producción" || echo "VERIFICACION FALLÓ: sin respuesta de producción"
exit $OK
