-- =============================================================================
-- 05_capturar_planes_optimizados.sql
-- Captura planes de ejecución reales (no estimados) de las 6 consultas
-- optimizadas usando el hint gather_plan_statistics + DISPLAY_CURSOR.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- DIFERENCIA CON EXPLAIN PLAN (Fase 2):
-- EXPLAIN PLAN genera un plan estimado sin ejecutar la consulta — muestra
-- E-Rows (filas estimadas) pero no A-Rows (filas reales). Con el hint
-- gather_plan_statistics + DBMS_XPLAN.DISPLAY_CURSOR se obtiene el plan
-- de la última ejecución real, mostrando A-Rows vs E-Rows lado a lado.
-- Eso permite detectar estimaciones erróneas del CBO y confirmar qué
-- operaciones de acceso se usaron realmente (INDEX RANGE SCAN, DOMAIN INDEX,
-- BITMAP INDEX, etc.) en vez de TABLE ACCESS FULL.
-- =============================================================================

SET PAGESIZE  200
SET LINESIZE  200
SET FEEDBACK   OFF

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q1: Establecimientos por entidad federativa ===
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       entidad,
       cve_ent,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
GROUP  BY entidad, cve_ent
ORDER  BY num_establecimientos DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

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
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '46%'
  AND  cve_ent = 9
ORDER  BY municipio, nom_estab;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q3: Top 20 municipios — alimentos (SCIAN 72) ===
-- Esperado: INDEX RANGE SCAN sobre IX_DENUE_CODIGO_ACT
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       entidad,
       municipio,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '72%'
GROUP  BY entidad, municipio
ORDER  BY num_establecimientos DESC
FETCH  FIRST 20 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

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
FROM   DENUE_ESTABLECIMIENTOS
WHERE  per_ocu LIKE '%251 y más personas%'
ORDER  BY entidad, nom_estab;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q5: Distribución manufactura (SCIAN 31-33) ===
-- Esperado: INLIST ITERATOR o CONCATENATION sobre IX_DENUE_CODIGO_ACT
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '31%'
   OR  codigo_act LIKE '32%'
   OR  codigo_act LIKE '33%'
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- =============================================================================
PROMPT === PLAN OPTIMIZADO Q6: Tiendas OXXO — Oracle Text CONTAINS ===
-- Esperado: DOMAIN INDEX sobre IX_DENUE_NOM_ESTAB_TXT
-- =============================================================================

SELECT /*+ gather_plan_statistics */
       id,
       nom_estab,
       entidad,
       municipio,
       cod_postal,
       latitud,
       longitud
FROM   DENUE_ESTABLECIMIENTOS
WHERE  CONTAINS(nom_estab, 'OXXO') > 0
ORDER  BY entidad, municipio;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

SET FEEDBACK ON
PROMPT
PROMPT === Todos los planes optimizados capturados ===
PROMPT Comparar columna Operation: INDEX RANGE SCAN / BITMAP INDEX / DOMAIN INDEX
PROMPT vs TABLE ACCESS FULL de la Fase 2.
PROMPT Comparar A-Rows vs E-Rows para detectar estimaciones erróneas del CBO.
