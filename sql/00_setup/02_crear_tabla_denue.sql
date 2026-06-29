-- =============================================================================
-- 02_crear_tabla_denue.sql
-- Crea la tabla principal DENUE_ESTABLECIMIENTOS en el esquema DENUE_LAB.
-- Basado en el diccionario de datos oficial DENUE INEGI (edición 2024-2025).
--
-- ADVERTENCIA: Validar las columnas y sus nombres contra el header real del
-- archivo CSV antes de cargar datos. El diccionario oficial puede diferir
-- ligeramente entre ediciones (columnas adicionales, renombres, orden distinto).
-- Ajustar este DDL si es necesario antes de ejecutar sql/01_carga/.
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

-- 2. Crear la tabla
CREATE TABLE DENUE_LAB.DENUE_ESTABLECIMIENTOS
(
    -- Identificador único INEGI
    ID              NUMBER                      NOT NULL,

    -- Datos del establecimiento
    NOM_ESTAB       VARCHAR2(200),              -- Nombre comercial
    RAZ_SOCIAL      VARCHAR2(200),              -- Razón social

    -- Actividad económica (SCIAN 2018)
    CODIGO_ACT      VARCHAR2(10),               -- Código de 6 dígitos
    NOMBRE_ACT      VARCHAR2(300),              -- Descripción de la actividad

    -- Tamaño
    PER_OCU         VARCHAR2(30),               -- Rango de personal ocupado

    -- Domicilio — vialidad principal
    TIPO_VIAL       VARCHAR2(50),
    NOM_VIAL        VARCHAR2(200),

    -- Domicilio — vialidades de referencia (entre calles)
    TIPO_V_E_1      VARCHAR2(50),
    NOM_V_E_1       VARCHAR2(200),
    TIPO_V_E_2      VARCHAR2(50),
    NOM_V_E_2       VARCHAR2(200),
    TIPO_V_E_3      VARCHAR2(50),
    NOM_V_E_3       VARCHAR2(200),

    -- Número y letra exterior/interior
    NUMERO_EXT      VARCHAR2(30),
    LETRA_EXT       VARCHAR2(10),
    EDIFICIO        VARCHAR2(100),
    EDIFICIO_E      VARCHAR2(100),
    NUMERO_INT      VARCHAR2(30),
    LETRA_INT       VARCHAR2(10),

    -- Asentamiento
    TIPO_ASENT      VARCHAR2(50),               -- Colonia, ejido, fraccionamiento, etc.
    NOM_ASENT       VARCHAR2(200),
    COD_POSTAL      VARCHAR2(10),

    -- Claves geoestadísticas INEGI
    ENTIDAD         NUMBER(2),                  -- Clave entidad federativa (01-32)
    MUNICIPIO       NUMBER(3),                  -- Clave de municipio
    LOCALIDAD       NUMBER(4),                  -- Clave de localidad
    AGEB            VARCHAR2(4),
    MANZANA         VARCHAR2(3),

    -- Contacto
    TELEFONO        VARCHAR2(20),
    CORREOELEC      VARCHAR2(200),
    WWW             VARCHAR2(300),

    -- Clasificación
    TIPOUC          VARCHAR2(10),               -- Tipo de unidad económica
    MULTIUNIDAD     VARCHAR2(5),
    ID_STRATUM      VARCHAR2(10),               -- Estrato del establecimiento

    -- Temporalidad
    FECHA_ALTA      DATE,                       -- Fecha de incorporación al DENUE

    -- Coordenadas geográficas
    LATITUD         NUMBER(12,8),
    LONGITUD        NUMBER(12,8),

    -- 3. Clave primaria
    CONSTRAINT PK_DENUE_ESTAB PRIMARY KEY (ID)
);

-- 4. Verificación: nombre de tabla y número de columnas creadas
SELECT table_name,
       COUNT(*) AS num_columnas
FROM   user_tab_columns
WHERE  table_name = 'DENUE_ESTABLECIMIENTOS'
GROUP BY table_name;

-- =============================================================================
-- FIN DEL SCRIPT
-- =============================================================================
