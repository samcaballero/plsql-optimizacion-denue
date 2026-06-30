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

## Archivos en este directorio

| Archivo            | Descripción                                         |
|--------------------|-----------------------------------------------------|
| `sqlldr_load.log`  | Log completo de SQL*Loader de la carga inicial      |
