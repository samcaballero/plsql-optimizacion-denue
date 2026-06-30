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

## Archivos en este directorio

| Archivo                   | Descripción                                              |
|---------------------------|----------------------------------------------------------|
| `sqlldr_load.log`         | Log completo de SQL*Loader de la carga inicial           |
| `baseline_tiempos.log`    | Salida de AUTOTRACE con tiempos y logical reads Fase 2   |
