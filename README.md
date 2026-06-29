# Laboratorio de Optimización PL/SQL — DENUE INEGI

## Descripción del proyecto

Laboratorio de optimización de rendimiento sobre el DENUE de INEGI (~6.1 M filas), con métricas de antes/después que documentan el impacto de cada técnica aplicada.

## Estructura del repositorio

```
plsql-optimizacion-denue/
├── sql/
│   ├── 00_setup/          — Creación de usuarios, tablespaces y objetos base
│   ├── 01_carga/          — Scripts de carga e importación del dataset DENUE
│   ├── 02_baseline/       — Consultas originales (sin optimizar) y captura de métricas iniciales
│   ├── 03_optimizacion/   — Scripts con las optimizaciones aplicadas (índices, hints, refactors)
│   └── 04_validacion/     — Pruebas de correctitud y comparación de resultados
├── data/
│   └── raw/               — Archivos fuente del DENUE (ignorados por Git; ver instrucciones abajo)
├── benchmarks/            — Resultados de ejecución: tiempos, planes de ejecución, estadísticas
└── informe/               — Documento final con análisis y conclusiones
```

## Entorno técnico

- **Base de datos:** Oracle 23ai Free (Docker)
- **Cliente SQL:** SQLcl
- **Lenguaje:** Oracle PL/SQL

## Dataset

**DENUE INEGI** — Directorio Estadístico Nacional de Unidades Económicas.

El archivo de datos **no está incluido en este repositorio** por su tamaño. Para cargarlo, seguir las instrucciones en `sql/01_carga/`.

## Estado

> En construcción
