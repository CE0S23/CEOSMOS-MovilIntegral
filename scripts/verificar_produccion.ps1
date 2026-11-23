# Verificación automática tras instalar: ¿la app instalada llega a la API de PRODUCCIÓN?
# En la pantalla de Acceso escribe un correo que NO existe y comprueba que la app
# responde «Correo o contraseña incorrectos.» (la API contestó 401 desde producción).
# No usa cuentas reales ni bloquea ninguna (el correo no existe) y no toca ajustes.
# Si la app ya tiene sesión iniciada, no hay formulario: se informa OMITIDO.
#   powershell -File scripts/verificar_produccion.ps1 -Serial R52W80BXQHP
param([Parameter(Mandatory)][string]$Serial)
$paquete = 'com.ceosmos.ceosmos_movil_integral'

function Volcar {
  adb -s $Serial shell uiautomator dump /sdcard/ceosmos_ui.xml | Out-Null
  $x = (adb -s $Serial shell cat /sdcard/ceosmos_ui.xml) -join ''
  adb -s $Serial shell rm -f /sdcard/ceosmos_ui.xml | Out-Null
  return $x
}
function Centro($nodo) {
  $m = [regex]::Match($nodo, 'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
  return @((([int]$m.Groups[1].Value + [int]$m.Groups[3].Value) / 2), (([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2))
}

adb -s $Serial shell am force-stop $paquete | Out-Null
adb -s $Serial shell am start -n "$paquete/.MainActivity" | Out-Null
# Espera activa al formulario (la Tab S9 tarda más que el S24 en arrancar en frío:
# con una espera fija de 6 s la verificación falló el 22/11 aunque la app sí llegaba).
$campos = @()
foreach ($i in 1..10) {
  Start-Sleep -Seconds 2
  $ui = Volcar
  $campos = @([regex]::Matches($ui, '<node [^>]*class="android.widget.EditText"[^>]*>') | ForEach-Object { $_.Value })
  if ($campos.Count -ge 2 -or $ui -match 'Inicio|Equipos|Perfil') { break }
}
if ($campos.Count -lt 2) { Write-Output 'VERIFICACION OMITIDA: la app tiene sesión iniciada (no hay formulario de Acceso)'; exit 0 }

$c = Centro $campos[0]; adb -s $Serial shell input tap $c[0] $c[1]; Start-Sleep -Milliseconds 1500
adb -s $Serial shell input text 'verificacion.blindaje@example.com'
# Tab mueve el foco a la contraseña: no se toca la pantalla con el teclado abierto
# (un toque ahí abrió una vez los ajustes del teclado Samsung).
adb -s $Serial shell input keyevent 61; Start-Sleep -Milliseconds 1500
adb -s $Serial shell input text 'NoExiste2026x'
adb -s $Serial shell input keyevent 66   # Enter envía el formulario (no se toca el teclado)
$ok = $false
foreach ($i in 1..10) {
  Start-Sleep -Seconds 2
  $ui = Volcar
  # Sin depender de la codificación de la consola: desde Git Bash la «ñ» llega como
  # bytes UTF-8 mal decodificados y la verificación fallaba aunque la app sí respondía.
  if ($ui -match 'Correo o contrase.{1,8}a incorrectos') { $ok = $true; break }
  if ($ui -match 'No hay conexi|demasiado|n segura') { break }
}
# Deja la app limpia en Acceso.
adb -s $Serial shell am force-stop $paquete | Out-Null
adb -s $Serial shell am start -n "$paquete/.MainActivity" | Out-Null
if ($ok) { Write-Output 'VERIFICACION OK: la app llega a la API de producción («Correo o contraseña incorrectos.»)'; exit 0 }
Write-Output 'VERIFICACION FALLÓ: la app no obtuvo respuesta de producción (¿URL de la API? ¿red?)'; exit 1
