<#
  Compila CEOSMOS como PWA (Flutter web) lista para instalar y usar sin conexión.

  Uso:
    powershell -ExecutionPolicy Bypass -File scripts\construir_pwa.ps1            # API de producción
    powershell -ExecutionPolicy Bypass -File scripts\construir_pwa.ps1 -Local     # API local (localhost:8080)
    powershell -ExecutionPolicy Bypass -File scripts\construir_pwa.ps1 -Servir    # y la sirve en http://localhost:4200

  - --no-web-resources-cdn: CanvasKit se sirve desde la propia PWA (no desde gstatic),
    para que el service worker lo precargue y la app abra sin red.
  - Puerto 4200: es un origen que la API de CEOSMOS ya admite por CORS, y «localhost»
    cuenta como contexto seguro (service worker, instalación y Web Bluetooth). En el
    teléfono: adb reverse tcp:4200 tcp:4200 y abrir http://localhost:4200 en Chrome.
#>
param([switch]$Local, [switch]$Servir, [int]$Puerto = 4200)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Push-Location $raiz
try {
  $api = if ($Local) { 'http://localhost:8080/api' } else { 'https://ceosmos-api.vercel.app/api' }
  flutter build web --release --no-web-resources-cdn --no-wasm-dry-run "--dart-define=CEOSMOS_API_URL=$api"
  if ($LASTEXITCODE -ne 0) { throw 'Falló flutter build web' }
  python scripts\pwa_precache.py build\web
  if ($LASTEXITCODE -ne 0) { throw 'Falló la lista de precarga' }
  Write-Host "PWA lista en build\web (API: $api)"
  if ($Servir) {
    Write-Host "Sirviendo en http://localhost:$Puerto (Ctrl+C para detener)"
    python -m http.server $Puerto --bind 127.0.0.1 --directory build\web
  }
} finally { Pop-Location }
