-- =============================================================================
-- 03_medir_tiempos.sql
-- Mide el tiempo real de ejecución de las 6 consultas baseline.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- Estos tiempos son la LÍNEA BASE a superar en la Fase 3 con índices y
-- técnicas de optimización. Anotar los valores en benchmarks/README.md.
--
-- SET AUTOTRACE ON muestra estadísticas de consistent gets y physical reads,
-- permitiendo comparar I/O lógico y físico antes/después de optimizar.
-- REQUISITO: el rol PLUSTRACE debe estar otorgado a DENUE_LAB.
--   Si falla con ORA-01031, ejecutar como SYS:
--     GRANT PLUSTRACE TO DENUE_LAB;
--   Alternativa sin PLUSTRACE: usar los bloques DBMS_UTILITY.GET_TIME
--   al final de este script.
-- =============================================================================

SET PAGESIZE     50
SET LINESIZE    160
SET TIMING       ON
SET AUTOTRACE    ON

-- =============================================================================
-- Q1 — Establecimientos por entidad federativa
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
-- Q2 — Comercio al por menor (SCIAN 46) en CDMX
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
-- Q3 — Top 20 municipios con más restaurantes (SCIAN 72)
-- =============================================================================
PROMPT
PROMPT === Q3: Top 20 municipios — servicios de alimentos (SCIAN 72) ===

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
-- Q5 — Distribución por personal — sector manufacturero (SCIAN 31-33)
-- =============================================================================
PROMPT
PROMPT === Q5: Distribución por personal — sector manufacturero ===

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
-- =============================================================================
PROMPT
PROMPT === Q6: Tiendas OXXO ===

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

SET AUTOTRACE OFF
SET TIMING    OFF

-- =============================================================================
-- ALTERNATIVA SIN PLUSTRACE — bloques PL/SQL con DBMS_UTILITY.GET_TIME
-- Descomentar si SET AUTOTRACE falla con ORA-01031
-- =============================================================================
/*
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_start NUMBER;
    v_dummy NUMBER;
BEGIN
    -- Q1
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_dummy FROM (
        SELECT entidad, cve_ent, COUNT(*)
        FROM   DENUE_ESTABLECIMIENTOS
        GROUP  BY entidad, cve_ent
    );
    DBMS_OUTPUT.PUT_LINE('Q1 tiempo: ' || ROUND((DBMS_UTILITY.GET_TIME - v_start)/100, 2) || ' seg');

    -- Q2
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_dummy FROM DENUE_ESTABLECIMIENTOS
    WHERE  codigo_act LIKE '46%' AND cve_ent = 9;
    DBMS_OUTPUT.PUT_LINE('Q2 tiempo: ' || ROUND((DBMS_UTILITY.GET_TIME - v_start)/100, 2) || ' seg');

    -- Q3
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_dummy FROM (
        SELECT entidad, municipio, COUNT(*)
        FROM   DENUE_ESTABLECIMIENTOS
        WHERE  codigo_act LIKE '72%'
        GROUP  BY entidad, municipio
    );
    DBMS_OUTPUT.PUT_LINE('Q3 tiempo: ' || ROUND((DBMS_UTILITY.GET_TIME - v_start)/100, 2) || ' seg');

    -- Q4
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_dummy FROM DENUE_ESTABLECIMIENTOS
    WHERE  per_ocu LIKE '%251 y más personas%';
    DBMS_OUTPUT.PUT_LINE('Q4 tiempo: ' || ROUND((DBMS_UTILITY.GET_TIME - v_start)/100, 2) || ' seg');

    -- Q5
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_dummy FROM (
        SELECT per_ocu, COUNT(*)
        FROM   DENUE_ESTABLECIMIENTOS
        WHERE  codigo_act LIKE '31%' OR codigo_act LIKE '32%' OR codigo_act LIKE '33%'
        GROUP  BY per_ocu
    );
    DBMS_OUTPUT.PUT_LINE('Q5 tiempo: ' || ROUND((DBMS_UTILITY.GET_TIME - v_start)/100, 2) || ' seg');

    -- Q6
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_dummy FROM DENUE_ESTABLECIMIENTOS
    WHERE  nom_estab LIKE '%OXXO%';
    DBMS_OUTPUT.PUT_LINE('Q6 tiempo: ' || ROUND((DBMS_UTILITY.GET_TIME - v_start)/100, 2) || ' seg');
END;
/
*/
