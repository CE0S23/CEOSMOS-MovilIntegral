\set ON_ERROR_STOP on
\timing on
\echo '##### DESPUÉS de la migración 20261112090000_p11_correcciones (índices reales) #####'
BEGIN;
INSERT INTO "User"(id, email, username, "passwordHash", "updatedAt")
SELECT 'p11-u-' || g, 'p11-u-' || g || '@vol.test', 'p11vol' || g, 'x', now() FROM generate_series(1, 2000) g;
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed)
SELECT 'p11-v-' || g, 'p11-u-' || (g % 2000 + 1), 'orbit', 'FOCUS', now() - (g || ' min')::interval,
       now() - (g || ' min')::interval + interval '5 min', 300, 5, true FROM generate_series(1, 100000) g;
INSERT INTO "MediaItem"(id,"userId",type,url,"createdAt")
SELECT 'p11-m-' || g, 'p11-u-' || (g % 2000 + 1), 'IMAGE', 'https://img.test/' || g || '.jpg', now() - (g || ' s')::interval
FROM generate_series(1, 100000) g;
INSERT INTO "Session"(id,"userId",token,"expiresAt")
SELECT 'p11-s-' || g, 'p11-u-' || (g % 2000 + 1), md5('p11' || g), now() + interval '7 days' FROM generate_series(1, 20000) g;
ANALYZE "FocusSession"; ANALYZE "MediaItem"; ANALYZE "Session";
\echo '--- Q1 con 100 000 sesiones de enfoque ---'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "FocusSession" WHERE "userId" = 'p11-u-7' ORDER BY "startedAt" DESC LIMIT 50;
\echo '--- Q2 con 100 000 elementos de biblioteca (sin índice en userId) ---'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "MediaItem" WHERE "userId" = 'p11-u-7' ORDER BY "createdAt" DESC;
\echo '--- Q2b addMedia: count(*) del usuario antes de insertar ---'
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM "MediaItem" WHERE "userId" = 'p11-u-7';
\echo '--- Q3 con 20 000 sesiones: búsqueda por token (índice UNIQUE) ---'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "Session" WHERE token = md5('p11777');
\echo '--- Q4 con 20 000 sesiones: por userId (sin índice) ---'
EXPLAIN (ANALYZE, BUFFERS) SELECT id, "createdAt", "ipAddress" FROM "Session" WHERE "userId" = 'p11-u-7' ORDER BY "createdAt" DESC LIMIT 10;
ROLLBACK;
