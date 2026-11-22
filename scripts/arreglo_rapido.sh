#!/usr/bin/env bash
# Plan de contingencia · arreglar algo en 20 minutos.
#
#   bash scripts/arreglo_rapido.sh <area> [segundos_logcat]
#
# Áreas: login | red | ble | soporte | reportes | directorio | mensajeria |
#        incidencias | seguridad | navegacion | todo
#
# Pasos (cada uno cronometrado): análisis del área → pruebas del área →
# build debug → instalación en el S24 y la Tab S9 (sin borrar datos) →
# logcat filtrado de la app. Termina con el resumen de tiempos.
set -u
cd "$(dirname "$0")/.."

AREA="${1:-todo}"
LOGCAT_SEG="${2:-20}"
DISPOSITIVOS="${CEOSMOS_DISPOSITIVOS:-R5CXA1DRLAF R52W80BXQHP}"
PAQUETE="com.ceosmos.ceosmos_movil_integral"

case "$AREA" in
  login)       PRUEBAS="test/widget_test.dart test/whitebox/wb_validacion_test.dart test/p13_14/aut01_03_unitarias_test.dart"; CODIGO="lib/ui/auth_screen.dart lib/data/auth_repository.dart" ;;
  red)         PRUEBAS="test/whitebox/wb_comunicacion_test.dart test/p12 test/p13_14/aut04_integracion_api_test.dart test/p13_14/aut05_servidor_sin_respuesta_test.dart"; CODIGO="lib/data lib/core/reintentos.dart" ;;
  ble)         PRUEBAS="test/ble test/p13_14/aut03_regresion_tv_reiniciada_test.dart"; CODIGO="lib/core/ble lib/ui/ble_section.dart" ;;
  soporte)     PRUEBAS="test/navegacion_funciones_test.dart"; CODIGO="lib/practicas/p07 lib/ui/funciones.dart" ;;
  reportes)    PRUEBAS="test/practicas/bd_flutter"; CODIGO="lib/practicas/bd_flutter" ;;
  directorio)  PRUEBAS="test/practicas/p03_04 test/p13_14/aut06_persistencia_p04_test.dart"; CODIGO="lib/practicas/p03_04" ;;
  mensajeria)  PRUEBAS="test/practicas/p06"; CODIGO="lib/practicas/p06" ;;
  incidencias) PRUEBAS="test/practicas/examen1"; CODIGO="lib/practicas/examen1" ;;
  seguridad)   PRUEBAS="test/practica8_black_box_test.dart"; CODIGO="lib/practicas/p05" ;;
  navegacion)  PRUEBAS="test/navegacion_funciones_test.dart test/widget_test.dart"; CODIGO="lib/app.dart lib/ui" ;;
  todo)        PRUEBAS=""; CODIGO="" ;;
  *) echo "Área desconocida: $AREA"; exit 2 ;;
esac

RESUMEN=()
FALLO=0
paso() { # paso <nombre> <comando...>
  local nombre="$1"; shift
  local t0=$(date +%s)
  echo; echo "== $nombre"
  if "$@"; then estado="OK"; else estado="FALLÓ"; FALLO=1; fi
  local dt=$(( $(date +%s) - t0 ))
  RESUMEN+=("$(printf '%-22s %4ss  %s' "$nombre" "$dt" "$estado")")
}

paso "1 análisis" flutter analyze $CODIGO
paso "2 pruebas del área" flutter test $PRUEBAS
if [ "$FALLO" = 0 ]; then
  paso "3 build debug" flutter build apk --debug --dart-define=CEOSMOS_API_URL=https://ceosmos-api.vercel.app/api
  for d in $DISPOSITIVOS; do
    if adb -s "$d" get-state >/dev/null 2>&1; then
      # -r conserva los datos de la app (misma llave que el release instalado).
      paso "4 instalar $d" adb -s "$d" install -r build/app/outputs/flutter-apk/app-debug.apk
      adb -s "$d" shell am force-stop "$PAQUETE"
      adb -s "$d" shell am start -n "$PAQUETE/.MainActivity" >/dev/null   # nunca adb monkey
    else
      RESUMEN+=("$(printf '%-22s %4ss  %s' "4 instalar $d" 0 "SIN CONEXIÓN")")
    fi
  done
  for d in $DISPOSITIVOS; do
    if adb -s "$d" get-state >/dev/null 2>&1; then
      echo; echo "== 5 logcat $d (${LOGCAT_SEG}s, solo errores de la app)"
      adb -s "$d" logcat -c
      t0=$(date +%s)
      timeout "$LOGCAT_SEG" adb -s "$d" logcat -v time 'flutter:E' 'AndroidRuntime:E' 'CEOSMOS:*' '*:S' || true
      RESUMEN+=("$(printf '%-22s %4ss  %s' "5 logcat $d" "$(( $(date +%s) - t0 ))" "revisado")")
      # 6: ¿llega a producción? Correo inexistente → «Correo o contraseña incorrectos».
      paso "6 API producción $d" bash "$(dirname "$0")/verificar_produccion.sh" "$d"
    fi
  done
else
  echo; echo "Las pruebas fallaron: corrige antes de instalar."
fi

echo; echo "== Resumen ($AREA)"
printf '%s\n' "${RESUMEN[@]}"
echo
echo "Para subir: git add -A && git commit -m \"Arreglo: ...\" && git push origin main && gh run watch"
exit $FALLO
