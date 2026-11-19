#!/usr/bin/env python3
"""P13-14 · Resume el reporte JSON de `flutter test` (--machine / --file-reporter json)
y la cobertura lcov. Uso: python3 scripts/resumen_pruebas.py <resultados.json> [lcov.info]
Imprime una tabla Markdown (sirve para $GITHUB_STEP_SUMMARY y para las evidencias)."""
import json
import sys


def resumir(ruta_json):
    pruebas, aprobadas, fallidas, omitidas, tiempo_ms = {}, 0, 0, 0, 0
    fallos = []
    with open(ruta_json, encoding="utf-8", errors="replace") as f:
        for linea in f:
            linea = linea.strip()
            if not linea.startswith("{"):
                continue
            try:
                e = json.loads(linea)
            except json.JSONDecodeError:
                continue
            if isinstance(e, list):
                continue
            t = e.get("type")
            if t == "testStart":
                pruebas[e["test"]["id"]] = e["test"]["name"]
            elif t == "testDone" and not e.get("hidden"):
                if e.get("skipped"):
                    omitidas += 1
                elif e.get("result") == "success":
                    aprobadas += 1
                else:
                    fallidas += 1
                    fallos.append(pruebas.get(e["testID"], str(e["testID"])))
            elif t == "done":
                tiempo_ms = e.get("time", 0)
    return aprobadas, fallidas, omitidas, tiempo_ms, fallos


def cobertura(ruta_lcov):
    lf = lh = 0
    with open(ruta_lcov, encoding="utf-8") as f:
        for linea in f:
            if linea.startswith("LF:"):
                lf += int(linea[3:])
            elif linea.startswith("LH:"):
                lh += int(linea[3:])
    return lh, lf


def main():
    ok, ko, sk, ms, fallos = resumir(sys.argv[1])
    print("| Ejecutadas | Aprobadas | Fallidas | Omitidas | Tiempo |")
    print("| --- | --- | --- | --- | --- |")
    print(f"| {ok + ko} | {ok} | {ko} | {sk} | {ms / 1000:.1f} s |")
    if len(sys.argv) > 2:
        try:
            lh, lf = cobertura(sys.argv[2])
            print(f"\nCobertura de líneas: **{100 * lh / lf:.1f} %** ({lh} de {lf})")
        except (OSError, ZeroDivisionError):
            print("\nCobertura: no disponible")
    for n in fallos:
        print(f"- FALLÓ: {n}")
    sys.exit(1 if ko else 0)


if __name__ == "__main__":
    main()
