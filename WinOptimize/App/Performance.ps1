param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Apply", "Restore", "Status", "HagsOn", "HagsOff", "AnalyzeDefrag", "DefragDrives")]
    [string]$Action,
    [string]$Drives = ""
)

$ErrorActionPreference = "Stop"
$RootDir    = Split-Path $PSScriptRoot -Parent
$LogsDir    = Join-Path $RootDir "Logs"
$ConfigsDir = Join-Path $RootDir "Configs"
if (-not (Test-Path $LogsDir))    { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (-not (Test-Path $ConfigsDir)) { New-Item -ItemType Directory -Path $ConfigsDir -Force | Out-Null }

$LogFile   = Join-Path $LogsDir "performance.log"
$StateFile = Join-Path $ConfigsDir "performance_baseline.json"
$PendingDefragFile = Join-Path $ConfigsDir "pending_defrag.txt"

$LegacyStateFile = Join-Path $RootDir "Optimizar_Rendimiento_estado_original.json"
if ((Test-Path $LegacyStateFile) -and (-not (Test-Path $StateFile))) {
    Copy-Item $LegacyStateFile $StateFile -ErrorAction SilentlyContinue
}

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
# Plan de energia
# ============================================================
function Get-ActiveSchemeGuid {
    $out = & powercfg /getactivescheme
    if ($out -match '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})') {
        return $Matches[1]
    }
    return $null
}

function Set-MaxPerformancePowerPlan {
    $ultimateTemplate = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    $applied = $false
    try {
        $dup = & powercfg -duplicatescheme $ultimateTemplate 2>$null
        if ($LASTEXITCODE -eq 0 -and $dup -match '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})') {
            & powercfg -setactive $Matches[1] | Out-Null
            Write-Status "Plan de energia: Rendimiento Maximo (Ultimate Performance) activado."
            $applied = $true
        }
    } catch { }
    if (-not $applied) {
        try {
            & powercfg -setactive $highPerfGuid | Out-Null
            Write-Status "Plan de energia: Alto rendimiento activado (Ultimate Performance no disponible en esta edicion)."
        } catch {
            Write-Status "ERROR al activar plan de energia: $($_.Exception.Message)"
        }
    }
}

# ============================================================
# Modo Juego / Game DVR
# ============================================================
function Set-GameModeOn {
    try {
        if (-not (Test-Path "HKCU:\Software\Microsoft\GameBar")) { New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord
        Write-Status "Modo Juego: activado. Grabacion en segundo plano (Game DVR): desactivada."
    } catch {
        Write-Status "ERROR al configurar Modo Juego: $($_.Exception.Message)"
    }
}

function Set-GameModeOff {
    try {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -ErrorAction SilentlyContinue
        Write-Status "Modo Juego y Game DVR: revertidos."
    } catch {
        Write-Status "ERROR al revertir Modo Juego: $($_.Exception.Message)"
    }
}

# ============================================================
# Efectos visuales: "Ajustar para obtener el mejor rendimiento".
# Solo cosmetico (animaciones/sombras/transparencias), cero riesgo
# funcional. Mismo interruptor que Panel de Control -> Sistema ->
# Configuracion avanzada -> Rendimiento -> Ajustar para.
# 0=Dejar que Windows elija, 1=Mejor apariencia, 2=Mejor rendimiento, 3=Personalizado
# ============================================================
function Set-VisualEffectsPerformance {
    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -Type DWord
        Write-Status "Efectos visuales: ajustados a mejor rendimiento (se reflejan luego de cerrar sesion o reiniciar)."
    } catch {
        Write-Status "ERROR al ajustar efectos visuales: $($_.Exception.Message)"
    }
}

function Set-VisualEffectsDefault {
    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Status "Efectos visuales: restaurados (Windows decide automaticamente)."
    } catch { }
}

# ============================================================
# Discos: clasificacion, TRIM, tarea automatica
# ============================================================
function Get-DiskEffectiveType($disk) {
    if ($disk.MediaType -eq "SSD") { return "SSD" }
    if ($disk.MediaType -eq "HDD") { return "HDD" }
    if ($disk.SpindleSpeed -gt 0) { return "HDD" }
    if ($disk.SpindleSpeed -eq 0) { return "SSD" }
    return "Desconocido"
}

function Ensure-Trim {
    try {
        $trimStatus = (fsutil behavior query DisableDeleteNotify) -join " "
        Write-Detail "TRIM (estado previo): $trimStatus"
        if ($trimStatus -notmatch "= 0") {
            fsutil behavior set DisableDeleteNotify 0 | Out-Null
            Write-Status "TRIM (SSD): activado."
        } else {
            Write-Status "TRIM (SSD): ya estaba activado."
        }
    } catch {
        Write-Status "ERROR al verificar/activar TRIM: $($_.Exception.Message)"
    }
}

function Ensure-DefragTask {
    try {
        $task = Get-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\" -ErrorAction Stop
        if ($task.State -eq "Disabled") {
            Enable-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\" -ErrorAction Stop | Out-Null
            Write-Detail "Tarea de optimizacion automatica de discos: habilitada."
        } else {
            Write-Detail "Tarea de optimizacion automatica de discos: ya estaba habilitada."
        }
    } catch {
        Write-Detail "No se pudo verificar la tarea de optimizacion automatica: $($_.Exception.Message)"
    }
}

function Get-DiskReport {
    Write-Detail "----- Discos detectados -----"
    $ssdCount = 0; $hddCount = 0; $lowSpace = @()
    try {
        Get-PhysicalDisk | ForEach-Object {
            $effective = Get-DiskEffectiveType $_
            if ($effective -eq "SSD") { $ssdCount++ }
            if ($effective -eq "HDD") { $hddCount++ }
            $note = if ($_.MediaType -ne $effective -and $effective -ne "Desconocido") { " (corregido por velocidad de giro)" } else { "" }
            Write-Detail "Disco $($_.DeviceId): $($_.FriendlyName) | Tipo: $effective$note | Salud: $($_.HealthStatus)"
        }
    } catch { }
    try {
        Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 } | ForEach-Object {
            $freePct = [math]::Round(($_.SizeRemaining / $_.Size) * 100, 1)
            Write-Detail "Unidad $($_.DriveLetter): $freePct% libre de $([math]::Round($_.Size / 1GB, 1)) GB"
            if ($freePct -lt 15) { $lowSpace += "$($_.DriveLetter): $freePct%" }
        }
    } catch { }
    Write-Status "Discos: $ssdCount SSD/NVMe, $hddCount HDD detectados."
    if ($lowSpace.Count -gt 0) {
        Write-Status "ADVERTENCIA - poco espacio libre: $($lowSpace -join ', ') (menos de 15% degrada el rendimiento real)."
    }
}

function Get-HddVolumes {
    $hddVolumes = @()
    try {
        $hddDisks = Get-PhysicalDisk | Where-Object { (Get-DiskEffectiveType $_) -eq "HDD" }
        foreach ($disk in $hddDisks) {
            $partitions = Get-Partition -DiskNumber $disk.DeviceId -ErrorAction SilentlyContinue
            foreach ($p in $partitions) {
                if ($p.DriveLetter) { $hddVolumes += $p.DriveLetter }
            }
        }
    } catch {
        Write-Detail "No se pudo mapear discos HDD a letras de unidad: $($_.Exception.Message)"
    }
    return $hddVolumes
}

function Get-FragmentationPct($letter) {
    try {
        $out = & defrag.exe "${letter}:" /A /V 2>&1
        $fragLine = $out | Where-Object { $_ -match "fragmenta" -and $_ -match "\d+\s*%" }
        if ($fragLine) {
            $m = [regex]::Match(($fragLine -join " "), "(\d+)\s*%")
            if ($m.Success) { return [int]$m.Groups[1].Value }
        }
    } catch { }
    return $null
}

function Invoke-AnalyzeDefrag {
    $volumes = Get-HddVolumes
    if (-not $volumes) {
        Write-Status "Fragmentacion: no hay discos HDD, no aplica (los SSD nunca se desfragmentan)."
        Set-Content -Path $PendingDefragFile -Value "" -Encoding ASCII -NoNewline
        return
    }
    $recommended = @()
    Write-Status "Analizando fragmentacion de $($volumes.Count) disco(s) HDD..."
    foreach ($letter in $volumes) {
        $pct = Get-FragmentationPct $letter
        if ($null -eq $pct) {
            Write-Detail "[Analisis] Unidad ${letter}: no se pudo determinar la fragmentacion."
        } elseif ($pct -ge 10) {
            Write-Detail "[Analisis] Unidad ${letter}: fragmentacion $pct% -> recomendado."
            $recommended += $letter
        } else {
            Write-Detail "[Analisis] Unidad ${letter}: fragmentacion $pct% -> no hace falta."
        }
    }
    if ($recommended.Count -gt 0) {
        Write-Status "Fragmentacion alta detectada en: $($recommended -join ', ')"
    } else {
        Write-Status "Fragmentacion: dentro de rango normal, no hace falta desfragmentar."
    }
    Set-Content -Path $PendingDefragFile -Value ($recommended -join ",") -Encoding ASCII -NoNewline
}

function Invoke-DefragDrives {
    param([string]$DriveList)
    if ([string]::IsNullOrWhiteSpace($DriveList)) {
        Write-Status "No se especificaron unidades para desfragmentar."
        return
    }
    $letters = $DriveList -split "," | Where-Object { $_ -ne "" }
    foreach ($letter in $letters) {
        try {
            Write-Status "Desfragmentando unidad ${letter}: ... puede tardar varios minutos."
            Optimize-Volume -DriveLetter $letter -Defrag -ErrorAction Stop
            Write-Status "Unidad ${letter}: desfragmentacion finalizada."
        } catch {
            Write-Status "ERROR al desfragmentar ${letter}: $($_.Exception.Message)"
        }
    }
}

# ============================================================
# GPU
# ============================================================
function Get-GpuReport {
    Write-Detail "----- GPU detectada -----"
    try {
        Get-CimInstance Win32_VideoController | ForEach-Object {
            Write-Status "GPU: $($_.Name) (driver $($_.DriverVersion))"
            if ($_.Name -match "NVIDIA") {
                Write-Status "  Ajuste manual: Panel de control NVIDIA -> Administracion de energia 3D -> 'Preferir rendimiento maximo'."
            } elseif ($_.Name -match "AMD|Radeon") {
                Write-Status "  Ajuste manual: AMD Software -> Rendimiento -> perfil grafico a rendimiento."
            } elseif ($_.Name -match "Intel") {
                Write-Status "  Ajuste manual: Panel de graficos Intel -> modo de rendimiento."
            }
        }
    } catch {
        Write-Status "No se pudo consultar la GPU: $($_.Exception.Message)"
    }
}

# ============================================================
# HAGS - aparte, opt-in. Ver nota de riesgo en el menu principal.
# ============================================================
function Set-HagsOn {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord
        Write-Status "HAGS: ACTIVADO. Requiere REINICIO. Si notas caidas de FPS o inestabilidad, desactivalo desde este mismo menu."
    } catch {
        Write-Status "ERROR al activar HAGS: $($_.Exception.Message)"
    }
}

function Set-HagsOff {
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 1 -Type DWord
        Write-Status "HAGS: DESACTIVADO (valor por defecto). Requiere REINICIO."
    } catch {
        Write-Status "ERROR al desactivar HAGS: $($_.Exception.Message)"
    }
}

# ============================================================
# Snapshot / Restore
# ============================================================
function Save-BaselineIfNeeded {
    if (Test-Path $StateFile) {
        Write-Detail "Snapshot de rendimiento ya existe (no se sobreescribe): $StateFile"
        return
    }
    $baseline = @{
        PowerScheme         = Get-ActiveSchemeGuid
        AutoGameModeEnabled = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name AutoGameModeEnabled -ErrorAction SilentlyContinue).AutoGameModeEnabled
        AllowGameDVR        = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -ErrorAction SilentlyContinue).AllowGameDVR
        VisualFXSetting     = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -ErrorAction SilentlyContinue).VisualFXSetting
    }
    $baseline | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
    Write-Detail "Snapshot de configuracion de rendimiento original guardado."
}

function Restore-Performance {
    if (-not (Test-Path $StateFile)) {
        Write-Status "No existe snapshot de rendimiento. Nada que restaurar todavia."
        return
    }
    $baseline = Get-Content $StateFile -Raw | ConvertFrom-Json
    if ($baseline.PowerScheme) {
        try {
            & powercfg -setactive $baseline.PowerScheme | Out-Null
            Write-Status "Plan de energia: restaurado al original."
        } catch {
            Write-Status "ERROR al restaurar plan de energia: $($_.Exception.Message)"
        }
    }
    try {
        if ($null -eq $baseline.AutoGameModeEnabled) {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value $baseline.AutoGameModeEnabled -Type DWord
        }
        if ($null -eq $baseline.AllowGameDVR) {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value $baseline.AllowGameDVR -Type DWord
        }
        Write-Status "Modo Juego / Game DVR: restaurados."
    } catch {
        Write-Status "ERROR al restaurar Modo Juego: $($_.Exception.Message)"
    }
    try {
        if ($null -ne $baseline.VisualFXSetting) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value $baseline.VisualFXSetting -Type DWord -ErrorAction SilentlyContinue
        }
        Write-Status "Efectos visuales: restaurados."
    } catch { }
}

function Show-Status {
    Write-Status "Plan de energia activo (GUID): $(Get-ActiveSchemeGuid)"
    Get-DiskReport
    Get-GpuReport
    Write-Status "Modo Juego: $((Get-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name AutoGameModeEnabled -ErrorAction SilentlyContinue).AutoGameModeEnabled)"
    Write-Status "HAGS (HwSchMode): $((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -ErrorAction SilentlyContinue).HwSchMode) (2=activado, vacio/1=desactivado)"
}

function Apply-Performance {
    Save-BaselineIfNeeded
    Set-MaxPerformancePowerPlan
    Set-GameModeOn
    Set-VisualEffectsPerformance
    Ensure-Trim
    Ensure-DefragTask
    Get-DiskReport
    Get-GpuReport
    Invoke-AnalyzeDefrag
}

Write-Detail "===== Iniciando accion: $Action ====="
switch ($Action) {
    "Apply"         { Apply-Performance }
    "Restore"       { Restore-Performance }
    "Status"        { Show-Status }
    "HagsOn"        { Set-HagsOn }
    "HagsOff"       { Set-HagsOff }
    "AnalyzeDefrag" { Invoke-AnalyzeDefrag }
    "DefragDrives"  { Invoke-DefragDrives -DriveList $Drives }
}
Write-Detail "===== Accion '$Action' finalizada ====="
