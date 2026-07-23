param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("StartupReport", "SfcScan", "DismRepair", "GpuDriverCheck", "DirectXCheck")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path $PSScriptRoot -Parent
$LogsDir = Join-Path $RootDir "Logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile = Join-Path $LogsDir "health.log"
$SfcResultFile = Join-Path $RootDir "Configs\sfc_needs_dism.flag"

function Write-Detail {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" -Encoding UTF8
}
function Write-Status {
    param([string]$Message)
    Write-Detail $Message
    Write-Host "  $Message"
}

# ============================================================
# Reporte de programas de inicio. SOLO LECTURA - no desactiva
# nada. Decidir que desactivar depende de como usa la PC cada
# persona (backup, seguridad, drivers de mouse, etc.) y eso no
# se puede juzgar de forma segura sin intervencion humana.
# ============================================================
$KnownHeavyPatterns = @("Spotify", "Discord", "Adobe", "Steam", "Epic", "Battle.net",
                        "Teams", "Skype", "Zoom", "CCleaner", "uTorrent", "qBittorrent")

function Invoke-StartupReport {
    try {
        $items = Get-CimInstance Win32_StartupCommand -ErrorAction Stop
        if (-not $items) {
            Write-Status "Programas de inicio: no se detecto ninguno."
            return
        }
        Write-Detail "----- Programas de inicio detectados -----"
        $heavy = @()
        foreach ($i in $items) {
            Write-Detail "  $($i.Name) | Comando: $($i.Command) | Ubicacion: $($i.Location)"
            foreach ($pattern in $KnownHeavyPatterns) {
                if ($i.Name -match $pattern -or $i.Command -match $pattern) {
                    $heavy += $i.Name
                    break
                }
            }
        }
        Write-Status "Programas de inicio: $($items.Count) detectados en total."
        if ($heavy.Count -gt 0) {
            Write-Status "Con impacto conocido en el arranque: $($heavy -join ', ')"
            Write-Status "Revisar y desactivar los que no necesites desde: Administrador de tareas -> pestaña Inicio."
        } else {
            Write-Status "No se detectaron programas de arranque de alto impacto conocido."
        }
    } catch {
        Write-Status "No se pudo generar el reporte de inicio: $($_.Exception.Message)"
    }
}

# ============================================================
# SFC: herramienta oficial de Microsoft, verifica y repara
# archivos de sistema corruptos. Segura, sin efectos secundarios.
# Los mensajes de resultado de sfc.exe salen en el idioma de
# Windows, por eso se busca por palabras clave en varios idiomas.
# ============================================================
function Invoke-SfcScan {
    Write-Status "Verificando integridad de archivos del sistema (puede tardar varios minutos)..."
    $tempOut = Join-Path $env:TEMP "sfc_output.txt"
    try {
        cmd /c "sfc /scannow > `"$tempOut`"" | Out-Null
    } catch {
        Write-Status "ERROR al ejecutar SFC: $($_.Exception.Message)"
        return
    }
    $content = ""
    try {
        $content = Get-Content -Path $tempOut -Raw -Encoding Unicode -ErrorAction Stop
    } catch {
        try { $content = Get-Content -Path $tempOut -Raw -ErrorAction SilentlyContinue } catch { }
    }
    Write-Detail "----- Salida completa de SFC -----"
    Write-Detail $content

    $clean   = $content -match "no encontr|did not find"
    $fixed   = $content -match "repar|repaired"
    $unfixed = $content -match "no ha podido|no pudo reparar|unable to fix|was unable"

    if ($unfixed) {
        Write-Status "SFC encontro archivos corruptos que NO pudo reparar por si solo."
        Set-Content -Path $SfcResultFile -Value "needs_dism" -Encoding ASCII -NoNewline
    } elseif ($fixed) {
        Write-Status "SFC encontro y reparo archivos corruptos correctamente."
        if (Test-Path $SfcResultFile) { Remove-Item $SfcResultFile -Force -ErrorAction SilentlyContinue }
    } elseif ($clean) {
        Write-Status "SFC: no se encontraron violaciones de integridad. Sistema limpio."
        if (Test-Path $SfcResultFile) { Remove-Item $SfcResultFile -Force -ErrorAction SilentlyContinue }
    } else {
        Write-Status "SFC finalizo pero no se pudo interpretar el resultado con certeza. Revisar Logs\health.log para el detalle completo."
    }
}

function Invoke-DismRepair {
    Write-Status "Ejecutando reparacion profunda con DISM (requiere internet, puede tardar bastante)..."
    try {
        $out = & DISM.exe /Online /Cleanup-Image /RestoreHealth 2>&1
        Write-Detail "----- Salida de DISM -----"
        Write-Detail ($out -join "`n")
        if ($LASTEXITCODE -eq 0) {
            Write-Status "DISM finalizo correctamente."
            if (Test-Path $SfcResultFile) { Remove-Item $SfcResultFile -Force -ErrorAction SilentlyContinue }
        } else {
            Write-Status "DISM finalizo con codigo $LASTEXITCODE. Revisar Logs\health.log para el detalle."
        }
    } catch {
        Write-Status "ERROR al ejecutar DISM: $($_.Exception.Message)"
    }
}

# ============================================================
# GPU: reporte de antiguedad del driver. Solo informativo, no
# descarga ni instala nada - eso requiere el instalador oficial
# del fabricante (NVIDIA/AMD/Intel).
# ============================================================
function Invoke-GpuDriverCheck {
    try {
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
        foreach ($g in $gpus) {
            $ageInfo = ""
            if ($g.DriverDate) {
                try {
                    $driverDate = [Management.ManagementDateTimeConverter]::ToDateTime($g.DriverDate)
                    $ageDays = (Get-Date) - $driverDate
                    $ageInfo = " | Fecha del driver: $($driverDate.ToString('yyyy-MM-dd')) ($([math]::Round($ageDays.TotalDays / 30)) meses)"
                    if ($ageDays.TotalDays -gt 365) {
                        $ageInfo += " -- driver con mas de 1 anio, se recomienda revisar actualizacion"
                    }
                } catch { }
            }
            Write-Status "GPU: $($g.Name) | Driver: $($g.DriverVersion)$ageInfo"
        }
        Write-Status "Descarga oficial: NVIDIA (nvidia.com/drivers), AMD (amd.com/support), Intel (intel.com/content/www/us/en/support)."
    } catch {
        Write-Status "No se pudo consultar el driver de GPU: $($_.Exception.Message)"
    }
}

# ============================================================
# DirectX: solo verificacion, NUNCA instalacion automatica.
# DirectX 12 (compatible con la API de 11) ya viene integrado al
# sistema operativo y se actualiza solo via Windows Update - no
# hay nada que instalar ni ningun interruptor que tocar ahi.
# Lo unico que puede faltar son componentes LEGACY de DirectX 9
# (d3dx9_43.dll, xinput1_3.dll, etc.) que necesitan juegos viejos
# (anteriores a ~2010). Si faltan, la solucion oficial es el
# "DirectX End-User Runtime" de Microsoft - un instalador aparte
# que el usuario debe descargar y ejecutar el mismo: este programa
# nunca descarga ni ejecuta instaladores de terceros o de internet.
# ============================================================
function Invoke-DirectXCheck {
    $tempOut = Join-Path $env:TEMP "dxdiag_report.txt"
    try {
        Start-Process -FilePath "dxdiag.exe" -ArgumentList "/t `"$tempOut`"" -Wait -ErrorAction Stop
    } catch {
        Write-Status "No se pudo ejecutar dxdiag: $($_.Exception.Message)"
        return
    }

    Start-Sleep -Seconds 1
    if (-not (Test-Path $tempOut)) {
        Write-Status "DirectX: no se pudo generar el reporte de dxdiag."
        return
    }

    $content = Get-Content -Path $tempOut -Raw -ErrorAction SilentlyContinue
    Write-Detail "----- Reporte dxdiag (resumen) -----"

    $dxVersion = $null
    if ($content -match "DirectX Version:\s*(.+)") { $dxVersion = $Matches[1].Trim() }
    if ($dxVersion) {
        Write-Status "DirectX del sistema: $dxVersion (integrado a Windows, se actualiza solo via Windows Update)."
    } else {
        Write-Status "No se pudo determinar la version de DirectX del sistema en el reporte."
    }

    $featureLevels = [regex]::Matches($content, "Feature Levels:\s*(.+)")
    if ($featureLevels.Count -gt 0) {
        $levels = $featureLevels[0].Groups[1].Value.Trim()
        Write-Status "Niveles de funciones soportados por tu GPU: $levels"
        Write-Detail "Feature Levels completos: $levels"
    }

    Write-Status "Si un juego ANTIGUO (antes de 2010 aprox.) pide una DLL de DirectX 9 faltante, instalar manualmente el 'DirectX End-User Runtime' oficial desde: https://www.microsoft.com/download/details.aspx?id=35"
    Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
}

Write-Detail "===== Iniciando accion: $Action ====="
switch ($Action) {
    "StartupReport"  { Invoke-StartupReport }
    "SfcScan"        { Invoke-SfcScan }
    "DismRepair"     { Invoke-DismRepair }
    "GpuDriverCheck" { Invoke-GpuDriverCheck }
    "DirectXCheck"   { Invoke-DirectXCheck }
}
Write-Detail "===== Accion '$Action' finalizada ====="
