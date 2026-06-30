-- =============================================================================
-- 03_grants_autotrace.sql
-- Otorga a DENUE_LAB acceso a las vistas dinámicas V$ necesarias para
-- AUTOTRACE y DBMS_XPLAN con estadísticas reales de ejecución.
-- Ejecutar conectado como SYS en FREEPDB1.
--
-- POR QUÉ ES NECESARIO:
-- Las vistas V$ (V$SQL, V$SESSION, V$MYSTAT, etc.) son vistas del diccionario
-- dinámico de Oracle que exponen métricas internas del motor: consistent gets,
-- physical reads, latch activity, etc. Por defecto, un usuario de aplicación
-- como DENUE_LAB no tiene SELECT sobre ellas. Sin estos grants:
--   - SET AUTOTRACE ON falla con ORA-01031 (insufficient privileges)
--   - DBMS_XPLAN.DISPLAY_CURSOR no puede leer estadísticas de ejecución real
--   - La captura de métricas de rendimiento (Fase 2 y Fase 3) queda incompleta
--
-- Nota: en Oracle los GRANT sobre vistas V$ se otorgan usando el prefijo V_$
-- (con guión bajo), no V$ directamente. Oracle resuelve el alias internamente.
-- =============================================================================

-- Acceso al texto y metadatos de sentencias SQL en la shared pool
GRANT SELECT ON V_$SQL                        TO DENUE_LAB;

-- Estadísticas detalladas de ejecución por fila del plan (rows, buffers, time)
GRANT SELECT ON V_$SQL_PLAN_STATISTICS_ALL    TO DENUE_LAB;

-- Estadísticas acumuladas de la sesión actual (consistent gets, physical reads)
GRANT SELECT ON V_$MYSTAT                     TO DENUE_LAB;

-- Catálogo de nombres de estadísticas (necesario para interpretar V$MYSTAT)
GRANT SELECT ON V_$STATNAME                   TO DENUE_LAB;

-- Información de la sesión activa (SID, serial#, módulo, etc.)
GRANT SELECT ON V_$SESSION                    TO DENUE_LAB;

-- Pasos del plan de ejecución almacenados tras una ejecución real
GRANT SELECT ON V_$SQL_PLAN                   TO DENUE_LAB;

-- Verificación: confirmar que los grants quedaron registrados
SELECT grantee,
       owner,
       table_name,
       privilege
FROM   dba_tab_privs
WHERE  grantee    = 'DENUE_LAB'
  AND  table_name IN ('V_$SQL',
                      'V_$SQL_PLAN_STATISTICS_ALL',
                      'V_$MYSTAT',
                      'V_$STATNAME',
                      'V_$SESSION',
                      'V_$SQL_PLAN')
ORDER  BY table_name;
