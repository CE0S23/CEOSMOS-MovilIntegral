"""Ensayo del plan de contingencia: 3 fallos simulados, detectados y corregidos con
scripts/arreglo_rapido.sh, cronometrando cada fase.

    python scripts/ensayo_contingencia.py            (dispositivos: CEOSMOS_DISPOSITIVOS)

Escribe los registros en evidencias/blindaje/ensayo/ y el resumen en resumen.md.
El código queda exactamente como estaba (se verifica con git diff al final).
"""
import os
import subprocess
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / 'evidencias' / 'blindaje' / 'ensayo'
SALIDA.mkdir(parents=True, exist_ok=True)

FALLOS = [
    ('F1 · campo sin validar (correo)', 'login', 'lib/data/auth_repository.dart',
     "return _email.hasMatch(value) ? null : 'Escribe un correo válido.';",
     'return null; // FALLO SIMULADO: acepta cualquier correo'),
    ('F2 · timeout mal puesto (cliente de la API)', 'red', 'lib/data/api_client.dart',
     'this.timeout = const Duration(seconds: 15),',
     'this.timeout = const Duration(milliseconds: 1), // FALLO SIMULADO'),
    ('F3 · permiso de Bluetooth mal manejado', 'ble', 'lib/core/ble/ecosistema_ble.dart',
     """      e.error = 'Permiso de Bluetooth denegado. Actívalo en Ajustes › Apps › CEOSMOS › Permisos.';
      if (enlace != null) await _soltar(enlace, rol);
      return ResultadoConexion.sinPermiso;""",
     """      e.error = 'Error'; // FALLO SIMULADO: no explica el permiso
      if (enlace != null) await _soltar(enlace, rol);
      return ResultadoConexion.fallo;"""),
]


def correr(area, registro):
    t0 = time.time()
    with open(registro, 'w', encoding='utf-8') as f:
        r = subprocess.run(['bash', 'scripts/arreglo_rapido.sh', area, '10'], cwd=RAIZ,
                           stdout=f, stderr=subprocess.STDOUT, env=os.environ.copy())
    return r.returncode, time.time() - t0


filas = []
for nombre, area, archivo, bueno, malo in FALLOS:
    ruta = RAIZ / archivo
    original = ruta.read_bytes()
    texto = original.decode('utf-8')
    assert bueno in texto, f'No se encontró el fragmento en {archivo}'
    ruta.write_bytes(texto.replace(bueno, malo, 1).encode('utf-8'))
    inicio = time.time()
    slug = area
    try:
        cod1, t_det = correr(area, SALIDA / f'{slug}_1_deteccion.txt')
        t_fix0 = time.time()
        ruta.write_bytes(original)  # corrección (vuelve al código correcto)
        t_fix = time.time() - t_fix0
        cod2, t_ver = correr(area, SALIDA / f'{slug}_2_verificacion.txt')
    finally:
        ruta.write_bytes(original)
    total = time.time() - inicio
    filas.append((nombre, area, cod1 != 0, t_det, t_fix, cod2 == 0, t_ver, total))
    print(f'{nombre}: detectado={cod1 != 0} ({t_det:.0f}s) corregido_ok={cod2 == 0} ({t_ver:.0f}s) total={total:.0f}s', flush=True)

diff = subprocess.run(['git', 'diff', '--stat', '--', *[f[2] for f in FALLOS]], cwd=RAIZ,
                      capture_output=True, text=True).stdout.strip()
with open(SALIDA / 'resumen.md', 'w', encoding='utf-8') as f:
    f.write('# Ensayo del plan de contingencia (20 minutos)\n\n')
    f.write(f'Fecha: {time.strftime("%Y-%m-%d %H:%M")} · dispositivos: {os.environ.get("CEOSMOS_DISPOSITIVOS", "R5CXA1DRLAF R52W80BXQHP")}\n\n')
    f.write('| Fallo | Área | ¿Lo detectaron las pruebas? | Detección | Corrección | ¿Verificado e instalado? | Verificación | Total |\n')
    f.write('|---|---|---|---|---|---|---|---|\n')
    for n, a, det, td, tf, ok, tv, tt in filas:
        f.write(f'| {n} | `{a}` | {"sí" if det else "NO"} | {td:.0f} s | {tf:.0f} s | {"sí" if ok else "NO"} | {tv:.0f} s | {tt/60:.1f} min |\n')
    f.write('\nLa corrección se hizo restaurando el código correcto (el arreglo real se escribe a mano; '
            'aquí se mide el ciclo detectar → corregir → probar → compilar → instalar → revisar logcat).\n')
    f.write(f'\nCódigo final sin cambios: {"sí" if not diff else "NO: " + diff}\n')
print(open(SALIDA / 'resumen.md', encoding='utf-8').read())
