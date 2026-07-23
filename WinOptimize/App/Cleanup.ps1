param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Run", "EmptyRecycleBin")]
    [string]$Action
)

$ErrorActionPreference = "Continue"
$RootDir   = Split-Path $PSScriptRoot -Parent
$LogsDir   = Join-Path $RootDir "Logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile = Join-Path $LogsDir "cleanup.log"

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $Message
}

# ============================================================
# Solo se tocan carpetas de cache/temporal, cuyo contenido Windows
# regenera automaticamente. NO se toca Prefetch (a proposito: es
# un mito que limpiarlo mejora el rendimiento, Windows lo usa para
# acelerar el inicio de programas; borrarlo lo empeora al principio).
# NO se toca Windows.old (requiere decision explicita del usuario,
# se reporta si existe pero no se borra automaticamente).
# ============================================================
$CleanupTargets = @(
    @{ Path = $env:TEMP;                                                      Label = "Temp del usuario";                    StopServices = @() },
    @{ Path = "$env:SystemRoot\Temp";                                         Label = "Temp del sistema";                    StopServices = @() },
    @{ Path = "$env:LocalAppData\Microsoft\Windows\Explorer";  Filter = "thumbcache_*.db"; Label = "Cache de miniaturas";     StopServices = @() },
    @{ Path = "$env:SystemRoot\SoftwareDistribution\Download";                Label = "Cache de descargas de Windows Update"; StopServices = @("wuauserv", "bits") },
    @{ Path = "$env:ProgramData\Microsoft\Windows\WER";                       Label = "Cola de informes de error"; StopServices = @() }
)

function Get-FolderSizeBytes($path, $filter) {
    if (-not (Test-Path $path)) { return 0 }
    try {
        if ($filter) {
            $items = Get-ChildItem -Path $path -Filter $filter -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
        return ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    } catch { return 0 }
}

function Invoke-Cleanup {
    $totalFreed = 0
    foreach ($t in $CleanupTargets) {
        if (-not (Test-Path $t.Path)) {
            Write-Log "[$($t.Label)] Carpeta no existe, se omite."
            continue
        }
        foreach ($svc in $t.StopServices) {
            try { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue } catch { }
        }

        $before = Get-FolderSizeBytes $t.Path $t.Filter
        $errors = 0
        try {
            if ($t.Filter) {
                Get-ChildItem -Path $t.Path -Filter $t.Filter -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    try { Remove-Item $_.FullName -Force -ErrorAction Stop } catch { $errors++ }
                }
            } else {
                Get-ChildItem -Path $t.Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    try { Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop } catch { $errors++ }
                }
            }
        } catch { }

        foreach ($svc in $t.StopServices) {
            try { Start-Service -Name $svc -ErrorAction SilentlyContinue } catch { }
        }

        $after = Get-FolderSizeBytes $t.Path $t.Filter
        $freed = [math]::Max(0, $before - $after)
        $totalFreed += $freed
        $freedMB = [math]::Round($freed / 1MB, 1)
        if ($errors -gt 0) {
            Write-Log "[$($t.Label)] Liberados $freedMB MB. $errors archivos en uso, omitidos (normal, no afecta nada)."
        } else {
            Write-Log "[$($t.Label)] Liberados $freedMB MB."
        }
    }

    $totalMB = [math]::Round($totalFreed / 1MB, 1)
    Write-Log "TOTAL liberado: $totalMB MB."

    $winOld = Join-Path $env:SystemDrive "Windows.old"
    if (Test-Path $winOld) {
        Write-Log "NOTA: existe la carpeta Windows.old (instalacion anterior de Windows). No se borra automaticamente porque impide volver atras si la borras. Si no la necesitas, usar el 'Liberador de espacio en disco' de Windows -> 'Instalaciones anteriores de Windows'."
    }
}

function Invoke-EmptyRecycleBin {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Log "Papelera de reciclaje vaciada."
    } catch {
        Write-Log "ERROR al vaciar la papelera (o ya estaba vacia): $($_.Exception.Message)"
    }
}

Write-Log "===== Iniciando accion: $Action ====="
switch ($Action) {
    "Run"              { Invoke-Cleanup }
    "EmptyRecycleBin"  { Invoke-EmptyRecycleBin }
}
Write-Log "===== Accion '$Action' finalizada ====="
