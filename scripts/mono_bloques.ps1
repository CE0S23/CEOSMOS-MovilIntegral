# Usuario torpe por bloques en un teléfono, siempre sobre la copia aislada
# com.ceosmos.ceosmos_movil_integral.monkey (la app real y sus datos no se tocan).
# Uso: powershell -File scripts/mono_bloques.ps1 -Serial R5CXA1DRLAF -Semillas "3101,3102,3103,3104"
param(
  [Parameter(Mandatory)] [string]$Serial,
  [string]$Semillas = '3101,3102,3103,3104',
  [int]$Acciones = 5000
)
$ErrorActionPreference = 'Continue'
$raiz = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $raiz 'evidencias\blindaje\mono'
$resumen = Join-Path $dir "bloques_$Serial.txt"
$env:ORG_GRADLE_PROJECT_ceosmosMonkey = 'true'
Set-Location $raiz
foreach ($s in ($Semillas -split ',' | ForEach-Object { [int]$_ })) {
 foreach ($intento in 1..3) {
  $log = Join-Path $dir "mono_${Serial}_semilla$s.txt"
  $inicioDisp = (adb -s $Serial shell date '+%m-%d %H:%M:%S.000').Trim()
  $t = [Diagnostics.Stopwatch]::StartNew()
  flutter test integration_test/mono_usuario_test.dart -d $Serial `
    --dart-define=MONO_ACCIONES=$Acciones --dart-define=MONO_SEMILLA=$s *> $log
  $codigo = $LASTEXITCODE
  $t.Stop()
  $linea = (Select-String -Path $log -Pattern 'MONO_RESUMEN' | Select-Object -Last 1).Line
  $crash = @(adb -s $Serial logcat -b crash -d -T "$inicioDisp" 2>$null | Select-String 'ceosmos').Count
  $anr = @(adb -s $Serial logcat -b events -d -T "$inicioDisp" 2>$null | Select-String 'am_anr.*ceosmos').Count
  $pasa = [bool](Select-String -Path $log -Pattern 'All tests passed' -Quiet)
  "$(Get-Date -Format s) serial=$Serial semilla=$s codigo=$codigo pasa=$pasa crash=$crash anr=$anr seg=$([int]$t.Elapsed.TotalSeconds) :: $linea" |
    Add-Content -Path $resumen -Encoding utf8
  $usb = [bool](Select-String -Path $log -Pattern "device '$Serial' not found|No tests were found" -Quiet)
  if ($pasa) { break }
  if (-not $usb) { break }
  # El teléfono se desconectó de adb (cable/USB), no es un fallo de la app: se espera y se repite.
  "$(Get-Date -Format s) serial=$Serial semilla=$s desconexion_usb intento=$intento -> se repite" | Add-Content -Path $resumen -Encoding utf8
  adb -s $Serial wait-for-device
  Start-Sleep -Seconds 10
 }
  if (-not $pasa) { break }
}
"FIN $Serial" | Add-Content -Path $resumen -Encoding utf8


