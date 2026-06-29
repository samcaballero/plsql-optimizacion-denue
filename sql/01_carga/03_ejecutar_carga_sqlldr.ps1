# =============================================================================
# 03_ejecutar_carga_sqlldr.ps1
# Orquesta la carga completa del DENUE en Oracle 23ai Free (Docker).
#
# Prerequisitos:
#   - Haber ejecutado 01_concatenar_csvs.ps1 (genera denue_completo.csv)
#   - Contenedor Docker 'oracle23ai' corriendo con FREEPDB1 disponible
#   - Usuario DENUE_LAB y tabla DENUE_ESTABLECIMIENTOS ya creados
# =============================================================================

$repoRoot   = "C:\sca\plsql-optimizacion-denue"
$csvHost    = "$repoRoot\data\raw\denue_completo.csv"
$ctlHost    = "$repoRoot\sql\01_carga\02_denue.ctl"
$logHost    = "$repoRoot\benchmarks\sqlldr_load.log"
$container  = "oracle23ai"
$csvDocker  = "/tmp/denue_completo.csv"
$ctlDocker  = "/tmp/denue.ctl"
$logDocker  = "/tmp/denue_load.log"

# 1. Verificar que el CSV consolidado exista
if (-not (Test-Path $csvHost)) {
    Write-Error "Archivo no encontrado: $csvHost"
    Write-Error "Ejecuta primero 01_concatenar_csvs.ps1"
    exit 1
}
Write-Host "[1/5] CSV encontrado: $csvHost"

# 2a. Copiar CSV al contenedor
Write-Host "[2/5] Copiando CSV al contenedor..."
docker cp $csvHost "${container}:${csvDocker}"
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo docker cp CSV"; exit 1 }

# 2b. Copiar control file al contenedor
Write-Host "[2/5] Copiando .ctl al contenedor..."
docker cp $ctlHost "${container}:${ctlDocker}"
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo docker cp .ctl"; exit 1 }

# 3. Ejecutar SQL*Loader y medir tiempo
Write-Host "[3/5] Ejecutando SQL*Loader (modo DIRECT)..."
$start = Get-Date

docker exec $container sqlldr `
    "userid=DENUE_LAB/DenueL4b2025#@localhost/FREEPDB1" `
    "control=$ctlDocker" `
    "log=$logDocker" `
    "DIRECT=TRUE" `
    "ERRORS=1000" `
    "ROWS=50000" `
    "BINDSIZE=10485760"

$sqlldrExit = $LASTEXITCODE
$elapsed    = (Get-Date) - $start

Write-Host ""
Write-Host "Tiempo de carga SQL*Loader: $([math]::Round($elapsed.TotalSeconds, 1)) segundos"

if ($sqlldrExit -ne 0) {
    Write-Warning "SQL*Loader terminó con código de salida $sqlldrExit (puede haber filas rechazadas)"
}

# 4. Copiar log de vuelta al host
Write-Host "[4/5] Copiando log al host..."
docker cp "${container}:${logDocker}" $logHost
if ($LASTEXITCODE -ne 0) {
    Write-Warning "No se pudo copiar el log desde el contenedor."
} else {
    Write-Host "Log guardado en: $logHost"
}

# 5. Mostrar las últimas 20 líneas del log
Write-Host ""
Write-Host "[5/5] Últimas 20 líneas del log:"
Write-Host ("-" * 60)
if (Test-Path $logHost) {
    Get-Content $logHost -Tail 20
} else {
    Write-Warning "Log no disponible localmente; consultarlo dentro del contenedor:"
    Write-Warning "  docker exec $container cat $logDocker"
}

Write-Host ("-" * 60)
Write-Host "Carga finalizada. Tiempo total: $([math]::Round($elapsed.TotalMinutes, 2)) minutos"
