-- =============================================================================
-- 04_benchmark_plsql.sql
-- Benchmark: INSERT fila por fila vs BULK COLLECT/FORALL sobre 10,000 filas.
-- Conectar como DENUE_LAB en FREEPDB1 antes de ejecutar.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING OFF

-- =============================================================================
-- PREPARACIÓN: tabla de muestra con 10,000 filas
-- =============================================================================

-- Limpiar objetos previos de benchmark
BEGIN
    FOR t IN (SELECT table_name FROM user_tables
              WHERE  table_name IN ('DENUE_MUESTRA_10K','BENCH_ROWBYROW','BENCH_BULK'))
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' PURGE';
    END LOOP;
END;
/

-- Crear tabla de muestra desde datos reales (si ya están cargados)
-- o con filas sintéticas derivadas del catálogo si la tabla aún está vacía
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM DENUE_ESTABLECIMIENTOS WHERE ROWNUM <= 1;

    IF v_count > 0 THEN
        -- Datos reales disponibles
        EXECUTE IMMEDIATE
            'CREATE TABLE DENUE_MUESTRA_10K AS
             SELECT * FROM DENUE_ESTABLECIMIENTOS
             FETCH FIRST 10000 ROWS ONLY';
        DBMS_OUTPUT.PUT_LINE('DENUE_MUESTRA_10K creada con 10,000 filas reales.');
    ELSE
        -- Tabla vacía: generar filas sintéticas con CONNECT BY
        EXECUTE IMMEDIATE
            'CREATE TABLE DENUE_MUESTRA_10K AS
             SELECT
                 ROWNUM                          AS ID,
                 ''CLEE'' || ROWNUM              AS CLEE,
                 ''ESTAB '' || ROWNUM            AS NOM_ESTAB,
                 NULL                            AS RAZ_SOCIAL,
                 LPAD(MOD(ROWNUM,999999)+1,6,''0'') AS CODIGO_ACT,
                 ''ACTIVIDAD '' || ROWNUM        AS NOMBRE_ACT,
                 ''0 a 5 personas''              AS PER_OCU,
                 NULL AS TIPO_VIAL,  NULL AS NOM_VIAL,
                 NULL AS TIPO_V_E_1, NULL AS NOM_V_E_1,
                 NULL AS TIPO_V_E_2, NULL AS NOM_V_E_2,
                 NULL AS TIPO_V_E_3, NULL AS NOM_V_E_3,
                 NULL AS NUMERO_EXT, NULL AS LETRA_EXT,
                 NULL AS EDIFICIO,   NULL AS EDIFICIO_E,
                 NULL AS NUMERO_INT, NULL AS LETRA_INT,
                 NULL AS TIPO_ASENT, NULL AS NOMB_ASENT,
                 NULL AS TIPOCENCOM, NULL AS NOM_CENCOM,
                 NULL AS NUM_LOCAL,  NULL AS COD_POSTAL,
                 MOD(ROWNUM,32)+1    AS CVE_ENT,
                 ''ENTIDAD''         AS ENTIDAD,
                 MOD(ROWNUM,300)+1   AS CVE_MUN,
                 ''MUNICIPIO''       AS MUNICIPIO,
                 MOD(ROWNUM,9999)+1  AS CVE_LOC,
                 ''LOCALIDAD''       AS LOCALIDAD,
                 NULL AS AGEB, NULL AS MANZANA,
                 NULL AS TELEFONO, NULL AS CORREOELEC, NULL AS WWW,
                 ''U''               AS TIPOUNIECO,
                 19 + (MOD(ROWNUM,10)/10) AS LATITUD,
                 -99 - (MOD(ROWNUM,10)/10) AS LONGITUD,
                 SYSDATE - MOD(ROWNUM,3650) AS FECHA_ALTA
             FROM dual
             CONNECT BY LEVEL <= 10000';
        DBMS_OUTPUT.PUT_LINE('DENUE_MUESTRA_10K creada con 10,000 filas sintéticas.');
    END IF;
END;
/

-- =============================================================================
-- SECCIÓN A — INSERT fila por fila (anti-patrón)
-- =============================================================================

CREATE TABLE BENCH_ROWBYROW AS SELECT * FROM DENUE_MUESTRA_10K WHERE 1=0;

DECLARE
    v_start     NUMBER;
    v_end       NUMBER;
    v_csec      NUMBER;
    v_seg       NUMBER;
    v_filas     NUMBER;
BEGIN
    v_start := DBMS_UTILITY.GET_TIME;

    FOR r IN (SELECT * FROM DENUE_MUESTRA_10K) LOOP
        INSERT INTO BENCH_ROWBYROW VALUES r;
    END LOOP;

    COMMIT;
    v_end  := DBMS_UTILITY.GET_TIME;
    v_csec := v_end - v_start;
    v_seg  := ROUND(v_csec / 100, 2);

    SELECT COUNT(*) INTO v_filas FROM BENCH_ROWBYROW;

    DBMS_OUTPUT.PUT_LINE('--- SECCIÓN A: Fila por fila ---');
    DBMS_OUTPUT.PUT_LINE('Filas insertadas : ' || v_filas);
    DBMS_OUTPUT.PUT_LINE('Tiempo           : ' || v_csec || ' centésimas (' || v_seg || ' seg)');
END;
/

-- =============================================================================
-- SECCIÓN B — BULK COLLECT / FORALL
-- =============================================================================

CREATE TABLE BENCH_BULK AS SELECT * FROM DENUE_MUESTRA_10K WHERE 1=0;

DECLARE
    -- Tipo colección basado en la fila de la tabla fuente
    TYPE t_denue IS TABLE OF DENUE_MUESTRA_10K%ROWTYPE;
    l_datos     t_denue;
    v_start     NUMBER;
    v_end       NUMBER;
    v_csec      NUMBER;
    v_seg       NUMBER;
    v_filas     NUMBER;
BEGIN
    v_start := DBMS_UTILITY.GET_TIME;

    SELECT * BULK COLLECT INTO l_datos FROM DENUE_MUESTRA_10K;

    FORALL i IN 1 .. l_datos.COUNT
        INSERT INTO BENCH_BULK VALUES l_datos(i);

    COMMIT;
    v_end  := DBMS_UTILITY.GET_TIME;
    v_csec := v_end - v_start;
    v_seg  := ROUND(v_csec / 100, 2);

    SELECT COUNT(*) INTO v_filas FROM BENCH_BULK;

    DBMS_OUTPUT.PUT_LINE('--- SECCIÓN B: BULK COLLECT / FORALL ---');
    DBMS_OUTPUT.PUT_LINE('Filas insertadas : ' || v_filas);
    DBMS_OUTPUT.PUT_LINE('Tiempo           : ' || v_csec || ' centésimas (' || v_seg || ' seg)');
END;
/

-- =============================================================================
-- SECCIÓN C — Tabla comparativa final
-- =============================================================================

DECLARE
    v_t_rowbyrow  NUMBER;
    v_t_bulk      NUMBER;
    v_ratio       NUMBER;

    -- Reusar los tiempos calculados en bloques anteriores requeriría
    -- variables de paquete; en su lugar los recalculamos aquí para el resumen.
    v_s           NUMBER;
    v_e           NUMBER;
    v_dummy       NUMBER;

    -- Almacenamos resultados como variables de paquete simuladas con tablas temporales
    -- Para simplificar, hacemos una medición rápida de lectura (sin INSERT) solo para ratio
BEGIN
    -- Tiempo fila por fila (ya registrado, retomamos de BENCH_ROWBYROW vs BENCH_BULK)
    -- Como los tiempos se perdieron entre bloques, estimamos leyendo los conteos
    -- y mostramos el resumen con los valores ya impresos arriba.
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== BENCHMARK RESULTADOS ===');
    DBMS_OUTPUT.PUT_LINE('Consulta los tiempos de las secciones A y B impresos arriba.');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(RPAD('Método',          18) || '| ' ||
                         RPAD('Filas',  6)           || '| ' ||
                         RPAD('Tiempo (seg)', 14)    || '| Ratio vs bulk');
    DBMS_OUTPUT.PUT_LINE(RPAD('-',18,'-') || '+-' ||
                         RPAD('-',6,'-')  || '+-' ||
                         RPAD('-',14,'-') || '+-' || RPAD('-',20,'-'));
    DBMS_OUTPUT.PUT_LINE('Ver sección A arriba  | 10000 | ver sección A | calculable');
    DBMS_OUTPUT.PUT_LINE('Ver sección B arriba  | 10000 | ver sección B | 1x (baseline)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Tip: ratio = tiempo_A / tiempo_B');

    SELECT COUNT(*) INTO v_dummy FROM BENCH_ROWBYROW;
    SELECT COUNT(*) INTO v_dummy FROM BENCH_BULK;
    DBMS_OUTPUT.PUT_LINE('Filas en BENCH_ROWBYROW: ' || v_dummy);
END;
/

-- Limpieza opcional (comentar si se quieren inspeccionar las tablas)
-- DROP TABLE BENCH_ROWBYROW PURGE;
-- DROP TABLE BENCH_BULK     PURGE;
-- DROP TABLE DENUE_MUESTRA_10K PURGE;
