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
-- Q6 — Tiendas OXXO — reescrita para Oracle Text
--      LIKE '%OXXO%' → CONTAINS(NOM_ESTAB, 'OXXO') > 0
--      CONTAINS() invoca el índice DOMAIN IX_DENUE_NOM_ESTAB_TXT directamente.
--      Se espera: DOMAIN INDEX (CONTAINS) → TABLE ACCESS BY ROWID
--      NOTA: los resultados deben ser equivalentes a Q6 baseline salvo que
--      Oracle Text tokeniza por palabras — 'OXXO EXPRÉS' y 'OXXO' son
--      resultados válidos; 'LOXXO' (sin espacio) depende de la configuración
--      del lexer (BASIC_LEXER por defecto no tiene stopwords para español).
-- =============================================================================
PROMPT
PROMPT === Q6 (optimizada): Tiendas OXXO — Oracle Text CONTAINS ===

SELECT id,
       nom_estab,
       entidad,
       municipio,
       cod_postal,
       latitud,
       longitud
FROM   DENUE_ESTABLECIMIENTOS
WHERE  CONTAINS(nom_estab, 'OXXO') > 0
ORDER  BY entidad, municipio;
