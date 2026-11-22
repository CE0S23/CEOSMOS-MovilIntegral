# Plan de contingencia · arreglar algo en 20 minutos (Windows PowerShell 5.1).
#
#   powershell -ExecutionPolicy Bypass -File scripts\arreglo_rapido.ps1 -Area login [-LogcatSeg 20]
#
# Áreas: login | red | ble | soporte | reportes | directorio | mensajeria |
#        incidencias | seguridad | navegacion | todo
param(
    [string]$Area = 'todo',
    [int]$LogcatSeg = 20,
    [string[]]$Dispositivos = @('R5CXA1DRLAF', 'R52W80BXQHP')
)
Set-Location (Join-Path $PSScriptRoot '..')
$paquete = 'com.ceosmos.ceosmos_movil_integral'

$areas = @{
    'login'       = @('test/widget_test.dart test/whitebox/wb_validacion_test.dart test/p13_14/aut01_03_unitarias_test.dart', 'lib/ui/auth_screen.dart lib/data/auth_repository.dart')
    'red'         = @('test/whitebox/wb_comunicacion_test.dart test/p12 test/p13_14/aut04_integracion_api_test.dart test/p13_14/aut05_servidor_sin_respuesta_test.dart', 'lib/data lib/core/reintentos.dart')
    'ble'         = @('test/ble test/p13_14/aut03_regresion_tv_reiniciada_test.dart', 'lib/core/ble lib/ui/ble_section.dart')
    'soporte'     = @('test/navegacion_funciones_test.dart', 'lib/practicas/p07 lib/ui/funciones.dart')
    'reportes'    = @('test/practicas/bd_flutter', 'lib/practicas/bd_flutter')
    'directorio'  = @('test/practicas/p03_04 test/p13_14/aut06_persistencia_p04_test.dart', 'lib/practicas/p03_04')
    'mensajeria'  = @('test/practicas/p06', 'lib/practicas/p06')
    'incidencias' = @('test/practicas/examen1', 'lib/practicas/examen1')
    'seguridad'   = @('test/practica8_black_box_test.dart', 'lib/practicas/p05')
    'navegacion'  = @('test/navegacion_funciones_test.dart test/widget_test.dart', 'lib/app.dart lib/ui')
    'todo'        = @('', '')
}
if (-not $areas.ContainsKey($Area)) { Write-Host "Área desconocida: $Area"; exit 2 }
$pruebas = $areas[$Area][0] -split ' ' | Where-Object { $_ }
$codigo = $areas[$Area][1] -split ' ' | Where-Object { $_ }

$resumen = New-Object System.Collections.Generic.List[string]
$fallo = $false
function Paso([string]$nombre, [scriptblock]$accion) {
    Write-Host "`n== $nombre"
    $reloj = [Diagnostics.Stopwatch]::StartNew()
    & $accion
    $ok = ($LASTEXITCODE -eq 0)
    $reloj.Stop()
    if (-not $ok) { $script:fallo = $true }
    $estado = if ($ok) { 'OK' } else { 'FALLÓ' }
    $script:resumen.Add(('{0,-22} {1,4}s  {2}' -f $nombre, [int]$reloj.Elapsed.TotalSeconds, $estado))
}

Paso '1 análisis' { flutter analyze @codigo }
Paso '2 pruebas del área' { flutter test @pruebas }
if (-not $fallo) {
    Paso '3 build debug' { flutter build apk --debug --dart-define=CEOSMOS_API_URL=https://ceosmos-api.vercel.app/api }
    foreach ($d in $Dispositivos) {
        adb -s $d get-state 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            # -r conserva los datos de la app (misma llave que el release instalado).
            Paso "4 instalar $d" { adb -s $d install -r build/app/outputs/flutter-apk/app-debug.apk }
            adb -s $d shell am force-stop $paquete | Out-Null
            adb -s $d shell am start -n "$paquete/.MainActivity" | Out-Null   # nunca adb monkey
        } else {
            $resumen.Add(('{0,-22} {1,4}s  {2}' -f "4 instalar $d", 0, 'SIN CONEXIÓN'))
        }
    }
    foreach ($d in $Dispositivos) {
        adb -s $d get-state 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { continue }
        Write-Host "`n== 5 logcat $d ($LogcatSeg s, solo errores de la app)"
        adb -s $d logcat -c
        $reloj = [Diagnostics.Stopwatch]::StartNew()
        $p = Start-Process adb -ArgumentList "-s $d logcat -v time flutter:E AndroidRuntime:E CEOSMOS:* *:S" -NoNewWindow -PassThru
        Start-Sleep -Seconds $LogcatSeg
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
        $resumen.Add(('{0,-22} {1,4}s  {2}' -f "5 logcat $d", [int]$reloj.Elapsed.TotalSeconds, 'revisado'))
        # 6: ¿llega a producción? Correo inexistente → «Correo o contraseña incorrectos».
        Paso "6 API producción $d" { powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verificar_produccion.ps1') -Serial $d }
    }
} else {
    Write-Host "`nLas pruebas fallaron: corrige antes de instalar."
}

Write-Host "`n== Resumen ($Area)"
$resumen | ForEach-Object { Write-Host $_ }
Write-Host "`nPara subir: git add -A; git commit -m 'Arreglo: ...'; git push origin main; gh run watch"
if ($fallo) { exit 1 } else { exit 0 }
