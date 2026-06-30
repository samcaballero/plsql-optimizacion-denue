# =============================================================================
# 01_concatenar_csvs.ps1
# Concatena los 25 archivos denue_inegi_XX_.csv en un único CSV,
# escribiendo el header una sola vez.
# Usa StreamReader/StreamWriter de .NET para evitar cargar todo en memoria.
# =============================================================================

$rawDir = "C:\sca\plsql-optimizacion-denue\data\raw\conjunto_de_datos"
$output = "C:\sca\plsql-optimizacion-denue\data\raw\denue_completo.csv"

# Verificar que el directorio fuente exista
if (-not (Test-Path $rawDir)) {
    Write-Error "Directorio no encontrado: $rawDir"
    exit 1
}

$csvFiles = Get-ChildItem -Path $rawDir -Filter "*.csv" | Sort-Object Name
if ($csvFiles.Count -eq 0) {
    Write-Error "No se encontraron archivos .csv en: $rawDir"
    exit 1
}

Write-Host "Archivos encontrados: $($csvFiles.Count)"

# Preguntar si sobreescribir cuando el archivo de salida ya existe
if (Test-Path $output) {
    $respuesta = Read-Host "El archivo '$output' ya existe. ¿Sobreescribir? (s/N)"
    if ($respuesta -notmatch '^[sS]$') {
        Write-Host "Operación cancelada."
        exit 0
    }
    Remove-Item $output -Force
}

$encoding  = [System.Text.Encoding]::GetEncoding(1252)   # Windows-1252 (Latin-1), encoding real del DENUE INEGI
$writer    = New-Object System.IO.StreamWriter($output, $false, $encoding)
$totalRows = 0
$isFirst   = $true

try {
    foreach ($file in $csvFiles) {
        Write-Host "Procesando: $($file.Name)"
        $reader = New-Object System.IO.StreamReader($file.FullName, $encoding)

        try {
            $firstLine = $reader.ReadLine()   # siempre leer el header

            if ($isFirst) {
                $writer.WriteLine($firstLine) # escribir header solo del primer archivo
                $isFirst = $false
            }

            while (-not $reader.EndOfStream) {
                $writer.WriteLine($reader.ReadLine())
                $totalRows++
            }
        }
        finally {
            $reader.Close()
        }
    }
}
finally {
    $writer.Close()
}

# +1 por el header
$totalLines = $totalRows + 1
Write-Host ""
Write-Host "Archivo generado : $output"
Write-Host "Líneas de datos  : $totalRows"
Write-Host "Líneas totales   : $totalLines (incluye header)"
