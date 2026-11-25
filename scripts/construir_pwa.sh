#!/usr/bin/env bash
# Compila CEOSMOS como PWA (Flutter web). Ver scripts/construir_pwa.ps1.
# Uso: scripts/construir_pwa.sh [--local] [--servir]
set -euo pipefail
cd "$(dirname "$0")/.."
api=https://ceosmos-api.vercel.app/api
servir=0
for a in "$@"; do
  case "$a" in
    --local) api=http://localhost:8080/api ;;
    --servir) servir=1 ;;
  esac
done
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run "--dart-define=CEOSMOS_API_URL=$api"
python3 scripts/pwa_precache.py build/web || python scripts/pwa_precache.py build/web
echo "PWA lista en build/web (API: $api)"
if [ "$servir" = 1 ]; then
  python3 -m http.server 4200 --bind 127.0.0.1 --directory build/web
fi
