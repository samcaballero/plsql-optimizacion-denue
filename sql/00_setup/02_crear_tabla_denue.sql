-- =============================================================================
-- 02_crear_tabla_denue.sql
-- Crea la tabla principal DENUE_ESTABLECIMIENTOS en el esquema DENUE_LAB.
--
-- DDL validado contra el header real del CSV DENUE 05/2026 (42 columnas).
-- Orden y nombres de columna coinciden exactamente con los del archivo fuente.
--
-- Prerequisito: conectado como DENUE_LAB (o SYS con permisos) en FREEPDB1.
-- =============================================================================

-- 1. Eliminar la tabla si ya existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DENUE_LAB.DENUE_ESTABLECIMIENTOS CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Tabla DENUE_ESTABLECIMIENTOS eliminada.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -942 THEN
            DBMS_OUTPUT.PUT_LINE('Tabla DENUE_ESTABLECIMIENTOS no existía; continuando.');
        ELSE
            RAISE;
        END IF;
END;
/

-- 2. Crear la tabla (42 columnas, orden del CSV)
CREATE TABLE DENUE_LAB.DENUE_ESTABLECIMIENTOS
(
    ID              NUMBER              NOT NULL,
    CLEE            VARCHAR2(30),                   -- Clave estadística, ej: "25012713120002751000000000U6"
    NOM_ESTAB       VARCHAR2(250),
    RAZ_SOCIAL      VARCHAR2(250),
    CODIGO_ACT      VARCHAR2(10),                   -- Código SCIAN 2018 (6 dígitos)
    NOMBRE_ACT      VARCHAR2(300),
    PER_OCU         VARCHAR2(30),                   -- Rango personal: "0 a 5 personas", etc.
    TIPO_VIAL       VARCHAR2(50),
    NOM_VIAL        VARCHAR2(250),
    TIPO_V_E_1      VARCHAR2(50),
    NOM_V_E_1       VARCHAR2(250),
    TIPO_V_E_2      VARCHAR2(50),
    NOM_V_E_2       VARCHAR2(250),
    TIPO_V_E_3      VARCHAR2(50),
    NOM_V_E_3       VARCHAR2(250),
    NUMERO_EXT      VARCHAR2(30),
    LETRA_EXT       VARCHAR2(100),
    EDIFICIO        VARCHAR2(100),
    EDIFICIO_E      VARCHAR2(100),
    NUMERO_INT      VARCHAR2(30),
    LETRA_INT       VARCHAR2(100),
    TIPO_ASENT      VARCHAR2(50),
    NOMB_ASENT      VARCHAR2(250),                  -- nomb_asent en CSV (no nom_asent)
    TIPOCENCOM      VARCHAR2(50),                   -- Tipo de centro comercial
    NOM_CENCOM      VARCHAR2(250),                  -- Nombre de centro comercial
    NUM_LOCAL       VARCHAR2(20),
    COD_POSTAL      VARCHAR2(10),
    CVE_ENT         NUMBER(2),                      -- Clave numérica entidad 01-32
    ENTIDAD         VARCHAR2(100),                  -- Nombre de la entidad federativa
    CVE_MUN         NUMBER(3),                      -- Clave numérica municipio
    MUNICIPIO       VARCHAR2(150),                  -- Nombre del municipio
    CVE_LOC         NUMBER(4),                      -- Clave numérica localidad
    LOCALIDAD       VARCHAR2(150),                  -- Nombre de la localidad
    AGEB            VARCHAR2(4),
    MANZANA         VARCHAR2(3),
    TELEFONO        VARCHAR2(20),
    CORREOELEC      VARCHAR2(250),
    WWW             VARCHAR2(300),
    TIPOUNIECO      VARCHAR2(20),                   -- tipoUniEco en CSV (antes TIPOUC)
    LATITUD         NUMBER(12,8),
    LONGITUD        NUMBER(12,8),
    FECHA_ALTA      DATE,

    -- 3. Clave primaria
    CONSTRAINT PK_DENUE_ESTAB PRIMARY KEY (ID)
);

-- 4. Verificación: debe mostrar 42
SELECT COUNT(*) AS num_columnas
FROM   user_tab_columns
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS';

-- =============================================================================
-- FIN DEL SCRIPT
-- =============================================================================
