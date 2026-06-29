-- =============================================================================
-- 01_crear_usuario.sql
-- Crea el usuario DENUE_LAB en Oracle 23ai Free (PDB: FREEPDB1).
-- Prerequisito: ejecutar conectado como SYS / SYSDBA en FREEPDB1.
-- =============================================================================

-- 1. Eliminar el usuario si ya existe
BEGIN
    EXECUTE IMMEDIATE 'DROP USER DENUE_LAB CASCADE';
    DBMS_OUTPUT.PUT_LINE('Usuario DENUE_LAB eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1918 THEN
            DBMS_OUTPUT.PUT_LINE('Usuario DENUE_LAB no existía; continuando.');
        ELSE
            RAISE;
        END IF;
END;
/

-- 2. Crear el usuario
CREATE USER DENUE_LAB IDENTIFIED BY "DenueL4b2025#";

-- 3. Privilegios mínimos para el laboratorio
GRANT CREATE SESSION          TO DENUE_LAB;
GRANT CREATE TABLE            TO DENUE_LAB;
GRANT CREATE VIEW             TO DENUE_LAB;
GRANT CREATE MATERIALIZED VIEW TO DENUE_LAB;
GRANT CREATE PROCEDURE        TO DENUE_LAB;
GRANT CREATE SEQUENCE         TO DENUE_LAB;
GRANT UNLIMITED TABLESPACE    TO DENUE_LAB;

-- Verificación rápida
SELECT username, account_status, default_tablespace
FROM   dba_users
WHERE  username = 'DENUE_LAB';

-- =============================================================================
-- INSTRUCCIONES DE EJECUCIÓN
-- =============================================================================
--
-- Desde una terminal, conectarse a FREEPDB1 como SYS con SQLcl:
--
--   sql sys/SYS_PASSWORD@//localhost:1521/FREEPDB1 as sysdba
--
-- (Reemplazar SYS_PASSWORD con la contraseña del contenedor Docker.)
--
-- Una vez conectado, ejecutar este script:
--
--   @/ruta/al/repo/sql/00_setup/01_crear_usuario.sql
--
-- O si SQLcl ya está en el directorio raíz del repo:
--
--   @sql/00_setup/01_crear_usuario.sql
--
-- Para verificar desde Docker antes de conectar:
--
--   docker exec -it <nombre_contenedor> sqlplus sys/SYS_PASSWORD@FREEPDB1 as sysdba
-- =============================================================================
