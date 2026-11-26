#!/usr/bin/env bash
# Red Box contra PRODUCCIÓN: solo pruebas sin credenciales, no destructivas y a bajo ritmo
# (una petición cada 0,25 s ≈ 4 req/s, máximo 10). No inicia sesión con ninguna cuenta,
# no crea ni borra datos y no usa secretos. Las pruebas que exigen una sesión (IDOR, medios
# `javascript:`, rol) se cubren en local (redbox_api.sh 13/13, redbox_ampliado.sh 37/37)
# y en las pruebas de la API (src/blindaje.spec.ts).
#   bash scripts/redbox_produccion.sh > evidencias/blindaje/final/redbox_produccion.txt
API="${1:-https://ceosmos-api.vercel.app/api}"
ok=0; mal=0
code() { sleep 0.25; curl -s -o /dev/null -w "%{http_code}" "$@"; }
chk() { if [ "$2" = "$3" ]; then echo "PASA  $1 (esperado $2, obtenido $3)"; ok=$((ok+1)); else echo "FALLA $1 (esperado $2, obtenido $3)"; mal=$((mal+1)); fi; }
en() { for x in "${@:2}"; do [ "$1" = "$x" ] && { echo 1; return; }; done; echo "$1"; }
JS=(-H 'Content-Type: application/json')
# Tokens falsos firmados con una clave aleatoria (no la de producción).
forja() { python - "$1" "$2" <<'PY'
import sys,json,hmac,hashlib,base64,os,time
b=lambda x: base64.urlsafe_b64encode(x).rstrip(b'=').decode()
alg=sys.argv[2]; h=b(json.dumps({"alg":alg,"typ":"JWT"}).encode()); p=b(sys.argv[1].encode())
d={'HS256':hashlib.sha256,'HS512':hashlib.sha512}[alg]
print(h+'.'+p+'.'+b(hmac.new(os.urandom(32),(h+'.'+p).encode(),d).digest()))
PY
}
echo "Red Box producción $(date -u +%FT%TZ) · $API"
chk "P-01 sin token → 401" 401 "$(code "$API/devices")"
chk "P-02 token basura → 401" 401 "$(code -H 'Authorization: Bearer abc.def.ghi' "$API/devices")"
# En producción el firewall de Vercel corta antes el JWT alg:none (403, X-Vercel-Mitigated: deny).
chk "P-03 JWT alg:none → 401/403" 1 "$(en "$(code -H 'Authorization: Bearer eyJhbGciOiJub25lIn0.eyJzdWIiOiIxIn0.' "$API/devices")" 401 403)"
chk "P-04 JWT HS512 (otra clave) → 401, no 500" 401 "$(code -H "Authorization: Bearer $(forja '{"sub":"x","exp":9999999999}' HS512)" "$API/devices")"
chk "P-05 JWT con carga de otra forma (sub numérico, sin exp) → 401, no 500" 401 "$(code -H "Authorization: Bearer $(forja '{"sub":123,"role":"ADMIN"}' HS256)" "$API/users/me")"
chk "P-06 'Basic' en vez de Bearer → 401" 401 "$(code -H 'Authorization: Basic YTpi' "$API/devices")"
chk "P-07 'Bearer' vacío → 401" 401 "$(code -H 'Authorization: Bearer ' "$API/devices")"
chk "P-08 inyección SQL en login → 400/401" 1 "$(en "$(code -X POST "$API/auth/login" "${JS[@]}" -d "{\"email\":\"' OR 1=1 --\",\"password\":\"x' OR '1'='1\"}")" 400 401)"
chk "P-09 inyección NoSQL en login → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":{"$gt":""},"password":{"$gt":""}}')"
chk "P-10 tipos incorrectos en login → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":123,"password":["a"]}')"
chk "P-11 JSON malformado → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":')"
chk "P-12 text/plain → 400/401/415" 1 "$(en "$(code -X POST "$API/auth/login" -H 'Content-Type: text/plain' -d 'hola')" 400 401 415)"
# 1.4.0 · Campos sin espacios (correo inexistente: no toca cuentas reales ni el bloqueo).
chk "P-24 login con espacios en el correo → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"qa noexiste@example.com","password":"Clave#2026x"}')"
chk "P-25 login con espacios en la contraseña → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"qa.noexiste.espacios@example.com","password":"Clave #2026x"}')"
# Sin sesión el guard CSRF responde 403 antes de procesar el cuerpo: lo que importa es que no haya 500.
chk "P-13 JSON anidado 5000 niveles sin sesión → 400/403/413, no 500" 1 "$(en "$(python -c 'print("{\"a\":"*5000+"1"+"}"*5000)' | code -X POST "$API/tasks" "${JS[@]}" --data-binary @-)" 400 403 413)"
chk "P-14 cuerpo de 2 MB → 400/403/413" 1 "$(en "$(head -c 2000000 /dev/zero | tr '\0' 'a' | sed 's/^/{"name":"/;s/$/"}/' | code -X POST "$API/devices" "${JS[@]}" --data-binary @-)" 400 403 413)"
chk "P-15 método TRACE → 404/405" 1 "$(en "$(code -X TRACE "$API/devices")" 404 405)"
sleep 0.25; C=$(curl -s -D - -o /dev/null -X OPTIONS "$API/devices" -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: GET')
chk "P-16 CORS origen ajeno: sin Allow-Origin" 0 "$(echo "$C" | grep -ci 'access-control-allow-origin: https://evil.example')"
chk "P-17 CORS origen ajeno: no 500" 0 "$(echo "$C" | head -1 | grep -c ' 500')"
sleep 0.25; G=$(curl -s -D - -o /dev/null "$API/devices" -H 'Origin: https://evil.example')
chk "P-18 GET con origen ajeno: no 500" 0 "$(echo "$G" | head -1 | grep -c ' 500')"
sleep 0.25; H=$(curl -s -D - -o /dev/null "$API/health")
for cab in 'content-security-policy' 'x-content-type-options: nosniff' 'x-frame-options' 'referrer-policy' 'strict-transport-security'; do
  chk "P-19 cabecera '$cab'" 1 "$(echo "$H" | grep -qi "$cab" && echo 1 || echo 0)"
done
chk "P-20 sin X-Powered-By" 0 "$(echo "$H" | grep -ci 'x-powered-by')"
sleep 0.25; chk "P-21 errores sin traza" 0 "$(curl -s -X POST "$API/auth/login" "${JS[@]}" -d '{"email":' | grep -ciE 'at [A-Za-z]+ \(|node_modules|\.ts:')"
sleep 0.25; M=$(curl -s -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"noexiste_blindaje@example.com","password":"Incorrecta#1"}')
chk "P-22 login: mensaje genérico (sin intentos restantes)" 0 "$(echo "$M" | grep -ciE 'intent|attempt|remaining|restante')"
ULT=""; for i in $(seq 1 14); do ULT=$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"fuerza_bruta_blindaje@example.com","password":"Intento#'"$i"'"}'); done
chk "P-23 fuerza bruta: 14 intentos/min → 429" 429 "$ULT"
echo "Resultado: $ok pasan, $mal fallan"
