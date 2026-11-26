<#
  Levanta el entorno de desarrollo de CEOSMOS para probar en el emulador:
    1. PostgreSQL local de desarrollo (puerto 5433, datos en .devdb\data).
    2. API NestJS de CEOSMOS en su puerto propio (8081; -ApiPort para otro) con esa base.
    3. Backend de MediConnect (HTTPS 3443, su puerto de siempre) y adb reverse.

  Uso:  powershell -ExecutionPolicy Bypass -File scripts\dev_backend.ps1 [-Neon] [-ApiPort 8081]

  -Neon     usa la base de producción (Neon) definida en el .env del API en lugar
            de la base local. Antes aplica la migración 20261111170000_movil_integral
            (node prisma\migrate-ws.js --apply) — ver REPORTE_FINAL.md.
  -ApiPort  puerto de la API de CEOSMOS (por omisión 8081).

  1.4.0: antes se fijaba PORT=8080 en el entorno y MediConnect lo heredaba (escuchaba en
  8080 y la API no levantaba). Ahora PORT solo se fija para la API y se restaura antes de
  arrancar MediConnect, y el script se detiene con un aviso si el puerto está ocupado.
#>
param(
  [switch]$Neon,
  [ValidateRange(1024, 65535)][int]$ApiPort = 8081,
  [string]$Api = "C:\Users\cesar\OneDrive\Escritorio\8°\DesarrolloWEB\WEBANGULAR\ceosmos-api",
  [string]$Pg = "C:\Program Files\PostgreSQL\16\bin"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$data = Join-Path $root '.devdb\data'
$url = 'postgresql://ceosmos@127.0.0.1:5433/ceosmos_dev'

function Test-PuertoOcupado([int]$Puerto) {
  # true si algo ya escucha en ese puerto TCP.
  $l = $null
  try {
    $l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Puerto)
    $l.Start()
    return $false
  } catch {
    return $true
  } finally {
    if ($l) { $l.Stop() }
  }
}

if (Test-PuertoOcupado $ApiPort) {
  $quien = Get-NetTCPConnection -State Listen -LocalPort $ApiPort -ErrorAction SilentlyContinue |
    Select-Object -First 1 |
    ForEach-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName }
  $por = if ($quien) { " por '$quien'" } else { '' }
  Write-Warning "El puerto $ApiPort ya está ocupado$por. La API de CEOSMOS no se arrancó: libéralo o usa -ApiPort <otro>."
  exit 2
}

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

# PORT solo para el proceso de la API; MediConnect conserva su puerto (3443).
$portPrevio = $env:PORT
$env:PORT = "$ApiPort"
Start-Process -WorkingDirectory $Api -NoNewWindow node -ArgumentList 'dist/main.js'
if ($null -eq $portPrevio) { Remove-Item Env:PORT -ErrorAction SilentlyContinue } else { $env:PORT = $portPrevio }

$medi = Join-Path $root 'Practica para implementar en la app\Evaluacion2\mediconnect\backend'
if (Test-Path $medi) { Start-Process -WorkingDirectory $medi -NoNewWindow node -ArgumentList 'server.js' }

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (Test-Path $adb) {
  & $adb reverse tcp:3443 tcp:3443
  & $adb reverse tcp:$ApiPort tcp:$ApiPort
}
Write-Host "API CEOSMOS: http://10.0.2.2:$ApiPort/api (emulador) o http://127.0.0.1:$ApiPort/api · MediConnect: https://localhost:3443 (adb reverse)"
