#!/usr/bin/env bash
# P13-14 · Demuestra que la prueba de regresión DEF-BLE-01 detecta el defecto:
#   1) con lib/core/ble/ecosistema_ble.dart ANTERIOR a la corrección (1a8f98c^) → FALLA
#   2) con el código actual (corregido) → PASA
# Restaura siempre el archivo actual, aunque se interrumpa.
set -u
cd "$(dirname "$0")/.."
ARCH=lib/core/ble/ecosistema_ble.dart
PRUEBA=test/p13_14/aut03_regresion_tv_reiniciada_test.dart
OUT=evidencias/p13_14
mkdir -p "$OUT"
cp "$ARCH" "$ARCH.p13bak"
trap 'mv -f "$ARCH.p13bak" "$ARCH"' EXIT

git show 1a8f98c^:"$ARCH" > "$ARCH"
echo "== Código VIEJO (1a8f98c^): se espera FALLO ==" | tee "$OUT/regresion_codigo_viejo.txt"
flutter test "$PRUEBA" --reporter expanded 2>&1 | tee -a "$OUT/regresion_codigo_viejo.txt"
viejo=${PIPESTATUS[0]}

mv -f "$ARCH.p13bak" "$ARCH"; trap - EXIT
echo "== Código NUEVO (corregido): se espera ÉXITO ==" | tee "$OUT/regresion_codigo_nuevo.txt"
flutter test "$PRUEBA" --reporter expanded 2>&1 | tee -a "$OUT/regresion_codigo_nuevo.txt"
nuevo=${PIPESTATUS[0]}

echo "Resultado: viejo=exit $viejo (debe ser ≠0) · nuevo=exit $nuevo (debe ser 0)"
[ "$viejo" -ne 0 ] && [ "$nuevo" -eq 0 ]
