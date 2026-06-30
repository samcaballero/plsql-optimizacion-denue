-- =============================================================================
-- 04_consultas_optimizadas.sql
-- Las mismas 6 consultas de Fase 2, ahora con índices disponibles.
-- El CBO elige automáticamente el acceso óptimo — no se usan hints todavía.
-- Q1-Q5: misma lógica de negocio que baseline, deben devolver idénticos resultados.
-- Q6: reescrita de LIKE '%OXXO%' a CONTAINS() para aprovechar Oracle Text.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- PREREQUISITOS:
--   1. sql/03_optimizacion/01_indices_btree.sql ejecutado
--   2. sql/03_optimizacion/02_indice_bitmap.sql ejecutado
--   3. sql/03_optimizacion/03_indice_oracle_text.sql ejecutado
--   4. sql/02_baseline/00_estadisticas.sql ejecutado post-índices
-- =============================================================================

SET PAGESIZE   50
SET LINESIZE  160
SET FEEDBACK   ON
SET TIMING     ON

-- =============================================================================
-- Q1 — Conteo de establecimientos por entidad federativa
--      Sin filtro selectivo; el CBO puede elegir entre FULL SCAN (con parallel)
--      o INDEX FAST FULL SCAN sobre IX_DENUE_ENT_ACT (cubre CVE_ENT + CODIGO_ACT).
-- =============================================================================
PROMPT
PROMPT === Q1 (optimizada): Establecimientos por entidad federativa ===

SELECT entidad,
       cve_ent,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
GROUP  BY entidad, cve_ent
ORDER  BY num_establecimientos DESC;

-- =============================================================================
-- Q2 — Comercio al por menor (SCIAN 46) en CDMX
--      Índice IX_DENUE_ENT_ACT (CVE_ENT, CODIGO_ACT): igualdad en CVE_ENT=9
--      seguida de range scan en CODIGO_ACT LIKE '46%'.
--      Se espera: INDEX RANGE SCAN → TABLE ACCESS BY ROWID
-- =============================================================================
PROMPT
PROMPT === Q2 (optimizada): Comercio al por menor (SCIAN 46) en CDMX ===

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

-- =============================================================================
-- Q3 — Top 20 municipios con más establecimientos de alimentos (SCIAN 72)
--      Índice IX_DENUE_CODIGO_ACT: range scan en CODIGO_ACT LIKE '72%'.
-- =============================================================================
PROMPT
PROMPT === Q3 (optimizada): Top 20 municipios — servicios de alimentos (SCIAN 72) ===

SELECT entidad,
       municipio,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '72%'
GROUP  BY entidad, municipio
ORDER  BY num_establecimientos DESC
FETCH  FIRST 20 ROWS ONLY;

-- =============================================================================
-- Q4 — Establecimientos grandes (251 y más personas)
--      Índice IX_DENUE_PER_OCU_BMP: bitmap lookup directo por valor de PER_OCU.
--      Se espera: BITMAP INDEX SINGLE VALUE → TABLE ACCESS BY ROWID
-- =============================================================================
PROMPT
PROMPT === Q4 (optimizada): Establecimientos grandes — 251 y más personas ===

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

-- =============================================================================
-- Q5 — Distribución por personal — sector manufacturero (SCIAN 31, 32, 33)
--      Índice IX_DENUE_CODIGO_ACT: 3 range scans unidos con OR (INLIST ITERATOR
--      o CONCATENATION en el plan).
-- =============================================================================
PROMPT
PROMPT === Q5 (optimizada): Distribución por personal — sector manufacturero ===

SELECT per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '31%'
   OR  codigo_act LIKE '32%'
   OR  codigo_act LIKE '33%'
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;

-- =============================================================================
-- Q6 — Tiendas OXXO
--      LIMITACIÓN DOCUMENTADA: esta consulta seguirá haciendo TABLE ACCESS FULL.
--      Oracle Text (CTXSYS) no está disponible en esta imagen Docker — ver
--      sql/03_optimizacion/03_indice_oracle_text.sql y benchmarks/README.md.
--      LIKE '%OXXO%' con wildcard en ambos extremos no es indexable con B-tree
--      ni con índices de función. Se mantiene en la suite para que el informe
--      final refleje honestamente que no toda consulta es optimizable con los
--      recursos de infraestructura disponibles.
--      Se usa UPPER() para aprovechar el índice de función IX_DENUE_NOM_ESTAB_FN
--      en el caso de que la búsqueda cambie a prefijo o exacta en el futuro.
-- =============================================================================
PROMPT
PROMPT === Q6 (limitación documentada): Tiendas OXXO — FULL SCAN inevitable ===

SELECT id,
       nom_estab,
       entidad,
       municipio,
       cod_postal,
       latitud,
       longitud
FROM   DENUE_ESTABLECIMIENTOS
WHERE  UPPER(nom_estab) LIKE '%OXXO%'
ORDER  BY entidad, municipio;
