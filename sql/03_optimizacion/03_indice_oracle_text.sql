-- =============================================================================
-- 03_indice_oracle_text.sql
-- Intento de índice Oracle Text sobre NOM_ESTAB + alternativa nativa.
-- Conectar como DENUE_LAB en FREEPDB1.
-- =============================================================================

-- =============================================================================
-- EVIDENCIA DE INTENTO — ORA-29833
-- =============================================================================
-- Se intentó ejecutar:
--
--   CREATE INDEX IX_DENUE_NOM_ESTAB_TXT ON DENUE_ESTABLECIMIENTOS(NOM_ESTAB)
--   INDEXTYPE IS CTXSYS.CONTEXT;
--
-- Resultado: ORA-29833: indextype does not exist
--
-- Confirmado que CTXSYS no existe en esta instancia:
--   SELECT username FROM dba_users WHERE username = 'CTXSYS';   -- no rows
--   SELECT * FROM dba_registry WHERE comp_name LIKE '%Text%';   -- no rows
--
-- Causa: las imágenes Oracle Database Free para Docker no incluyen componentes
-- opcionales como Oracle Text (CTXSYS), Oracle Spatial (MDSYS) ni Oracle
-- Multimedia. Son instalaciones mínimas pensadas para desarrollo y aprendizaje,
-- no para validar todas las capacidades Enterprise.
-- =============================================================================

-- =============================================================================
-- LIMITACIÓN FUNDAMENTAL QUE PERSISTE CON CUALQUIER ALTERNATIVA NATIVA
-- =============================================================================
-- El patrón LIKE '%OXXO%' tiene wildcard en ambos extremos. Ningún índice
-- B-tree (ni convencional ni de función) puede resolver esto eficientemente:
--
--   - Un B-tree ordena valores completos de izquierda a derecha.
--     Para LIKE 'OXXO%' Oracle hace range scan porque conoce el prefijo.
--     Para LIKE '%OXXO%' Oracle no sabe por dónde buscar en el árbol —
--     'OXXO' puede estar en cualquier posición del valor.
--
-- La única solución verdaderamente selectiva es un índice INVERTIDO:
-- Oracle Text en Oracle DB, o un motor externo (Elasticsearch, OpenSearch,
-- Solr) en arquitecturas con requisitos de búsqueda textual intensiva.
--
-- La alternativa implementada abajo ofrece una MEJORA MARGINAL (normalización
-- de mayúsculas), no una solución al problema de rendimiento de Q6.
-- Se documenta como ejemplo de juicio técnico honesto ante restricciones de
-- infraestructura disponible.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- =============================================================================
-- ALTERNATIVA NATIVA: índice de función sobre UPPER(NOM_ESTAB)
-- =============================================================================
-- Este índice SÍ ayuda en los siguientes patrones:
--   UPPER(NOM_ESTAB) = 'OXXO'          → INDEX UNIQUE/RANGE SCAN
--   UPPER(NOM_ESTAB) LIKE 'OXXO%'      → INDEX RANGE SCAN
--
-- NO ayuda (sigue siendo FULL SCAN) en:
--   UPPER(NOM_ESTAB) LIKE '%OXXO%'     → TABLE ACCESS FULL
--
-- Se incluye aquí para:
--   1. Garantizar búsquedas exactas o de prefijo insensibles a mayúsculas
--   2. Dejar evidencia de hasta dónde llega la optimización sin Oracle Text
-- =============================================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX DENUE_LAB.IX_DENUE_NOM_ESTAB_FN';
    DBMS_OUTPUT.PUT_LINE('IX_DENUE_NOM_ESTAB_FN eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1418 THEN
            DBMS_OUTPUT.PUT_LINE('IX_DENUE_NOM_ESTAB_FN no existía; continuando.');
        ELSE RAISE;
        END IF;
END;
/

CREATE INDEX IX_DENUE_NOM_ESTAB_FN
    ON DENUE_ESTABLECIMIENTOS (UPPER(NOM_ESTAB))
    NOLOGGING PARALLEL 4;

ALTER INDEX IX_DENUE_NOM_ESTAB_FN NOPARALLEL;

-- Verificación
PROMPT
PROMPT === Índice de función creado ===
SELECT index_name,
       index_type,
       status,
       funcidx_status
FROM   user_indexes
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS'
  AND  index_name = 'IX_DENUE_NOM_ESTAB_FN';

PROMPT
PROMPT === CONCLUSIÓN ===
PROMPT Q6 (búsqueda OXXO con wildcard inicial) seguirá haciendo TABLE ACCESS FULL.
PROMPT El índice de función IX_DENUE_NOM_ESTAB_FN cubre solo búsquedas exactas
PROMPT o de prefijo. Esta limitación queda documentada en benchmarks/README.md.
