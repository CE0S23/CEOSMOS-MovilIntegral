"""Escribe en build/web/sw.js la lista de precarga y la versión de la PWA.

Uso: python scripts/pwa_precache.py [build/web]

La versión es un hash del contenido: si cambia cualquier archivo, cambia sw.js, el
navegador instala el nuevo service worker y borra la caché anterior.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

web = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/web')
sw = web / 'sw.js'
if not sw.exists():
    sys.exit(f'No existe {sw}: compila primero con flutter build web.')

OMITIR = re.compile(
    r'(^\.last_build_id$|^sw\.js$|^flutter_service_worker\.js$|\.symbols$|\.map$'
    r'|^canvaskit/(skwasm|wimp)|^capturas/)'
)

archivos = sorted(
    p.relative_to(web).as_posix()
    for p in web.rglob('*')
    if p.is_file() and not OMITIR.search(p.relative_to(web).as_posix())
)
h = hashlib.sha256()
total = 0
for a in archivos:
    datos = (web / a).read_bytes()
    total += len(datos)
    h.update(a.encode())
    h.update(datos)
version = h.hexdigest()[:12]

texto = sw.read_text(encoding='utf-8')
texto, n1 = re.subn(r"const VERSION = '[^']*';", f"const VERSION = '{version}';", texto)
texto, n2 = re.subn(r'const PRECARGA = \[[^\]]*\];', 'const PRECARGA = ' + json.dumps(['./'] + archivos) + ';', texto)
if n1 != 1 or n2 != 1:
    sys.exit('sw.js no tiene los marcadores VERSION/PRECARGA esperados.')
sw.write_text(texto, encoding='utf-8', newline='\n')
print(f'PWA {version}: {len(archivos)} archivos precargados ({total / 1048576:.1f} MB)')
