-- =============================================================================
-- 02_indice_bitmap.sql
-- Crea un índice bitmap sobre PER_OCU para optimizar Q4 y Q5.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- CUÁNDO USAR BITMAP vs B-TREE:
-- Un índice bitmap es óptimo cuando la columna tiene BAJA CARDINALIDAD
-- (pocos valores distintos) y la tabla se usa principalmente en consultas
-- analíticas o de solo lectura. PER_OCU tiene exactamente 7 valores distintos
-- ("0 a 5 personas", "6 a 10 personas", ..., "251 y más personas"), lo que
-- genera bitmaps compactos que Oracle puede combinar eficientemente con AND/OR
-- a nivel de bits, sin acceder a los bloques de datos hasta el final.
--
-- ADVERTENCIA — NO USAR BITMAP EN TABLAS CON ESCRITURAS CONCURRENTES:
-- Los índices bitmap usan locking a nivel de entrada del bitmap, no a nivel
-- de fila. Un UPDATE o INSERT sobre PER_OCU bloquea todas las filas que
-- comparten ese valor en el bitmap (potencialmente millones). Esto causa
-- deadlocks y contención severa en tablas OLTP con escrituras frecuentes.
-- En este laboratorio la tabla DENUE es de carga única (solo lectura
-- analítica), por lo que el bitmap es apropiado.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX DENUE_LAB.IX_DENUE_PER_OCU_BMP';
    DBMS_OUTPUT.PUT_LINE('IX_DENUE_PER_OCU_BMP eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1418 THEN
            DBMS_OUTPUT.PUT_LINE('IX_DENUE_PER_OCU_BMP no existía; continuando.');
        ELSE RAISE;
        END IF;
END;
/

CREATE BITMAP INDEX IX_DENUE_PER_OCU_BMP
    ON DENUE_ESTABLECIMIENTOS(PER_OCU)
    NOLOGGING PARALLEL 4;

ALTER INDEX IX_DENUE_PER_OCU_BMP NOPARALLEL;

-- Verificación: confirmar INDEX_TYPE = 'BITMAP'
PROMPT
PROMPT === Índice bitmap creado ===
SELECT index_name,
       index_type,
       status,
       num_rows,
       last_analyzed
FROM   user_indexes
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS'
  AND  index_name = 'IX_DENUE_PER_OCU_BMP';

-- Confirmar los 7 valores distintos que maneja el bitmap
PROMPT
PROMPT === Valores distintos de PER_OCU (cardinalidad del bitmap) ===
SELECT per_ocu,
       COUNT(*) AS num_establecimientos
FROM   DENUE_ESTABLECIMIENTOS
GROUP  BY per_ocu
ORDER  BY num_establecimientos DESC;
