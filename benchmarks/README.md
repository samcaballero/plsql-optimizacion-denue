# Benchmarks — Laboratorio de Optimización PL/SQL DENUE

## Hito 1 — Carga masiva con SQL*Loader direct path

| Parámetro        | Valor                                      |
|------------------|--------------------------------------------|
| Dataset          | DENUE INEGI 05/2026                        |
| Registros fuente | 6,138,075                                  |
| Filas cargadas   | 6,138,071                                  |
| Filas rechazadas | 4                                          |
| Método           | SQL*Loader — direct path (`DIRECT=TRUE`)   |
| Tiempo           | 38.7 segundos                              |
| Encoding origen  | Windows-1252 (`WE8MSWIN1252`)              |
| Encoding Oracle  | AL32UTF8 (conversión automática en carga)  |
| Log              | `sqlldr_load.log`                          |

Este tiempo es la **línea base de referencia** para la Fase 1. Las siguientes
mediciones compararán el rendimiento de inserción PL/SQL fila por fila vs
`BULK COLLECT`/`FORALL` contra este punto de partida.

## Línea base — Fase 2

Resultados de las 6 consultas ejecutadas **sin índices** (solo existe la PK sobre `ID`).
Capturados con `SET AUTOTRACE ON` en SQLcl sobre 6,138,071 filas.

| #  | Consulta                        | Filas devueltas | Logical reads | Tiempo  |
|----|---------------------------------|----------------:|---------------:|---------|
| Q1 | Conteo por entidad              |              32 |       412,745  | 3.28 s  |
| Q2 | Comercio (SCIAN 46) en CDMX     |         212,251 |       412,745  | 8.53 s  |
| Q3 | Top 20 municipios — alimentos   |              20 |       412,745  | 1.41 s  |
| Q4 | Establecimientos grandes        |          13,198 |       412,745  | 2.26 s  |
| Q5 | Distribución manufactura        |               7 |       412,745  | 1.40 s  |
| Q6 | Búsqueda "OXXO"                 |          24,321 |       412,745  | 3.48 s  |

Las 6 consultas leen el mismo número fijo de bloques lógicos (412,745) sin importar
cuántas filas devuelven, confirmando `TABLE ACCESS FULL` en todos los casos. Una
consulta que devuelve 7 filas consume exactamente los mismos recursos de I/O que
una que devuelve 212,251 — evidencia directa del costo del escaneo completo.
Esta es la línea base que la Fase 3 busca reducir mediante índices.

## Limitación documentada — Q6 (búsqueda OXXO)

### Error encontrado

Al intentar crear el índice Oracle Text para Q6 (`LIKE '%OXXO%'`):

```sql
CREATE INDEX IX_DENUE_NOM_ESTAB_TXT ON DENUE_ESTABLECIMIENTOS(NOM_ESTAB)
INDEXTYPE IS CTXSYS.CONTEXT;
-- ORA-29833: indextype does not exist
```

Confirmado que `CTXSYS` no existe en esta instancia:

```sql
SELECT username  FROM dba_users   WHERE username    = 'CTXSYS';       -- no rows
SELECT comp_name FROM dba_registry WHERE comp_name LIKE '%Text%';     -- no rows
```

**Causa:** las imágenes Oracle Database Free para Docker no incluyen Oracle Text
ni otros componentes opcionales (`CTXSYS`, `MDSYS`, etc.). Es una instalación
mínima de desarrollo, no una instalación Enterprise completa.

### Por qué LIKE '%X%' no es indexable con B-tree

Un índice B-tree ordena los valores de izquierda a derecha. Para `LIKE 'OXXO%'`
Oracle puede hacer _range scan_ porque el prefijo `'OXXO'` acota el rango en el
árbol. Para `LIKE '%OXXO%'`, el patrón puede aparecer en cualquier posición del
valor — Oracle no sabe dónde buscar en el árbol y recurre a `TABLE ACCESS FULL`
sin importar qué índice B-tree exista sobre la columna.

### Alternativa implementada (mejora parcial)

Se creó un **índice de función** sobre `UPPER(NOM_ESTAB)`:

```sql
CREATE INDEX IX_DENUE_NOM_ESTAB_FN ON DENUE_ESTABLECIMIENTOS (UPPER(NOM_ESTAB));
```

Este índice ayuda en búsquedas exactas (`UPPER(NOM_ESTAB) = 'OXXO'`) o de
prefijo (`UPPER(NOM_ESTAB) LIKE 'OXXO%'`), pero **no resuelve** el problema
de `LIKE '%OXXO%'` — Q6 sigue haciendo `TABLE ACCESS FULL`.

### Solución completa (fuera del alcance de este laboratorio)

| Opción | Contexto |
|--------|----------|
| **Oracle Text** (`CTXSYS.CONTEXT`) | Disponible en Oracle EE/SE; índice invertido, `CONTAINS()` en lugar de `LIKE` |
| **Elasticsearch / OpenSearch** | Motor externo sincronizado con Oracle; adecuado para producción con millones de búsquedas textuales |

> **Nota:** esta limitación se documenta como ejemplo de **juicio técnico honesto
> ante restricciones de infraestructura**, no como un fallo del proyecto. Identificar
> los límites de la optimización disponible es parte del análisis de rendimiento.

## Archivos en este directorio

| Archivo                   | Descripción                                              |
|---------------------------|----------------------------------------------------------|
| `sqlldr_load.log`         | Log completo de SQL*Loader de la carga inicial           |
| `baseline_tiempos.log`    | Salida de AUTOTRACE con tiempos y logical reads Fase 2   |
