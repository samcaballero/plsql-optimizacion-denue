-- =============================================================================
-- 01_consultas_baseline.sql
-- Seis consultas representativas del DENUE ejecutadas SIN optimización.
-- Solo existe la PK sobre ID — el CBO recurrirá a FULL TABLE SCAN.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- Estos resultados son la referencia funcional para validar que las consultas
-- optimizadas en la Fase 3 devuelven exactamente los mismos datos.
-- =============================================================================

SET PAGESIZE   50
SET LINESIZE  160
SET FEEDBACK   ON
SET TIMING     ON

-- =============================================================================
-- Q1 — ¿Cuántos establecimientos hay por entidad federativa?
--      Útil para análisis de densidad económica por estado.
-- =============================================================================
PROMPT
PROMPT === Q1: Establecimientos por entidad federativa ===

SELECT entidad,
       cve_ent,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
GROUP  BY entidad, cve_ent
ORDER  BY num_establecimientos DESC;

-- =============================================================================
-- Q2 — ¿Cuáles son los establecimientos de comercio al por menor (SCIAN 46)
--      en la Ciudad de México (CVE_ENT = 9)?
--      Filtro compuesto: sector + estado — patrón frecuente en análisis
--      sectoriales por entidad.
-- =============================================================================
PROMPT
PROMPT === Q2: Comercio al por menor (SCIAN 46) en CDMX ===

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
-- Q3 — ¿Cuáles son los 20 municipios con más restaurantes y servicios de
--      alimentos (SCIAN 72)?
--      Agregación con doble GROUP BY para identificar zonas gastronómicas.
-- =============================================================================
PROMPT
PROMPT === Q3: Top 20 municipios con más establecimientos SCIAN 72 (alimentos) ===

SELECT entidad,
       municipio,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '72%'
GROUP  BY entidad, municipio
ORDER  BY num_establecimientos DESC
FETCH  FIRST 20 ROWS ONLY;

-- =============================================================================
-- Q4 — ¿Qué empresas grandes (251 y más personas) operan en México?
--      Identificación de grandes empleadores a nivel nacional.
-- =============================================================================
PROMPT
PROMPT === Q4: Establecimientos grandes — 251 y más personas ocupadas ===

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
-- Q5 — ¿Cómo se distribuyen los establecimientos manufactureros (SCIAN 31, 32, 33)
--      por tamaño de planta (PER_OCU)?
--      Estructura de tamaños en el sector industrial nacional.
-- =============================================================================
PROMPT
PROMPT === Q5: Distribución por personal ocupado — sector manufacturero (SCIAN 31-33) ===

SELECT per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act LIKE '31%'
   OR  codigo_act LIKE '32%'
   OR  codigo_act LIKE '33%'
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;

-- =============================================================================
-- Q6 — ¿Dónde están todas las tiendas OXXO registradas en el DENUE?
--      Búsqueda por nombre comercial con LIKE — patrón típico de análisis
--      de cadenas de conveniencia y cobertura geográfica.
-- =============================================================================
PROMPT
PROMPT === Q6: Tiendas OXXO en el DENUE ===

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
