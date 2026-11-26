#!/usr/bin/env bash
# Red Box AMPLIADO contra la API LOCAL de CEOSMOS (base .devdb). Nunca contra producción.
# Complementa scripts/redbox_api.sh (RB-01..13). La API local debe arrancar con un
# JWT_SECRET de PRUEBA desechable (no el de producción); su ruta se pasa en
# JWT_PRUEBA_ARCHIVO para fabricar tokens expirados o de usuarios inexistentes.
#   JWT_PRUEBA_ARCHIVO=/ruta/secreto.txt bash scripts/redbox_ampliado.sh > evidencias/blindaje/redbox_ampliado.txt
API="${1:-http://127.0.0.1:8081/api}"
case "$API" in *127.0.0.1*|*localhost*) ;; *) echo "Solo API local"; exit 1;; esac
PASS='P11#Carga2026'
j() { python -c 'import sys,json;d=json.load(sys.stdin);print(d.get(sys.argv[1],""))' "$1" 2>/dev/null; }
login() { curl -s -X POST "$API/auth/login" -H 'Content-Type: application/json' -d "{\"email\":\"$1\",\"password\":\"$2\"}"; }
code() { curl -s -o /dev/null -w "%{http_code}" "$@"; }
ok=0; mal=0
chk() { if [ "$2" = "$3" ]; then echo "PASA  $1 (esperado $2, obtenido $3)"; ok=$((ok+1)); else echo "FALLA $1 (esperado $2, obtenido $3)"; mal=$((mal+1)); fi; }
en() { for x in "${@:2}"; do [ "$1" = "$x" ] && { echo 1; return; }; done; echo "$1"; }

tok() { local r; r=$(login "$1" "$PASS"); local t; t=$(echo "$r" | j accessToken); [ -z "$t" ] && t=$(echo "$r" | j token); echo "$t"; }
TA=$(tok p11_wb@ceosmos.test); TB=$(tok p11_wb2@ceosmos.test)
echo "Tokens obtenidos: A=$([ -n "$TA" ] && echo sí || echo no) B=$([ -n "$TB" ] && echo sí || echo no)"
AUTH=(-H "Authorization: Bearer $TA")
JS=(-H 'Content-Type: application/json')

# --- Tokens manipulados (firmados con el secreto de PRUEBA de la API local) ---
forja() { # $1 = JSON de la carga útil, $2 = alg
  python - "$1" "${2:-HS256}" "$JWT_PRUEBA_ARCHIVO" <<'PY'
import sys,json,hmac,hashlib,base64,time
b=lambda x: base64.urlsafe_b64encode(x).rstrip(b'=').decode()
payload=json.loads(sys.argv[1].replace('AHORA',str(int(time.time()))))
alg=sys.argv[2]; key=open(sys.argv[3]).read().strip().encode()
h=b(json.dumps({"alg":alg,"typ":"JWT"}).encode()); p=b(json.dumps(payload).encode())
dig={'HS256':hashlib.sha256,'HS512':hashlib.sha512}[alg]
print(h+'.'+p+'.'+b(hmac.new(key,(h+'.'+p).encode(),dig).digest()))
PY
}
SUB_A=$(curl -s "$API/users/me" "${AUTH[@]}" | j id)
if [ -n "$JWT_PRUEBA_ARCHIVO" ] && [ -n "$SUB_A" ]; then
  EXP=$(forja "{\"sub\":\"$SUB_A\",\"iat\":1700000000,\"exp\":1700000600}")
  chk "RB-14 token expirado (firma válida) → 401" 401 "$(code "$API/devices" -H "Authorization: Bearer $EXP")"
  FANT=$(forja '{"sub":"00000000-0000-0000-0000-000000000000","iat":AHORA,"exp":9999999999}')
  chk "RB-15 token de un usuario inexistente → 401" 401 "$(code "$API/devices" -H "Authorization: Bearer $FANT")"
  H512=$(forja "{\"sub\":\"$SUB_A\",\"iat\":AHORA,\"exp\":9999999999}" HS512)
  chk "RB-16 algoritmo cambiado a HS512 → 401" 401 "$(code "$API/devices" -H "Authorization: Bearer $H512")"
  ROL=$(forja "{\"sub\":\"$SUB_A\",\"role\":\"ADMIN\",\"iat\":AHORA,\"exp\":9999999999}")
  chk "RB-17 token con role=ADMIN inventado no abre /admin → 401/403" 1 "$(en "$(code "$API/admin/users" -H "Authorization: Bearer $ROL")" 401 403)"
else
  echo "OMITIDO RB-14..17 (falta JWT_PRUEBA_ARCHIVO)"
fi
chk "RB-18 cabecera 'Basic' en lugar de Bearer → 401" 401 "$(code "$API/devices" -H 'Authorization: Basic YTpi')"
chk "RB-19 'Bearer' vacío → 401" 401 "$(code "$API/devices" -H 'Authorization: Bearer ')"
chk "RB-20 token de A con firma de B (mezcla) → 401" 401 "$(code "$API/devices" -H "Authorization: Bearer ${TA%.*}.${TB##*.}")"

# --- Inyección y validación ---
chk "RB-21 inyección NoSQL {\$gt:''} en login → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":{"$gt":""},"password":{"$gt":""}}')"
chk "RB-22 tipos incorrectos (número/array) en login → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":123,"password":["a"]}')"
chk "RB-23 JSON malformado → 400" 400 "$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":')"
chk "RB-24 Content-Type text/plain → 400/401/415 (no 500)" 1 "$(en "$(code -X POST "$API/auth/login" -H 'Content-Type: text/plain' -d 'hola')" 400 401 415)"
chk "RB-25 inyección SQL en búsqueda → 200/400 sin 500" 1 "$(en "$(code -G "$API/search" "${AUTH[@]}" --data-urlencode "q=' OR 1=1; DROP TABLE \"User\"; --")" 200 400)"
chk "RB-26 path traversal en favoritos → 400/404 (no 500)" 1 "$(en "$(code -X PUT "$API/favorites/..%2F..%2Fetc%2Fpasswd" "${AUTH[@]}")" 400 404)"
XSS='<img src=x onerror=alert(1)><script>alert(1)</script>'
R=$(curl -s -D - -o /dev/null -X POST "$API/tasks" "${AUTH[@]}" "${JS[@]}" -d "{\"title\":\"$XSS\"}")
chk "RB-27 XSS almacenado: la respuesta es JSON con nosniff (no HTML)" 1 "$(echo "$R" | grep -qi 'content-type: application/json' && echo "$R" | grep -qi 'x-content-type-options: nosniff' && echo 1 || echo 0)"
chk "RB-28 medio IMAGE con url javascript: → 400" 400 "$(code -X POST "$API/media" "${AUTH[@]}" "${JS[@]}" -d '{"type":"IMAGE","url":"javascript:alert(1)","title":"x"}')"
chk "RB-29 asignación masiva en perfil (role=ADMIN) → 400" 400 "$(code -X PATCH "$API/users/profile" "${AUTH[@]}" "${JS[@]}" -d '{"role":"ADMIN"}')"
chk "RB-30 el rol de A sigue siendo USER" USER "$(curl -s "$API/users/me" "${AUTH[@]}" | j role)"
chk "RB-31 JSON muy anidado (5000 niveles) → 400/413 (no 500)" 1 "$(en "$(python -c 'print("{\"a\":"*5000+"1"+"}"*5000)' | curl -s -o /dev/null -w '%{http_code}' -X POST "$API/tasks" "${AUTH[@]}" "${JS[@]}" --data-binary @-)" 400 413)"
chk "RB-32 título de 100 000 caracteres → 400/413" 1 "$(en "$(python -c 'print("{\"title\":\""+"a"*100000+"\"}")' | curl -s -o /dev/null -w '%{http_code}' -X POST "$API/tasks" "${AUTH[@]}" "${JS[@]}" --data-binary @-)" 400 413)"

# --- IDOR en más recursos ---
TID=$(curl -s -X POST "$API/tasks" -H "Authorization: Bearer $TB" "${JS[@]}" -d '{"title":"tarea de B"}' | j id)
chk "RB-33 A modifica una tarea de B → 403/404" 1 "$(en "$(code -X PATCH "$API/tasks/$TID" "${AUTH[@]}" "${JS[@]}" -d '{"title":"hack"}')" 403 404)"
chk "RB-34 A borra una tarea de B → 403/404" 1 "$(en "$(code -X DELETE "$API/tasks/$TID" "${AUTH[@]}")" 403 404)"
curl -s -o /dev/null -X DELETE "$API/tasks/$TID" -H "Authorization: Bearer $TB"
chk "RB-35 USER cambia el rol de otro (/users/:id/role) → 403" 403 "$(code -X PATCH "$API/users/$SUB_A/role" "${AUTH[@]}" "${JS[@]}" -d '{"role":"ADMIN"}')"
chk "RB-36 USER lista todos los usuarios (/users) → 403" 403 "$(code "$API/users" "${AUTH[@]}")"

# --- Métodos, cabeceras y CORS ---
chk "RB-37 método TRACE → 404/405" 1 "$(en "$(code -X TRACE "$API/devices" "${AUTH[@]}")" 404 405)"
chk "RB-38 PUT no definido en /devices → 404/405" 1 "$(en "$(code -X PUT "$API/devices" "${AUTH[@]}")" 404 405)"
C=$(curl -s -D - -o /dev/null -X OPTIONS "$API/devices" -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: GET')
chk "RB-39 CORS: origen ajeno sin Access-Control-Allow-Origin" 0 "$(echo "$C" | grep -ci 'access-control-allow-origin: https://evil.example')"
chk "RB-40 CORS: origen ajeno no provoca error 500" 0 "$(echo "$C" | head -1 | grep -c ' 500')"
H=$(curl -s -D - -o /dev/null "$API/health")
for cab in 'x-content-type-options: nosniff' 'x-frame-options' 'content-security-policy' 'referrer-policy'; do
  chk "RB-41 cabecera de seguridad '$cab'" 1 "$(echo "$H" | grep -qi "$cab" && echo 1 || echo 0)"
done
chk "RB-42 sin X-Powered-By" 0 "$(echo "$H" | grep -ci 'x-powered-by')"
chk "RB-43 errores sin traza ni rutas internas" 0 "$(curl -s -X POST "$API/auth/login" "${JS[@]}" -d '{"email":' | grep -ciE 'at [A-Za-z]+ \(|node_modules|\.ts:')"

# --- Enumeración y fuerza bruta ---
E1=$(curl -s -w ' %{http_code}' -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"p11_wb@ceosmos.test","password":"Incorrecta#1"}')
E2=$(curl -s -w ' %{http_code}' -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"noexiste_zz@ceosmos.test","password":"Incorrecta#1"}')
chk "RB-44 login: misma respuesta con correo existente y no existente" 1 "$([ "$E1" = "$E2" ] && echo 1 || echo "distinta")"
F1=$(curl -s -w ' %{http_code}' -X POST "$API/auth/forgot-password" "${JS[@]}" -d '{"email":"p11_wb@ceosmos.test"}')
F2=$(curl -s -w ' %{http_code}' -X POST "$API/auth/forgot-password" "${JS[@]}" -d '{"email":"noexiste_zz@ceosmos.test"}')
chk "RB-45 recuperar contraseña: misma respuesta exista o no la cuenta" 1 "$([ "$F1" = "$F2" ] && echo 1 || echo "distinta")"
ULT=""; for i in $(seq 1 14); do ULT=$(code -X POST "$API/auth/login" "${JS[@]}" -d '{"email":"fuerza_bruta@ceosmos.test","password":"Intento#'"$i"'"}'); done
chk "RB-46 fuerza bruta: 14 intentos/min → 429" 429 "$ULT"

# --- Reutilización tras logout (después de todo lo demás) ---
curl -s -o /dev/null -X POST "$API/auth/logout" -H "Authorization: Bearer $TB"
chk "RB-47 token de B reutilizado tras logout → 401" 401 "$(code "$API/users/me" -H "Authorization: Bearer $TB")"

echo "Resultado: $ok pasan, $mal fallan"
