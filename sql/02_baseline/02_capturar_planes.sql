-- =============================================================================
-- 02_capturar_planes.sql
-- Captura los planes de ejecución de las 6 consultas baseline SIN optimización.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- NOTA: estos planes reflejan el estado del optimizador sin índices adicionales
-- (solo existe la PK sobre ID). Se espera ver FULL TABLE SCAN en la mayoría de
-- consultas — evidencia del problema que resolverá la Fase 3.
-- Los planes quedan almacenados en PLAN_TABLE y se muestran con DBMS_XPLAN.DISPLAY.
-- =============================================================================

SET PAGESIZE  200
SET LINESIZE  180
SET FEEDBACK   OFF

-- =============================================================================
PROMPT === PLAN Q1: Establecimientos por entidad federativa ===
-- =============================================================================

EXPLAIN PLAN FOR
SELECT entidad,
       cve_ent,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
GROUP  BY entidad, cve_ent
ORDER  BY num_establecimientos DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));

-- =============================================================================
PROMPT === PLAN Q2: Comercio al por menor (SCIAN 46) en CDMX ===
-- =============================================================================

EXPLAIN PLAN FOR
SELECT id,
       nom_estab,
       codigo_act,
       nombre_act,
       municipio,
       per_ocu
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '46%'
  AND  cve_ent = 9
ORDER  BY municipio, nom_estab;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));

-- =============================================================================
PROMPT === PLAN Q3: Top 20 municipios — servicios de alimentos (SCIAN 72) ===
-- =============================================================================

EXPLAIN PLAN FOR
SELECT entidad,
       municipio,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '72%'
GROUP  BY entidad, municipio
ORDER  BY num_establecimientos DESC
FETCH  FIRST 20 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));

-- =============================================================================
PROMPT === PLAN Q4: Establecimientos grandes — 251 y más personas ===
-- =============================================================================

EXPLAIN PLAN FOR
SELECT id,
       nom_estab,
       raz_social,
       codigo_act,
       nombre_act,
       entidad,
       municipio,
       per_ocu
FROM   DENUE_ESTABLECIMIENTOS
WHERE  per_ocu LIKE '%251 y más personas%'
ORDER  BY entidad, nom_estab;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));

-- =============================================================================
PROMPT === PLAN Q5: Distribución por personal — sector manufacturero (SCIAN 31-33) ===
-- =============================================================================

EXPLAIN PLAN FOR
SELECT per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '31%'
   OR  codigo_act LIKE '32%'
   OR  codigo_act LIKE '33%'
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));

-- =============================================================================
PROMPT === PLAN Q6: Tiendas OXXO ===
-- =============================================================================

EXPLAIN PLAN FOR
SELECT id,
       nom_estab,
       entidad,
       municipio,
       cod_postal,
       latitud,
       longitud
FROM   DENUE_ESTABLECIMIENTOS
WHERE  nom_estab LIKE '%OXXO%'
ORDER  BY entidad, municipio;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'TYPICAL'));

SET FEEDBACK ON
PROMPT
PROMPT === Todos los planes baseline capturados ===
PROMPT Observar operación TABLE ACCESS FULL en la columna Operation —
PROMPT ese es el punto de partida que optimizaremos en la Fase 3.
