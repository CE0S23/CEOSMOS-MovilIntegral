-- Práctica 11 · Fase 4: White Box de la base de datos de CEOSMOS (PostgreSQL 16 local, .devdb)
-- Operaciones de las tablas que usa la app móvil: FocusSession, Favorite, LinkedDevice.
-- Ejecutar: psql -h 127.0.0.1 -p 5433 -U ceosmos -d ceosmos_dev -v uid=<id> -f fase4_crud.sql
\set ON_ERROR_STOP off
\set VERBOSITY default
\timing on
\echo '=== Fecha y servidor ==='
SELECT now() AS fecha, version();

\echo '=== DB-01 Inserción válida (FocusSession) ==='
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed,metadata)
VALUES ('p11-fs-0001', :'uid', 'orbit', 'FOCUS', now() - interval '10 min', now() - interval '5 min', 300, 5, true,
        '{"source":"p11-fase4","wearable":{"samples":3,"avgHeartRate":71.3}}')
RETURNING id, "userId", "durationSeconds", metadata->'wearable'->>'avgHeartRate' AS hr_promedio;

\echo '=== DB-02 Integridad: inserciones incompletas o inválidas (deben FALLAR) ==='
\echo '-- NOT NULL: contentKey nulo'
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes")
VALUES ('p11-fs-bad1', :'uid', NULL, 'FOCUS', now(), now(), 0, 5);
\echo '-- CHECK: durationSeconds > targetMinutes*60'
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes")
VALUES ('p11-fs-bad2', :'uid', 'orbit', 'FOCUS', now() - interval '1 h', now(), 3601, 60);
\echo '-- CHECK: endedAt < startedAt'
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes")
VALUES ('p11-fs-bad3', :'uid', 'orbit', 'FOCUS', now(), now() - interval '1 min', 10, 5);
\echo '-- ENUM: modo inexistente'
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes")
VALUES ('p11-fs-bad4', :'uid', 'orbit', 'SLEEP', now(), now(), 0, 5);
\echo '-- FOREIGN KEY: usuario inexistente'
INSERT INTO "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes")
VALUES ('p11-fs-bad5', '00000000-0000-0000-0000-000000000000', 'orbit', 'FOCUS', now(), now(), 0, 5);
\echo '-- UNIQUE: favorito repetido (userId, contentKey)'
INSERT INTO "Favorite"(id,"userId","contentKey") VALUES ('p11-fav-1', :'uid', 'p11:aurora');
INSERT INTO "Favorite"(id,"userId","contentKey") VALUES ('p11-fav-2', :'uid', 'p11:aurora');
\echo '-- CHECK: contentKey de 81 caracteres'
INSERT INTO "Favorite"(id,"userId","contentKey") VALUES ('p11-fav-3', :'uid', repeat('k', 81));
\echo '-- UNIQUE: dispositivo con la misma dirección'
INSERT INTO "LinkedDevice"(id,"userId",name,type,transport,address,"updatedAt") VALUES ('p11-dev-1', :'uid', 'Banda P11', 'WEARABLE', 'TCP', '10.0.2.2:5050', now());
INSERT INTO "LinkedDevice"(id,"userId",name,type,transport,address,"updatedAt") VALUES ('p11-dev-2', :'uid', 'Copia', 'WEARABLE', 'TCP', '10.0.2.2:5050', now());

\echo '=== Transacción: la segunda inserción falla → ROLLBACK, no queda nada a medias ==='
BEGIN;
INSERT INTO "Favorite"(id,"userId","contentKey") VALUES ('p11-tx-1', :'uid', 'p11:tx-uno');
INSERT INTO "Favorite"(id,"userId","contentKey") VALUES ('p11-tx-2', :'uid', 'p11:aurora'); -- viola UNIQUE
COMMIT; -- PostgreSQL convierte el COMMIT de una transacción abortada en ROLLBACK
SELECT count(*) AS filas_de_la_transaccion FROM "Favorite" WHERE id IN ('p11-tx-1','p11-tx-2');

\echo '=== DB-03 Consulta por id existente / inexistente ==='
SELECT id, "contentKey", mode, "durationSeconds" FROM "FocusSession" WHERE id = 'p11-fs-0001';
SELECT id FROM "FocusSession" WHERE id = 'no-existe-p11';

\echo '=== DB-04 Actualización (LinkedDevice.lastSeenAt, como PATCH /devices/:id) ==='
UPDATE "LinkedDevice" SET "lastSeenAt" = now(), "updatedAt" = now()
WHERE id = 'p11-dev-1' AND "userId" = :'uid' RETURNING id, "lastSeenAt" IS NOT NULL AS visto;
\echo '-- Intento de actualizar el dispositivo con OTRO usuario (filtro userId): 0 filas'
UPDATE "LinkedDevice" SET name = 'robado' WHERE id = 'p11-dev-1' AND "userId" = '00000000-0000-0000-0000-000000000000';

\echo '=== DB-05 Eliminación y verificación de persistencia ==='
DELETE FROM "LinkedDevice" WHERE id = 'p11-dev-1' AND "userId" = :'uid';
SELECT count(*) AS dispositivo_tras_borrar FROM "LinkedDevice" WHERE id = 'p11-dev-1';
DELETE FROM "Favorite" WHERE id = 'p11-fav-1';
DELETE FROM "FocusSession" WHERE id = 'p11-fs-0001';
SELECT (SELECT count(*) FROM "FocusSession" WHERE id LIKE 'p11-fs-%') AS sesiones_p11,
       (SELECT count(*) FROM "Favorite" WHERE id LIKE 'p11-%') AS favoritos_p11;

\echo '=== Riesgo de inyección SQL: Prisma usa consultas parametrizadas; búsqueda de SQL crudo ==='
SELECT 'ver evidencias/fase4_db/sql_crudo.txt' AS nota;
