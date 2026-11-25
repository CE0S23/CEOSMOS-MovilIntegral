# Actualiza índice, listas de figuras/tablas y campos de cada .docx y lo exporta a PDF con Word.
# Uso: powershell -File tool/documentacion/actualizar_y_exportar.ps1 "ruta1.docx" "ruta2.docx" ...
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Rutas)
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  foreach ($r in $Rutas) {
    $ruta = (Resolve-Path $r).Path
    $doc = $word.Documents.Open($ruta, $false, $false)
    for ($i = 0; $i -lt 2; $i++) {
      foreach ($story in $doc.StoryRanges) { [void]$story.Fields.Update() }
      foreach ($t in $doc.TablesOfContents) { [void]$t.Update() }
      foreach ($t in $doc.TablesOfFigures) { [void]$t.Update() }
    }
    $doc.Save()
    $pdf = [System.IO.Path]::ChangeExtension($ruta, '.pdf')
    # 17 = wdExportFormatPDF; CreateBookmarks 1 = encabezados
    $doc.ExportAsFixedFormat($pdf, 17, $false, 0, 0, 1, 1, 0, $true, $true, 1, $true, $true, $false)
    $paginas = $doc.ComputeStatistics(2)
    Write-Output "$paginas`t$ruta"
    $doc.Close(0)
  }
} finally {
  $word.Quit()
  [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
}
