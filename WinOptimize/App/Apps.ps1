param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Install", "Uninstall", "Tweaks", "RevertTweaks", "DiskCheck")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path $PSScriptRoot -Parent
$LogsDir = Join-Path $RootDir "Logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
$LogFile = Join-Path $LogsDir "apps.log"

# Detalle completo: solo al archivo de log, no ensucia la consola.
function Write-Detail {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" -Encoding UTF8
}
# Resumen: a la consola Y al log. Solo para hitos importantes.
function Write-Status {
    param([string]$Message)
    Write-Detail $Message
    Write-Host "  $Message"
}

$AppxTargets = @(
    @{ Label = "Cortana";                            AppxPattern = "Microsoft.549981C3F5F10"; WingetId = $null },
    @{ Label = "Xbox Game Bar y servicios de juegos"; AppxPattern = "*xbox*";                  WingetId = "9NZKPSTSNW4P" },
    @{ Label = "Mapas de Windows";                    AppxPattern = "*maps*";                  WingetId = $null },
    @{ Label = "El Tiempo / Noticias";                AppxPattern = "*bingweather*";           WingetId = "9WZDNCRFHVFW" },
    @{ Label = "Centro de Opiniones (Feedback Hub)";  AppxPattern = "*windowsfeedbackhub*";     WingetId = "9NBLGGH4R32N" },
    @{ Label = "Skype";                               AppxPattern = "*skype*";                 WingetId = $null },
    @{ Label = "Solitario (Solitaire Collection)";    AppxPattern = "*solitairecollection*";    WingetId = $null },
    @{ Label = "Contactos (People)";                  AppxPattern = "*people*";                 WingetId = $null },
    @{ Label = "Visor 3D (3D Viewer)";                AppxPattern = "Microsoft.Microsoft3DViewer"; WingetId = $null },
    @{ Label = "Paint 3D";                            AppxPattern = "Microsoft.MSPaint";        WingetId = $null },
    @{ Label = "Sugerencias de Windows (Get Started)"; AppxPattern = "Microsoft.Getstarted";    WingetId = $null },
    @{ Label = "Mi Office (tile)";                    AppxPattern = "Microsoft.MicrosoftOfficeHub"; WingetId = $null },
    @{ Label = "Peliculas y TV";                      AppxPattern = "Microsoft.ZuneVideo";      WingetId = $null },
    @{ Label = "Groove Music";                        AppxPattern = "Microsoft.ZuneMusic";      WingetId = $null }
)

$OptionalWindowsFeatures = @(
    @{ Name = "FaxServicesClientPackage"; Label = "Fax y Escaner de Windows (funcion opcional)" }
)

function Disable-FeatureTarget($f) {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $f.Name -ErrorAction Stop
        if ($feature.State -eq "Disabled") { Write-Detail "[$($f.Label)] Ya estaba deshabilitada."; return }
        Disable-WindowsOptionalFeature -Online -FeatureName $f.Name -NoRestart -ErrorAction Stop | Out-Null
        Write-Detail "[$($f.Label)] Deshabilitada."
    } catch {
        Write-Detail "[$($f.Label)] ERROR al deshabilitar: $($_.Exception.Message)"
    }
}

function Enable-FeatureTarget($f) {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $f.Name -ErrorAction Stop
        if ($feature.State -eq "Enabled") { Write-Detail "[$($f.Label)] Ya estaba habilitada."; return }
        Enable-WindowsOptionalFeature -Online -FeatureName $f.Name -All -NoRestart -ErrorAction Stop | Out-Null
        Write-Detail "[$($f.Label)] Habilitada nuevamente."
    } catch {
        Write-Detail "[$($f.Label)] ERROR al habilitar: $($_.Exception.Message)"
    }
}

function Get-FolderPattern($appxPattern) {
    if ($appxPattern -match '\*') { return $appxPattern }
    return "$appxPattern*"
}

function Uninstall-Target($t) {
    $result = "removed"
    $pkg = Get-AppxPackage $t.AppxPattern -ErrorAction SilentlyContinue
    if ($pkg) {
        try {
            $pkg | Remove-AppxPackage -ErrorAction Stop
            Write-Detail "[$($t.Label)] Removido para el usuario actual."
        } catch {
            if ($_.Exception.Message -match "no se puede desinstalar individualmente") {
                Write-Detail "[$($t.Label)] Omitido: subcomponente protegido por Windows. No afecta funcionalidad."
                $result = "protected"
            } else {
                Write-Detail "[$($t.Label)] ERROR al remover: $($_.Exception.Message)"
                $result = "error"
            }
        }
    } else {
        Write-Detail "[$($t.Label)] No estaba instalado."
        $result = "absent"
    }

    $folderPattern = Get-FolderPattern $t.AppxPattern
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                   Where-Object { $_.PackageName -like $folderPattern }
    if ($provisioned) {
        foreach ($p in $provisioned) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null
                Write-Detail "[$($t.Label)] Paquete provisioned removido ($($p.PackageName))."
            } catch {
                Write-Detail "[$($t.Label)] ERROR al remover provisioned: $($_.Exception.Message)"
            }
        }
    }
    return $result
}

function Install-Target($t) {
    $existing = Get-AppxPackage -AllUsers $t.AppxPattern -ErrorAction SilentlyContinue
    if ($existing) { Write-Detail "[$($t.Label)] Ya esta instalado."; return "already" }

    $folderPattern = Get-FolderPattern $t.AppxPattern
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                   Where-Object { $_.PackageName -like $folderPattern }
    if ($provisioned) {
        foreach ($p in $provisioned) {
            try {
                Add-AppxProvisionedPackage -Online -PackagePath $p.PackagePath -SkipLicense -ErrorAction Stop | Out-Null
                Write-Detail "[$($t.Label)] Reinstalado desde paquete provisioned."
                return "reinstalled"
            } catch { }
        }
    }

    $localFolder = Get-ChildItem "$env:ProgramFiles\WindowsApps" -Directory -Filter $folderPattern -ErrorAction SilentlyContinue |
                   Select-Object -First 1
    if ($localFolder) {
        $manifestPath = Join-Path $localFolder.FullName "AppXManifest.xml"
        if (Test-Path $manifestPath) {
            try {
                Add-AppxPackage -Register $manifestPath -DisableDevelopmentMode -ErrorAction Stop
                Write-Detail "[$($t.Label)] Reinstalado por registro local."
                return "reinstalled"
            } catch { }
        }
    }

    if ($t.WingetId) {
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            try {
                winget install --id $t.WingetId --accept-package-agreements --accept-source-agreements -e
                Write-Detail "[$($t.Label)] Instalado via winget."
                return "reinstalled"
            } catch { }
        }
    }
    Write-Detail "[$($t.Label)] No se pudo reinstalar automaticamente. Instalar manualmente desde Microsoft Store."
    return "manual"
}

function Get-OneDriveSetupPath {
    $setup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    $setup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    if (Test-Path $setup64) { return $setup64 }
    if (Test-Path $setup32) { return $setup32 }
    return $null
}

function Uninstall-OneDrive {
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    $setupPath = Get-OneDriveSetupPath
    if ($setupPath) {
        try {
            Start-Process -FilePath $setupPath -ArgumentList "/uninstall" -Wait -ErrorAction Stop
            Write-Detail "[OneDrive] Desinstalado via $setupPath."
        } catch {
            Write-Detail "[OneDrive] ERROR al desinstalar: $($_.Exception.Message)"
        }
    } else {
        Write-Detail "[OneDrive] OneDriveSetup.exe no encontrado."
    }
    try {
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
        Write-Detail "[OneDrive] Politica aplicada para bloquear reinstalacion automatica."
    } catch {
        Write-Detail "[OneDrive] ERROR al aplicar politica: $($_.Exception.Message)"
    }
}

function Install-OneDrive {
    try {
        if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive") {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -ErrorAction SilentlyContinue
        }
    } catch { }
    $setupPath = Get-OneDriveSetupPath
    if ($setupPath) {
        try {
            Start-Process -FilePath $setupPath -Wait -ErrorAction Stop
            Write-Detail "[OneDrive] Reinstalado."
        } catch {
            Write-Detail "[OneDrive] ERROR al reinstalar: $($_.Exception.Message)"
        }
    } else {
        Write-Detail "[OneDrive] Descargar manualmente desde https://onedrive.live.com/about/download/"
    }
}

# ============================================================
# Tweaks de registro: Copilot (politica + icono de barra de tareas)
# y Bing/Cortana en el buscador de Inicio. En Windows 10, Copilot
# NO existe como paquete separado desinstalable - esta integrado a
# Explorer. La politica de registro ES el mecanismo completo y
# correcto para desactivarlo, no un parche parcial.
# ============================================================
$RegistryTweaks = @(
    @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCopilotButton"; Value = 0 },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search";   Name = "BingSearchEnabled";     Value = 0 },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search";   Name = "CortanaConsent";        Value = 0 }
)

function Apply-RegistryTweaks {
    $ok = 0
    foreach ($t in $RegistryTweaks) {
        try {
            if (-not (Test-Path $t.Path)) { New-Item -Path $t.Path -Force | Out-Null }
            Set-ItemProperty -Path $t.Path -Name $t.Name -Value $t.Value -Type DWord
            Write-Detail "[Registro] $($t.Path)\$($t.Name) = $($t.Value)"
            $ok++
        } catch {
            Write-Detail "[Registro] ERROR en $($t.Path)\$($t.Name): $($_.Exception.Message)"
        }
    }
    Write-Status "Copilot y Bing/Cortana en busqueda: desactivados ($ok/$($RegistryTweaks.Count) ajustes aplicados). Reiniciar Explorador para ver el icono desaparecer."
}

function Revert-RegistryTweaks {
    foreach ($t in $RegistryTweaks) {
        try {
            Remove-ItemProperty -Path $t.Path -Name $t.Name -ErrorAction SilentlyContinue
            Write-Detail "[Registro] Revertido $($t.Path)\$($t.Name)"
        } catch { }
    }
    Write-Status "Copilot y Bing/Cortana en busqueda: restaurados a su configuracion original."
}

function Test-DiskHealth {
    Write-Detail "----- Diagnostico de discos -----"
    try {
        $trim = fsutil behavior query DisableDeleteNotify
        Write-Status "TRIM: $trim"
    } catch { }
    try {
        Get-PhysicalDisk | ForEach-Object {
            Write-Status "Disco: $($_.FriendlyName) | Tipo: $($_.MediaType) | Salud: $($_.HealthStatus)"
        }
    } catch { }
}

Write-Detail "===== Iniciando accion: $Action ====="
switch ($Action) {
    "Uninstall" {
        $counts = @{ removed=0; protected=0; absent=0; error=0 }
        foreach ($t in $AppxTargets) {
            $r = Uninstall-Target $t
            if ($counts.ContainsKey($r)) { $counts[$r]++ }
        }
        Uninstall-OneDrive
        foreach ($f in $OptionalWindowsFeatures) { Disable-FeatureTarget $f }
        Write-Status "Apps: $($counts.removed) removidas, $($counts.protected) protegidas por Windows (normal, sin riesgo), $($counts.absent) ya no estaban instaladas."
        Write-Status "OneDrive: desinstalado y bloqueado. Fax: deshabilitado."
    }
    "Install" {
        $counts = @{ reinstalled=0; already=0; manual=0 }
        foreach ($t in $AppxTargets) {
            $r = Install-Target $t
            if ($counts.ContainsKey($r)) { $counts[$r]++ }
        }
        Install-OneDrive
        foreach ($f in $OptionalWindowsFeatures) { Enable-FeatureTarget $f }
        Write-Status "Apps: $($counts.reinstalled) reinstaladas, $($counts.already) ya estaban, $($counts.manual) requieren instalacion manual desde la Store."
        Write-Status "OneDrive: restaurado. Fax: habilitado."
    }
    "Tweaks"       { Apply-RegistryTweaks }
    "RevertTweaks" { Revert-RegistryTweaks }
    "DiskCheck"    { Test-DiskHealth }
}
Write-Detail "===== Accion '$Action' finalizada ====="
