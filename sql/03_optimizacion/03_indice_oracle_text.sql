-- =============================================================================
-- 03_indice_oracle_text.sql
-- Crea un índice Oracle Text (CONTEXT) sobre NOM_ESTAB para optimizar Q6.
-- Conectar como DENUE_LAB en FREEPDB1.
--
-- POR QUÉ UN B-TREE NO SIRVE PARA LIKE '%OXXO%':
-- Un índice B-tree ordena valores completos de la columna. Para un LIKE con
-- wildcard solo al final ('OXXO%'), Oracle puede hacer range scan porque el
-- prefijo 'OXXO' define un rango acotado en el árbol. Pero con wildcard
-- inicial ('%OXXO%'), Oracle no sabe en qué parte del árbol buscar — la cadena
-- 'OXXO' puede aparecer en cualquier posición del valor. El resultado es que
-- Oracle ignora el índice B-tree y recurre a TABLE ACCESS FULL igualmente.
--
-- SOLUCIÓN — ÍNDICE CONTEXT DE ORACLE TEXT:
-- Oracle Text construye un índice INVERTIDO: tokeniza cada valor de NOM_ESTAB
-- en palabras y crea el mapa (palabra → lista de ROWIDs). Para buscar 'OXXO'
-- Oracle consulta directamente la entrada 'OXXO' en el índice invertido,
-- obteniendo los ROWIDs en O(log n) sin escanear la tabla. La sintaxis de
-- consulta cambia de LIKE '%OXXO%' a CONTAINS(NOM_ESTAB, 'OXXO') > 0.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX DENUE_LAB.IX_DENUE_NOM_ESTAB_TXT';
    DBMS_OUTPUT.PUT_LINE('IX_DENUE_NOM_ESTAB_TXT eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1418 THEN
            DBMS_OUTPUT.PUT_LINE('IX_DENUE_NOM_ESTAB_TXT no existía; continuando.');
        ELSIF SQLCODE = -20000 THEN
            -- Oracle Text (CTXSYS) no está instalado o habilitado en esta instancia.
            -- Verificar con: SELECT comp_name, status FROM dba_registry WHERE comp_name = 'Oracle Text';
            -- Si status != 'VALID', contactar al DBA para instalar el componente.
            DBMS_OUTPUT.PUT_LINE('ERROR: Oracle Text (CTXSYS) no está disponible en esta instancia.');
            DBMS_OUTPUT.PUT_LINE('Verificar: SELECT comp_name, status FROM dba_registry WHERE comp_name = ''Oracle Text'';');
        ELSE RAISE;
        END IF;
END;
/

CREATE INDEX IX_DENUE_NOM_ESTAB_TXT
    ON DENUE_ESTABLECIMIENTOS(NOM_ESTAB)
    INDEXTYPE IS CTXSYS.CONTEXT
    PARAMETERS ('SYNC (MANUAL)');

-- SINCRONIZACIÓN MANUAL TRAS CARGA MASIVA:
-- Los índices CONTEXT con SYNC (MANUAL) no se actualizan automáticamente con
-- cada INSERT/UPDATE. Esto es intencional para cargas masivas: sincronizar fila
-- a fila sería prohibitivamente lento sobre 6M registros. Tras la carga inicial
-- (o cualquier carga masiva posterior) hay que sincronizar explícitamente:
BEGIN
    CTX_DDL.SYNC_INDEX('IX_DENUE_NOM_ESTAB_TXT');
    DBMS_OUTPUT.PUT_LINE('Índice Oracle Text sincronizado correctamente.');
END;
/

-- Verificación: estado del índice Oracle Text
PROMPT
PROMPT === Índice Oracle Text creado ===
SELECT idx_name,
       idx_table,
       idx_text_name,
       idx_status
FROM   ctx_user_indexes
WHERE  idx_name = 'IX_DENUE_NOM_ESTAB_TXT';

-- Confirmar que el índice aparece también en USER_INDEXES como DOMAIN
SELECT index_name,
       index_type,
       status
FROM   user_indexes
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS'
  AND  index_name = 'IX_DENUE_NOM_ESTAB_TXT';
