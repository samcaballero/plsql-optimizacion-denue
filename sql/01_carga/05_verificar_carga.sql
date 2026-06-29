-- =============================================================================
-- 05_verificar_carga.sql
-- Verificación post-carga de DENUE_ESTABLECIMIENTOS.
-- Conectar como DENUE_LAB en FREEPDB1.
-- =============================================================================

SET PAGESIZE 100
SET LINESIZE 160
SET FEEDBACK ON

-- 1. Total de filas cargadas
PROMPT
PROMPT === 1. TOTAL DE FILAS ===
SELECT COUNT(*) AS total_filas
FROM   DENUE_ESTABLECIMIENTOS;

-- 2. Distribución por entidad federativa (top 10)
PROMPT
PROMPT === 2. TOP 10 ENTIDADES FEDERATIVAS ===
SELECT entidad,
       cve_ent,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
GROUP  BY entidad, cve_ent
ORDER  BY num_establecimientos DESC
FETCH  FIRST 10 ROWS ONLY;

-- 3. Distribución por sector SCIAN (primeros 2 dígitos), top 10
PROMPT
PROMPT === 3. TOP 10 SECTORES SCIAN (primeros 2 dígitos de CODIGO_ACT) ===
SELECT SUBSTR(codigo_act, 1, 2)  AS sector_scian,
       COUNT(*)                  AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  codigo_act IS NOT NULL
GROUP  BY SUBSTR(codigo_act, 1, 2)
ORDER  BY num_establecimientos DESC
FETCH  FIRST 10 ROWS ONLY;

-- 4. Calidad del dato geográfico: registros sin coordenadas
PROMPT
PROMPT === 4. REGISTROS SIN COORDENADAS GEOGRÁFICAS ===
SELECT COUNT(*) AS sin_latitud_o_longitud
FROM   DENUE_ESTABLECIMIENTOS
WHERE  latitud IS NULL
   OR  longitud IS NULL;

SELECT COUNT(*) AS con_coordenadas_completas
FROM   DENUE_ESTABLECIMIENTOS
WHERE  latitud  IS NOT NULL
  AND  longitud IS NOT NULL;

-- 5. Rango de fechas de incorporación al DENUE
PROMPT
PROMPT === 5. RANGO DE FECHA_ALTA ===
SELECT MIN(fecha_alta) AS primera_alta,
       MAX(fecha_alta) AS ultima_alta,
       COUNT(DISTINCT TRUNC(fecha_alta,'MM')) AS meses_distintos
FROM   DENUE_ESTABLECIMIENTOS
WHERE  fecha_alta IS NOT NULL;

-- 6. Muestra de 3 filas representativas
PROMPT
PROMPT === 6. MUESTRA (3 FILAS) ===
SELECT id,
       clee,
       nom_estab,
       codigo_act,
       per_ocu,
       entidad,
       municipio,
       latitud,
       longitud,
       fecha_alta
FROM   DENUE_ESTABLECIMIENTOS
FETCH FIRST 3 ROWS ONLY;

PROMPT
PROMPT === VERIFICACIÓN COMPLETA ===
