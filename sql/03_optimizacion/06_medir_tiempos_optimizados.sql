-- =============================================================================
-- 06_medir_tiempos_optimizados.sql
-- Mide el tiempo real y estadísticas de I/O de las 6 consultas optimizadas.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- AUTOTRACE TRACEONLY STATISTICS:
-- A diferencia de AUTOTRACE ON (que imprime todas las filas de resultado),
-- TRACEONLY suprime la salida de datos y solo muestra las estadísticas de
-- ejecución (consistent gets, physical reads, redo size, sorts, etc.).
-- Esto evita que Q2 (212,251 filas) o Q6 (24,321 filas) saturen el terminal
-- y permite capturar solo las métricas relevantes para comparar con Fase 2.
--
-- USO CON SPOOL:
-- Ejecutar desde SQLcl con SPOOL para capturar la evidencia del hito:
--   SPOOL C:\sca\plsql-optimizacion-denue\benchmarks\optimizacion_tiempos.log
--   @sql/03_optimizacion/06_medir_tiempos_optimizados.sql
--   SPOOL OFF
--
-- PREREQUISITO: rol PLUSTRACE otorgado a DENUE_LAB.
-- Si falta: conectar como SYS y ejecutar GRANT PLUSTRACE TO DENUE_LAB;
-- =============================================================================

SET PAGESIZE     0
SET LINESIZE   160
SET TIMING       ON
SET AUTOTRACE    TRACEONLY STATISTICS

-- =============================================================================
-- Q1 — Conteo por entidad federativa
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
-- Q3 — Top 20 municipios con más restaurantes (SCIAN 72)
-- =============================================================================
PROMPT
PROMPT === Q3 (optimizada): Top 20 municipios — servicios de alimentos ===

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
-- Q5 — Distribución por personal — sector manufacturero (SCIAN 31-33)
-- =============================================================================
PROMPT
PROMPT === Q5 (optimizada): Distribución manufactura — sector industrial ===

SELECT per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '31%'
   OR  codigo_act LIKE '32%'
   OR  codigo_act LIKE '33%'
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;

-- =============================================================================
-- Q6 — Tiendas OXXO — Oracle Text CONTAINS
-- =============================================================================
PROMPT
PROMPT === Q6 (optimizada): Tiendas OXXO — Oracle Text ===

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

SET AUTOTRACE OFF
SET TIMING    OFF

PROMPT
PROMPT === Medición completada ===
PROMPT Comparar los "consistent gets" de cada consulta contra los 412,745
PROMPT uniformes de la Fase 2 para cuantificar la mejora de cada índice.
