-- =============================================================================
-- 02_denue.ctl
-- Archivo de control para SQL*Loader.
-- Carga el CSV consolidado en DENUE_LAB.DENUE_ESTABLECIMIENTOS.
--
-- Uso (dentro del contenedor Docker):
--   sqlldr userid=DENUE_LAB/DenueL4b2025#@localhost/FREEPDB1 \
--           control=/tmp/denue.ctl log=/tmp/denue_load.log \
--           DIRECT=TRUE ERRORS=1000 ROWS=50000 BINDSIZE=10485760
-- =============================================================================

-- SKIP=1 a nivel de carga (load-level) para ignorar el header del CSV
OPTIONS (SKIP=1)

-- Indica a SQL*Loader que cargue datos
LOAD DATA
CHARACTERSET WE8MSWIN1252

-- Archivo fuente dentro del contenedor Docker
INFILE '/tmp/denue_completo.csv'

-- Filas rechazadas por errores de conversión o constraint
BADFILE '/tmp/denue_bad.bad'

-- Filas descartadas por cláusula WHEN (ninguna en este caso, pero se declara)
DISCARDFILE '/tmp/denue_discard.dsc'

-- APPEND para no truncar si se carga en varias fases; cambiar a TRUNCATE en carga limpia
APPEND INTO TABLE DENUE_LAB.DENUE_ESTABLECIMIENTOS

-- Delimitador coma; campos opcionalmente entre comillas dobles
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'

-- Columnas faltantes al final de la fila se tratan como NULL
TRAILING NULLCOLS

-- Lista de columnas en el mismo orden exacto que el header del CSV
(
    ID              INTEGER EXTERNAL,           -- identificador único INEGI
    CLEE,                                       -- clave estadística (string)
    NOM_ESTAB,
    RAZ_SOCIAL,
    CODIGO_ACT,                                 -- código SCIAN 2018
    NOMBRE_ACT,
    PER_OCU,
    TIPO_VIAL,
    NOM_VIAL,
    TIPO_V_E_1,
    NOM_V_E_1,
    TIPO_V_E_2,
    NOM_V_E_2,
    TIPO_V_E_3,
    NOM_V_E_3,
    NUMERO_EXT,
    LETRA_EXT,
    EDIFICIO,
    EDIFICIO_E,
    NUMERO_INT,
    LETRA_INT,
    TIPO_ASENT,
    NOMB_ASENT,
    TIPOCENCOM,
    NOM_CENCOM,
    NUM_LOCAL,
    COD_POSTAL,
    CVE_ENT         INTEGER EXTERNAL,           -- clave numérica entidad 01-32
    ENTIDAD,                                    -- nombre de la entidad federativa
    CVE_MUN         INTEGER EXTERNAL,           -- clave numérica municipio
    MUNICIPIO,                                  -- nombre del municipio
    CVE_LOC         INTEGER EXTERNAL,           -- clave numérica localidad
    LOCALIDAD,                                  -- nombre de la localidad
    AGEB,
    MANZANA,
    TELEFONO,
    CORREOELEC,
    WWW,
    TIPOUNIECO,                                 -- tipoUniEco en el CSV original
    LATITUD         DECIMAL EXTERNAL,
    LONGITUD        DECIMAL EXTERNAL,
    FECHA_ALTA      DATE 'YYYY-MM'              -- el DENUE incluye año-mes, sin día
)
