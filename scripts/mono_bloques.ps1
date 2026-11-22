# Usuario torpe por bloques en un teléfono, siempre sobre la copia aislada
# com.ceosmos.ceosmos_movil_integral.monkey (la app real y sus datos no se tocan).
# Uso: powershell -File scripts/mono_bloques.ps1 -Serial R5CXA1DRLAF -Semillas "3101,3102"
#
# INCIDENTE 22/11: la variable ORG_GRADLE_PROJECT_ceosmosMonkey NO llega a la build
# (reproducido: el APK sale con el paquete real). `flutter test` instaló la app REAL y
# al terminar la desinstaló: se perdieron los datos locales del teléfono. Por eso ahora:
#   1. el aislamiento se activa con el archivo marcador android/app/.ceosmos_monkey;
#   2. antes de correr se compila y se COMPRUEBA con aapt2 que el paquete es el .monkey;
#   3. tras cada bloque se verifica que la app real no se reinstaló (firstInstallTime).
param(
  [Parameter(Mandatory)] [string]$Serial,
  [string]$Semillas = '3101,3102,3103,3104',
  [int]$Acciones = 5000
)
$ErrorActionPreference = 'Continue'
$raiz = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $raiz 'evidencias\blindaje\mono'
$resumen = Join-Path $dir "bloques_$Serial.txt"
$marcador = Join-Path $raiz 'android\app\.ceosmos_monkey'
$real = 'com.ceosmos.ceosmos_movil_integral'
Set-Location $raiz

function InstalacionReal { (adb -s $Serial shell dumpsys package $real | Select-String 'firstInstallTime' | Select-Object -First 1).Line }

New-Item -ItemType File -Force $marcador | Out-Null
try {
  # Comprobación previa: el APK que instalará `flutter test` debe ser el aislado.
  flutter build apk --debug *> $null
  $sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk\build-tools'
  $aapt = Get-ChildItem $sdk -Recurse -Filter aapt2.exe | Sort-Object FullName -Descending | Select-Object -First 1
  $paquete = (& $aapt.FullName dump packagename build\app\outputs\flutter-apk\app-debug.apk).Trim()
  if ($paquete -ne "$real.monkey") {
    "$(Get-Date -Format s) ABORTADO: el APK de prueba es '$paquete', no '$real.monkey'. No se corre nada." |
      Add-Content $resumen -Encoding utf8
    Write-Output "ABORTADO: paquete $paquete"
    exit 2
  }
  $antes = InstalacionReal
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
      if ((InstalacionReal) -ne $antes) {
        "$(Get-Date -Format s) ALERTA: la app real cambió de instalación ($antes -> $(InstalacionReal)). Se detiene." |
          Add-Content $resumen -Encoding utf8
        exit 3
      }
      $usb = [bool](Select-String -Path $log -Pattern "device '$Serial' not found|No tests were found" -Quiet)
      if ($pasa -or -not $usb) { break }
      # El teléfono se desconectó de adb (cable/USB), no es un fallo de la app: se espera y se repite.
      "$(Get-Date -Format s) serial=$Serial semilla=$s desconexion_usb intento=$intento -> se repite" |
        Add-Content -Path $resumen -Encoding utf8
      adb -s $Serial wait-for-device
      Start-Sleep -Seconds 10
    }
    if (-not $pasa) { break }
  }
  "FIN $Serial" | Add-Content -Path $resumen -Encoding utf8
} finally {
  Remove-Item $marcador -ErrorAction SilentlyContinue
}
