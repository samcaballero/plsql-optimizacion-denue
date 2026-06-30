-- =============================================================================
-- 01_indices_btree.sql
-- Crea los índices B-tree para optimizar las consultas Q2, Q3 y Q5.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- RECORDATORIO OBLIGATORIO TRAS CREAR LOS ÍNDICES:
-- Volver a ejecutar sql/02_baseline/00_estadisticas.sql para que el CBO
-- (Cost-Based Optimizer) conozca los nuevos índices y sus estadísticas.
-- Sin ese paso, el optimizador puede seguir eligiendo TABLE ACCESS FULL
-- aunque los índices existan — las estadísticas de índice no se generan
-- automáticamente durante CREATE INDEX en todas las versiones de Oracle.
-- =============================================================================

-- =============================================================================
-- ÍNDICE 1: Compuesto (CVE_ENT, CODIGO_ACT)
-- Optimiza Q2: WHERE codigo_act LIKE '46%' AND cve_ent = 9
--
-- ORDEN DE COLUMNAS — por qué CVE_ENT va primero:
-- En un índice compuesto B-tree, Oracle puede hacer range scan solo si los
-- predicados de igualdad van antes que los de rango en el orden del índice.
-- CVE_ENT usa igualdad (= 9): permite "saltar" directo al nodo correcto
-- del árbol. CODIGO_ACT usa rango (LIKE '46%'): se aplica dentro del
-- subárbol ya acotado por CVE_ENT. Invirtiendo el orden, el índice solo
-- podría usarse para el prefijo CODIGO_ACT y el filtro CVE_ENT requeriría
-- un filter adicional sobre el INDEX RANGE SCAN, perdiendo eficiencia.
-- =============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX DENUE_LAB.IX_DENUE_ENT_ACT';
    DBMS_OUTPUT.PUT_LINE('IX_DENUE_ENT_ACT eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1418 THEN
            DBMS_OUTPUT.PUT_LINE('IX_DENUE_ENT_ACT no existía; continuando.');
        ELSE RAISE;
        END IF;
END;
/

CREATE INDEX IX_DENUE_ENT_ACT
    ON DENUE_ESTABLECIMIENTOS(CVE_ENT, CODIGO_ACT)
    NOLOGGING PARALLEL 4;

ALTER INDEX IX_DENUE_ENT_ACT NOPARALLEL;  -- restaurar paralelismo por defecto post-creación

-- =============================================================================
-- ÍNDICE 2: Simple (CODIGO_ACT)
-- Optimiza Q3 (LIKE '72%') y Q5 (OR LIKE '31%' / '32%' / '33%')
--
-- Un LIKE con wildcard solo al FINAL ('46%') admite INDEX RANGE SCAN porque
-- Oracle conoce el prefijo fijo ('46') y puede hacer un range [46, 47).
-- Un LIKE con wildcard al INICIO ('%OXXO%') NO puede usar B-tree — para ese
-- caso se usa Oracle Text (ver 03_indice_oracle_text.sql).
-- =============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX DENUE_LAB.IX_DENUE_CODIGO_ACT';
    DBMS_OUTPUT.PUT_LINE('IX_DENUE_CODIGO_ACT eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1418 THEN
            DBMS_OUTPUT.PUT_LINE('IX_DENUE_CODIGO_ACT no existía; continuando.');
        ELSE RAISE;
        END IF;
END;
/

CREATE INDEX IX_DENUE_CODIGO_ACT
    ON DENUE_ESTABLECIMIENTOS(CODIGO_ACT)
    NOLOGGING PARALLEL 4;

ALTER INDEX IX_DENUE_CODIGO_ACT NOPARALLEL;

-- Verificación
PROMPT
PROMPT === Índices B-tree creados ===
SELECT index_name,
       index_type,
       uniqueness,
       status,
       num_rows,
       last_analyzed
FROM   user_indexes
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS'
ORDER  BY index_name;

PROMPT
PROMPT === Columnas de los índices compuestos ===
SELECT index_name,
       column_position,
       column_name,
       descend
FROM   user_ind_columns
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS'
ORDER  BY index_name, column_position;

PROMPT
PROMPT RECORDATORIO: ejecutar sql/02_baseline/00_estadisticas.sql antes de
PROMPT               correr sql/03_optimizacion/04_consultas_optimizadas.sql
