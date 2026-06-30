-- =============================================================================
-- 00_estadisticas.sql
-- Recolecta estadísticas del optimizador (CBO) tras la carga masiva.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- POR QUÉ ES OBLIGATORIO TRAS UNA CARGA DIRECT-PATH:
-- SQL*Loader con DIRECT=TRUE inserta datos saltándose el buffer cache y los
-- triggers del segmento. Como consecuencia, el diccionario de estadísticas
-- (USER_TABLES.NUM_ROWS, histogramas de columnas, etc.) queda desactualizado
-- o a cero. El Cost-Based Optimizer (CBO) genera entonces planes no
-- representativos — típicamente prefiere FULL TABLE SCAN aunque existan
-- índices, o al revés. Ejecutar GATHER_TABLE_STATS sincroniza las estadísticas
-- con el estado real de la tabla y permite comparaciones fiables en la Fase 3.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

PROMPT
PROMPT === Recolectando estadísticas de DENUE_ESTABLECIMIENTOS ===
PROMPT (puede tardar 1-3 minutos sobre 6.1 M filas)
PROMPT

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname          => 'DENUE_LAB',
        tabname          => 'DENUE_ESTABLECIMIENTOS',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,  -- Oracle decide el muestreo óptimo
        cascade          => TRUE,                          -- incluye índices (PK y futuros)
        method_opt       => 'FOR ALL COLUMNS SIZE AUTO'   -- histogramas automáticos por columna
    );
    DBMS_OUTPUT.PUT_LINE('Estadísticas recolectadas correctamente.');
END;
/

-- Confirmar: metadatos generales de la tabla
PROMPT
PROMPT === Estado de la tabla tras GATHER_TABLE_STATS ===
SELECT table_name,
       num_rows,
       blocks,
       TO_CHAR(last_analyzed, 'YYYY-MM-DD HH24:MI:SS') AS last_analyzed
FROM   user_tables
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS';

-- Confirmar: cardinalidad de columnas clave para el optimizador
PROMPT
PROMPT === Cardinalidad de columnas clave (num_distinct) ===
SELECT column_name,
       num_distinct,
       num_nulls,
       TO_CHAR(last_analyzed, 'YYYY-MM-DD HH24:MI:SS') AS last_analyzed
FROM   user_tab_columns
WHERE  table_name  = 'DENUE_ESTABLECIMIENTOS'
  AND  column_name IN ('CVE_ENT', 'CODIGO_ACT', 'PER_OCU', 'MUNICIPIO', 'ENTIDAD', 'FECHA_ALTA')
ORDER  BY column_name;
