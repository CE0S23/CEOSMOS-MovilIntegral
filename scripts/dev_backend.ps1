<#
  Levanta el entorno de desarrollo de CEOSMOS para probar en el emulador:
    1. PostgreSQL local de desarrollo (puerto 5433, datos en .devdb\data).
    2. API NestJS de CEOSMOS (puerto 8080) apuntando a esa base.
    3. Backend de la práctica MediConnect (HTTPS 3443) y adb reverse.

  Uso:  powershell -ExecutionPolicy Bypass -File scripts\dev_backend.ps1 [-Neon]

  -Neon  usa la base de producción (Neon) definida en el .env del API en lugar
         de la base local. Antes aplica la migración 20261111170000_movil_integral
         (node prisma\migrate-ws.js --apply) — ver REPORTE_FINAL.md.
#>
param(
  [switch]$Neon,
  [string]$Api = "C:\Users\cesar\OneDrive\Escritorio\8°\DesarrolloWEB\WEBANGULAR\ceosmos-api",
  [string]$Pg = "C:\Program Files\PostgreSQL\16\bin"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$data = Join-Path $root '.devdb\data'
$url = 'postgresql://ceosmos@127.0.0.1:5433/ceosmos_dev'

if (-not $Neon) {
  if (-not (Test-Path $data)) {
    Write-Host 'Creando la base PostgreSQL de desarrollo...'
    & "$Pg\initdb.exe" -D $data -U ceosmos -A trust -E UTF8 --locale=C | Out-Null
    $nueva = $true
  }
  & "$Pg\pg_ctl.exe" -D $data status | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Start-Process -WindowStyle Hidden "$Pg\pg_ctl.exe" -ArgumentList @('-D', $data, '-o', '"-p 5433 -h 127.0.0.1"', '-l', (Join-Path $root '.devdb\postgres.log'), 'start')
    Start-Sleep -Seconds 4
  }
  if ($nueva) {
    & "$Pg\createdb.exe" -h 127.0.0.1 -p 5433 -U ceosmos ceosmos_dev
    Push-Location $Api
    $env:DATABASE_URL = $url; $env:DIRECT_URL = $url
    npx prisma db push --skip-generate
    Pop-Location
    Write-Host 'Base creada. Crea una cuenta con: SEED_EMAIL=... SEED_PASSWORD=... SEED_USERNAME=... node prisma\seed-movil.js'
  }
  $env:DATABASE_URL = $url; $env:DIRECT_URL = $url
}

$env:PORT = '8080'
Start-Process -WorkingDirectory $Api -NoNewWindow node -ArgumentList 'dist/main.js'

$medi = Join-Path $root 'Practica para implementar en la app\Evaluacion2\mediconnect\backend'
if (Test-Path $medi) { Start-Process -WorkingDirectory $medi -NoNewWindow node -ArgumentList 'server.js' }

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (Test-Path $adb) { & $adb reverse tcp:3443 tcp:3443 }
Write-Host 'API CEOSMOS: http://10.0.2.2:8080/api (emulador) · MediConnect: https://localhost:3443 (adb reverse)'
