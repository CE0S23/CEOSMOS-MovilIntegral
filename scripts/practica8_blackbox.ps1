param(
    [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\evidencias\practica8')
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$testFile = 'test/practica8_black_box_test.dart'
$flutter = (Get-Command flutter -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$log = Join-Path $OutputDir 'flutter-test.jsonl'
$report = Join-Path $OutputDir 'reporte.md'
$csv = Join-Path $OutputDir 'casos.csv'

Push-Location $projectRoot
try {
    & $flutter test $testFile --no-pub --reporter json 2>&1 |
        Out-File -LiteralPath $log -Encoding utf8
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

$events = foreach ($line in Get-Content -LiteralPath $log -Encoding utf8) {
    try { $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
}
$starts = @{}
$errors = @{}
$cases = [System.Collections.Generic.List[object]]::new()
foreach ($event in $events) {
    switch ($event.type) {
        'testStart' { $starts[[string]$event.test.id] = [string]$event.test.name }
        'error' {
            $id = [string]$event.testID
            if (-not $errors.ContainsKey($id)) { $errors[$id] = [string]$event.error }
        }
        'testDone' {
            $id = [string]$event.testID
            if (-not $starts.ContainsKey($id) -or $starts[$id] -notmatch 'CP-\d+') { break }
            $name = $starts[$id]
            $caseId = [regex]::Match($name, 'CP-\d+(?:-\d+)?').Value
            $requirement = [regex]::Match($name, 'REQ-[A-Z]+-\d+').Value
            $status = if ($event.skipped) { 'OMITIDO' } elseif ($event.result -eq 'success') { 'PASS' } else { 'FAIL' }
            $detail = if ($errors.ContainsKey($id)) { ($errors[$id] -split "`n")[0] } else { '' }
            $cases.Add([pscustomobject]@{
                Caso = $caseId
                Requisito = $requirement
                Descripcion = ($name -replace '^.*?CP-\d+(?:-\d+)?\s+REQ-[A-Z]+-\d+\s+', '')
                Estado = $status
                Detalle = $detail
            })
        }
    }
}
$cases | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
$passed = @($cases | Where-Object Estado -eq 'PASS').Count
$failed = @($cases | Where-Object Estado -eq 'FAIL').Count
$skipped = @($cases | Where-Object Estado -eq 'OMITIDO').Count
$total = $cases.Count
$covered = @($cases | Where-Object Estado -eq 'PASS' | Select-Object -ExpandProperty Requisito -Unique).Count
$decision = if ($exitCode -eq 0 -and $failed -eq 0 -and $skipped -eq 0 -and $covered -eq 12) {
    'ACEPTACIÓN del alcance local evaluado'
} else {
    'NO ACEPTAR hasta revisar los casos fallidos, omitidos o sin cobertura'
}
$date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Práctica 8 · Reporte de ejecución de caja negra')
$lines.Add('')
$lines.Add("**Proyecto:** CEOSMOS Móvil Integral  ")
$lines.Add("**Fecha local:** $date  ")
$lines.Add("**Comando:** ``flutter test $testFile --no-pub --reporter json``  ")
$lines.Add("**Salida:** $exitCode  ")
$lines.Add("**Resultado:** $decision")
$lines.Add('')
$lines.Add("**Ejecuciones:** $total; PASS: $passed; FAIL: $failed; omitidas: $skipped. **Requisitos cubiertos:** $covered/12.")
$lines.Add('')
$lines.Add('| Caso | Requisito | Comportamiento observable | Estado |')
$lines.Add('|---|---|---|---|')
foreach ($case in $cases) {
    $description = $case.Descripcion.Replace('|', '\|')
    $lines.Add("| $($case.Caso) | $($case.Requisito) | $description | $($case.Estado) |")
}
if ($failed -gt 0) {
    $lines.Add('')
    $lines.Add('## Fallos')
    $lines.Add('')
    foreach ($case in $cases | Where-Object Estado -eq 'FAIL') {
        $lines.Add("- **$($case.Caso):** $($case.Detalle)")
    }
}
$lines.Add('')
$lines.Add('## Alcance y límites de la evidencia')
$lines.Add('')
$lines.Add('- La suite envía acciones a formularios, botones, filtros y navegación Flutter; observa textos, controles y errores visibles. El reloj y un fallo del canal de audio se inyectan como condiciones externas controladas.')
$lines.Add('- CP-17 prueba valores de duración inválidos en la interfaz pública de estado, pues la UI solo ofrece 5, 15, 25 y 45 minutos.')
$lines.Add('- Los datos se conservan solo mientras vive la instancia de la app. No se acredita persistencia tras reinicio, API, JWT, WebAuthn, BLE, TCP/IP ni sensores físicos.')
$lines.Add('- La prueba de widgets no demuestra comportamiento en un dispositivo Android real, rendimiento, audio audible ni ausencia de fugas de memoria.')
$lines.Add('- Los eventos JSONL y el CSV de casos en esta carpeta permiten auditar el dictamen. Si Flutter no emitió resultados, el dictamen es rechazo por falta de evidencia.')
$lines | Set-Content -LiteralPath $report -Encoding utf8

Write-Output "Casos: $total; PASS: $passed; FAIL: $failed; omitidos: $skipped; requisitos: $covered/12"
Write-Output "Reporte: $report"
Write-Output "Evidencia: $log"
if ($exitCode -ne 0 -or $failed -gt 0 -or $skipped -gt 0 -or $covered -ne 12) { exit 1 }
