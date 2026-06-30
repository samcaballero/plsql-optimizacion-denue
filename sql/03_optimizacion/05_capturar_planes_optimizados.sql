-- =============================================================================
-- 05_capturar_planes_optimizados.sql
-- Captura planes de ejecución reales de las 6 consultas optimizadas.
-- Usa gather_plan_statistics + SQL_ID explícito vía tag único por consulta.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- DIFERENCIA CON EXPLAIN PLAN (Fase 2):
-- EXPLAIN PLAN genera un plan estimado sin ejecutar la consulta — muestra
-- E-Rows (filas estimadas) pero no A-Rows (filas reales). Con el hint
-- gather_plan_statistics + DBMS_XPLAN.DISPLAY_CURSOR se obtiene el plan
-- de la ejecución real, mostrando A-Rows vs E-Rows lado a lado.
--
-- POR QUÉ SE BUSCA EL SQL_ID EXPLÍCITAMENTE (y no NULL/NULL):
-- DISPLAY_CURSOR(NULL, NULL, ...) busca "el último SQL de la sesión", pero
-- SQLcl emite llamadas internas a dbms_output.get_line entre la consulta del
-- usuario y la llamada a DISPLAY_CURSOR, desplazando el cursor interno. El
-- resultado es que DISPLAY_CURSOR muestra el plan de una sentencia interna
-- de SQLcl en vez de la consulta que nos interesa. La solución es etiquetar
-- cada consulta con un comentario único (TAG_Qn_DENUE) y recuperar su SQL_ID
-- desde v$sql justo antes de mostrar el plan.
-- =============================================================================

SET PAGESIZE   200
SET LINESIZE   200
SET FEEDBACK    OFF
SET SERVEROUTPUT OFF   -- evita que dbms_output.get_line contamine v$sql

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q1: Establecimientos por entidad federativa ===
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       entidad,
       cve_ent,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS  -- TAG_Q1_DENUE
GROUP  BY entidad, cve_ent
ORDER  BY num_establecimientos DESC;

COLUMN v_sql_id NEW_VALUE v_sql_id NOPRINT
SELECT sql_id AS v_sql_id
FROM   v$sql
WHERE  sql_text LIKE '%TAG_Q1_DENUE%'
  AND  sql_text LIKE '%gather_plan_statistics%'
ORDER  BY last_active_time DESC
FETCH  FIRST 1 ROW ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id', 0, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q2: Comercio al por menor (SCIAN 46) en CDMX ===
-- Esperado: INDEX RANGE SCAN sobre IX_DENUE_ENT_ACT
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       id,
       nom_estab,
       codigo_act,
       nombre_act,
       municipio,
       per_ocu
FROM   DENUE_ESTABLECIMIENTOS  -- TAG_Q2_DENUE
WHERE  codigo_act LIKE '46%'
  AND  cve_ent = 9
ORDER  BY municipio, nom_estab;

COLUMN v_sql_id NEW_VALUE v_sql_id NOPRINT
SELECT sql_id AS v_sql_id
FROM   v$sql
WHERE  sql_text LIKE '%TAG_Q2_DENUE%'
  AND  sql_text LIKE '%gather_plan_statistics%'
ORDER  BY last_active_time DESC
FETCH  FIRST 1 ROW ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id', 0, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q3: Top 20 municipios — alimentos (SCIAN 72) ===
-- Esperado: INDEX RANGE SCAN sobre IX_DENUE_CODIGO_ACT
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       entidad,
       municipio,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS  -- TAG_Q3_DENUE
WHERE  codigo_act LIKE '72%'
GROUP  BY entidad, municipio
ORDER  BY num_establecimientos DESC
FETCH  FIRST 20 ROWS ONLY;

COLUMN v_sql_id NEW_VALUE v_sql_id NOPRINT
SELECT sql_id AS v_sql_id
FROM   v$sql
WHERE  sql_text LIKE '%TAG_Q3_DENUE%'
  AND  sql_text LIKE '%gather_plan_statistics%'
ORDER  BY last_active_time DESC
FETCH  FIRST 1 ROW ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id', 0, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q4: Establecimientos grandes — 251 y más personas ===
-- Esperado: BITMAP INDEX SINGLE VALUE sobre IX_DENUE_PER_OCU_BMP
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       id,
       nom_estab,
       raz_social,
       codigo_act,
       nombre_act,
       entidad,
       municipio,
       per_ocu
FROM   DENUE_ESTABLECIMIENTOS  -- TAG_Q4_DENUE
WHERE  per_ocu LIKE '%251 y más personas%'
ORDER  BY entidad, nom_estab;

COLUMN v_sql_id NEW_VALUE v_sql_id NOPRINT
SELECT sql_id AS v_sql_id
FROM   v$sql
WHERE  sql_text LIKE '%TAG_Q4_DENUE%'
  AND  sql_text LIKE '%gather_plan_statistics%'
ORDER  BY last_active_time DESC
FETCH  FIRST 1 ROW ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id', 0, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q5: Distribución manufactura (SCIAN 31-33) ===
-- Esperado: INLIST ITERATOR o CONCATENATION sobre IX_DENUE_CODIGO_ACT
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS  -- TAG_Q5_DENUE
WHERE  codigo_act LIKE '31%'
   OR  codigo_act LIKE '32%'
   OR  codigo_act LIKE '33%'
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;

COLUMN v_sql_id NEW_VALUE v_sql_id NOPRINT
SELECT sql_id AS v_sql_id
FROM   v$sql
WHERE  sql_text LIKE '%TAG_Q5_DENUE%'
  AND  sql_text LIKE '%gather_plan_statistics%'
ORDER  BY last_active_time DESC
FETCH  FIRST 1 ROW ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id', 0, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q6: Tiendas OXXO — FULL SCAN documentado ===
-- LIMITACIÓN: Oracle Text no disponible; TABLE ACCESS FULL esperado.
-- El índice IX_DENUE_NOM_ESTAB_FN (UPPER) no cubre wildcard inicial.
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       id,
       nom_estab,
       entidad,
       municipio,
       cod_postal,
       latitud,
       longitud
FROM   DENUE_ESTABLECIMIENTOS  -- TAG_Q6_DENUE
WHERE  UPPER(nom_estab) LIKE '%OXXO%'
ORDER  BY entidad, municipio;

COLUMN v_sql_id NEW_VALUE v_sql_id NOPRINT
SELECT sql_id AS v_sql_id
FROM   v$sql
WHERE  sql_text LIKE '%TAG_Q6_DENUE%'
  AND  sql_text LIKE '%gather_plan_statistics%'
ORDER  BY last_active_time DESC
FETCH  FIRST 1 ROW ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&v_sql_id', 0, 'ALLSTATS LAST'));

SET FEEDBACK    ON
SET SERVEROUTPUT ON SIZE UNLIMITED
PROMPT
PROMPT === Todos los planes optimizados capturados ===
PROMPT Comparar columna Operation: INDEX RANGE SCAN / BITMAP INDEX
PROMPT vs TABLE ACCESS FULL de la Fase 2.
PROMPT Comparar A-Rows vs E-Rows para detectar estimaciones erróneas del CBO.
PROMPT Q6 mostrará TABLE ACCESS FULL — limitación documentada (Oracle Text no disponible).
