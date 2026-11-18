#!/usr/bin/env bash
# Red Box contra la API LOCAL de CEOSMOS (base .devdb). Nunca contra producción.
#   bash scripts/redbox_api.sh [http://127.0.0.1:8080/api] > evidencias/redbox_api.txt
API="${1:-http://127.0.0.1:8080/api}"
case "$API" in *127.0.0.1*|*localhost*) ;; *) echo "Solo API local"; exit 1;; esac
PASS='P11#Carga2026'
j() { python -c 'import sys,json;d=json.load(sys.stdin);print(d.get(sys.argv[1],""))' "$1" 2>/dev/null; }
login() { curl -s -X POST "$API/auth/login" -H 'Content-Type: application/json' -d "{\"email\":\"$1\",\"password\":\"$2\"}"; }
code() { curl -s -o /dev/null -w "%{http_code}" "$@"; }
ok=0; mal=0
chk() { if [ "$2" = "$3" ]; then echo "PASA  $1 (esperado $2, obtenido $3)"; ok=$((ok+1)); else echo "FALLA $1 (esperado $2, obtenido $3)"; mal=$((mal+1)); fi; }

TA=$(login p11_wb@ceosmos.test "$PASS" | j accessToken); [ -z "$TA" ] && TA=$(login p11_wb@ceosmos.test "$PASS" | j token)
TB=$(login p11_wb2@ceosmos.test "$PASS" | j accessToken); [ -z "$TB" ] && TB=$(login p11_wb2@ceosmos.test "$PASS" | j token)
echo "Tokens obtenidos: A=${TA:+sí} B=${TB:+sí}"

chk "RB-01 sin token → 401" 401 "$(code "$API/devices")"
chk "RB-02 token alterado → 401" 401 "$(code -H "Authorization: Bearer ${TA}x" "$API/devices")"
chk "RB-03 JWT 'alg:none' → 401" 401 "$(code -H 'Authorization: Bearer eyJhbGciOiJub25lIn0.eyJzdWIiOiIxIn0.' "$API/devices")"
chk "RB-04 inyección SQL en login → 401/400 (no 200/500)" 1 "$(c=$(code -X POST "$API/auth/login" -H 'Content-Type: application/json' -d "{\"email\":\"' OR 1=1 --\",\"password\":\"x' OR '1'='1\"}"); [ "$c" = 401 ] || [ "$c" = 400 ] && echo 1 || echo $c)"
# B crea un dispositivo BLE; A intenta leerlo, modificarlo y borrarlo (IDOR/BOLA)
DID=$(curl -s -X POST "$API/devices" -H "Authorization: Bearer $TB" -H 'Content-Type: application/json' \
  -d '{"name":"Reloj de B","type":"WEARABLE","transport":"BLE","address":"CE:05:AA:BB:CC:DD"}' | j id)
echo "Dispositivo de B: ${DID:-no creado}"
chk "RB-05 A modifica dispositivo de B → 404" 404 "$(code -X PATCH "$API/devices/$DID" -H "Authorization: Bearer $TA" -H 'Content-Type: application/json' -d '{"name":"hack"}')"
chk "RB-06 A borra dispositivo de B → 404" 404 "$(code -X DELETE "$API/devices/$DID" -H "Authorization: Bearer $TA")"
chk "RB-07 A no ve el dispositivo de B en su lista" 0 "$(curl -s "$API/devices" -H "Authorization: Bearer $TA" | grep -c "$DID")"
chk "RB-08 asignación masiva (userId ajeno / campo extra) → 400" 400 "$(code -X POST "$API/devices" -H "Authorization: Bearer $TA" -H 'Content-Type: application/json' -d '{"name":"x","type":"TV","transport":"BLE","address":"CE:05:00:00:00:01","userId":"otro"}')"
chk "RB-09 dirección inválida → 400" 400 "$(code -X POST "$API/devices" -H "Authorization: Bearer $TA" -H 'Content-Type: application/json' -d '{"name":"x","type":"TV","transport":"BLE","address":"<script>"}')"
chk "RB-10 cuerpo enorme (2 MB) → 413/400" 1 "$(c=$(head -c 2000000 /dev/zero | tr '\0' 'a' | sed 's/^/{"name":"/;s/$/"}/' | curl -s -o /dev/null -w '%{http_code}' -X POST "$API/devices" -H "Authorization: Bearer $TA" -H 'Content-Type: application/json' --data-binary @-); [ "$c" = 413 ] || [ "$c" = 400 ] && echo 1 || echo $c)"
chk "RB-11 USER entra a /admin → 403" 403 "$(code "$API/admin/users" -H "Authorization: Bearer $TA")"
chk "RB-12 la respuesta de /users/me no expone el hash" 0 "$(curl -s "$API/users/me" -H "Authorization: Bearer $TA" | grep -ciE 'password|hash')"
curl -s -o /dev/null -X POST "$API/auth/logout" -H "Authorization: Bearer $TA"
chk "RB-13 token tras logout → 401" 401 "$(code "$API/devices" -H "Authorization: Bearer $TA")"
curl -s -o /dev/null -X DELETE "$API/devices/$DID" -H "Authorization: Bearer $TB"
echo "Resultado: $ok pasan, $mal fallan"
