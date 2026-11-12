#!/usr/bin/env bash
# Práctica 11 · Fase 5: ejecuta integration_test/p11_red_test.dart en el teléfono y
# corta / restablece el enlace app ↔ API (adb reverse) cuando la prueba lo indica.
#   bash fase5_orquestar.sh <id_dispositivo> <correo> <contraseña> <log>
set -u
DEV="$1"; EMAIL="$2"; PASS="$3"; LOG="$4"
cd "$(dirname "$0")/../../.."   # raíz del proyecto
adb -s "$DEV" reverse tcp:8080 tcp:8080 >/dev/null
: > "$LOG"; : > "$LOG.host"
flutter test integration_test/p11_red_test.dart -d "$DEV" --no-pub \
  --dart-define=CEOSMOS_API_URL=http://localhost:8080/api \
  --dart-define=E2E_EMAIL="$EMAIL" --dart-define=E2E_PASSWORD="$PASS" >> "$LOG" 2>&1 &
PID=$!
cortado=0; reconectado=0
while kill -0 $PID 2>/dev/null; do
  if [ $cortado -eq 0 ] && grep -q "P11_MARK CORTAR" "$LOG"; then
    adb -s "$DEV" reverse --remove tcp:8080
    echo "HOST $(date +%H:%M:%S.%N | cut -c1-12) adb reverse --remove tcp:8080 (enlace cortado)" >> "$LOG.host"
    cortado=1
  fi
  if [ $reconectado -eq 0 ] && grep -q "P11_MARK RECONECTAR" "$LOG"; then
    sleep 5   # el enlace permanece caído 5 s más
    adb -s "$DEV" reverse tcp:8080 tcp:8080 >/dev/null
    echo "HOST $(date +%H:%M:%S.%N | cut -c1-12) adb reverse tcp:8080 tcp:8080 (enlace restablecido)" >> "$LOG.host"
    reconectado=1
  fi
  sleep 0.3
done
wait $PID; echo "HOST flutter test terminó con código $?" >> "$LOG.host"
adb -s "$DEV" reverse tcp:8080 tcp:8080 >/dev/null
