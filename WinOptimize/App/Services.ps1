param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("DisableSafe", "DisableExtended", "Restore", "Status", "UacOn", "UacOff")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$RootDir    = Split-Path $PSScriptRoot -Parent
$LogsDir    = Join-Path $RootDir "Logs"
$ConfigsDir = Join-Path $RootDir "Configs"
if (-not (Test-Path $LogsDir))    { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (-not (Test-Path $ConfigsDir)) { New-Item -ItemType Directory -Path $ConfigsDir -Force | Out-Null }

$LogFile   = Join-Path $LogsDir "services.log"
$StateFile = Join-Path $ConfigsDir "services_baseline.json"

$LegacyStateFile = Join-Path $RootDir "Optimizar_Servicios_estado_original.json"
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

$ProtectedServices = @(
    @{ Name = "Spooler";               Label = "Cola de impresion (Print Spooler)" },
    @{ Name = "LanmanServer";          Label = "Servidor (uso compartido de archivos/impresoras)" },
    @{ Name = "LanmanWorkstation";     Label = "Estacion de trabajo (acceso a recursos compartidos)" },
    @{ Name = "SSDPSRV";               Label = "Descubrimiento SSDP" },
    @{ Name = "FDResPub";              Label = "Publicacion de recursos de deteccion de funcion" },
    @{ Name = "fdPHost";               Label = "Host de proveedor de deteccion de funcion" },
    @{ Name = "upnphost";              Label = "Host de dispositivo Plug and Play universal" },
    @{ Name = "mpssvc";                Label = "Firewall de Windows" },
    @{ Name = "WinDefend";             Label = "Windows Defender Antivirus" },
    @{ Name = "WdNisSvc";              Label = "Windows Defender Network Inspection" },
    @{ Name = "SecurityHealthService"; Label = "Windows Security" },
    @{ Name = "wuauserv";              Label = "Windows Update" },
    @{ Name = "BITS";                  Label = "Transferencia inteligente en segundo plano" },
    @{ Name = "UsoSvc";                Label = "Orquestador de actualizaciones" },
    @{ Name = "DoSvc";                 Label = "Optimizacion de entrega" },
    @{ Name = "Audiosrv";              Label = "Audio de Windows" },
    @{ Name = "AudioEndpointBuilder";  Label = "Generador de extremos de audio" }
)

$SafeServices = @(
    @{ Name = "DiagTrack";         Label = "Telemetria (Connected User Experiences)" },
    @{ Name = "dmwappushservice";  Label = "Enrutamiento de mensajes WAP Push" },
    @{ Name = "RemoteRegistry";    Label = "Registro remoto" },
    @{ Name = "MapsBroker";        Label = "Administrador de mapas descargados" },
    @{ Name = "Fax";               Label = "Servicio de Fax" },
    @{ Name = "RetailDemo";        Label = "Demo de venta minorista" },
    @{ Name = "PcaSvc";            Label = "Asistente de compatibilidad de programas" },
    @{ Name = "WerSvc";            Label = "Informe de errores de Windows" },
    @{ Name = "WdiServiceHost";    Label = "Host de servicio de diagnostico" },
    @{ Name = "WdiSystemHost";     Label = "Host de sistema de diagnostico" },
    @{ Name = "DPS";               Label = "Directivas de diagnostico" }
)

$OptionalServices = @(
    @{ Name = "WSearch";       Label = "Busqueda de Windows";                        Warning = "Rompe la busqueda instantanea en Explorador/Inicio." },
    @{ Name = "SysMain";       Label = "SysMain / Superfetch";                       Warning = "Efecto variable segun hardware." },
    @{ Name = "WMPNetworkSvc"; Label = "Uso compartido de red de Windows Media";     Warning = "Rompe DLNA a Smart TV si lo usas." },
    @{ Name = "WbioSrvc";      Label = "Servicio biometrico";                        Warning = "Rompe login con huella/reconocimiento facial." }
)

function Get-AllManaged { return $SafeServices + $OptionalServices }

function Save-BaselineIfNeeded {
    if (Test-Path $StateFile) {
        Write-Detail "Snapshot de estado original ya existe (no se sobreescribe): $StateFile"
        return
    }
    $baseline = @{}
    foreach ($t in (Get-AllManaged)) {
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='$($t.Name)'" -ErrorAction Stop
            $baseline[$t.Name] = $svc.StartMode
        } catch {
            $baseline[$t.Name] = "Unknown"
        }
    }
    $baseline | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
    Write-Detail "Snapshot de estado original guardado en $StateFile"
}

function Set-ServiceDisabled($t) {
    try {
        $svc = Get-CimInstance Win32_Service -Filter "Name='$($t.Name)'" -ErrorAction Stop
        Write-Detail "[$($t.Label)] Estado previo: $($svc.StartMode) / $($svc.State)"
        Set-Service -Name $t.Name -StartupType Disabled -ErrorAction Stop
        Stop-Service -Name $t.Name -Force -ErrorAction SilentlyContinue
        Write-Detail "[$($t.Label)] Desactivado."
        return $true
    } catch {
        Write-Detail "[$($t.Label)] ERROR al desactivar: $($_.Exception.Message)"
        return $false
    }
}

function Restore-AllServices {
    if (-not (Test-Path $StateFile)) {
        Write-Status "No existe snapshot. No hay nada que restaurar todavia."
        return
    }
    $baseline = Get-Content $StateFile -Raw | ConvertFrom-Json
    $ok = 0; $total = 0
    foreach ($prop in $baseline.PSObject.Properties) {
        $total++
        $name = $prop.Name
        $mode = $prop.Value
        $startupType = switch ($mode) {
            "Auto"     { "Automatic" }
            "Manual"   { "Manual" }
            "Disabled" { "Disabled" }
            default    { $null }
        }
        if (-not $startupType) {
            Write-Detail "[$name] Modo original desconocido, se omite."
            continue
        }
        try {
            Set-Service -Name $name -StartupType $startupType -ErrorAction Stop
            if ($startupType -ne "Disabled") { Start-Service -Name $name -ErrorAction SilentlyContinue }
            Write-Detail "[$name] Restaurado a $startupType."
            $ok++
        } catch {
            Write-Detail "[$name] ERROR al restaurar: $($_.Exception.Message)"
        }
    }
    Write-Status "Servicios: $ok/$total restaurados a su estado original real."
}

function Show-Status {
    Write-Status "----- Servicios protegidos -----"
    foreach ($t in $ProtectedServices) {
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='$($t.Name)'" -ErrorAction Stop
            Write-Status "[PROTEGIDO] $($t.Label): $($svc.StartMode) / $($svc.State)"
        } catch {
            Write-Status "[PROTEGIDO] $($t.Label): no encontrado."
        }
    }
    Write-Status "----- Servicios gestionados -----"
    foreach ($t in (Get-AllManaged)) {
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='$($t.Name)'" -ErrorAction Stop
            Write-Status "$($t.Label): $($svc.StartMode) / $($svc.State)"
        } catch {
            Write-Status "$($t.Label): no encontrado."
        }
    }
    try {
        $uac = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -ErrorAction Stop
        Write-Status "UAC: $(if ($uac.EnableLUA -eq 1) { 'ACTIVADO' } else { 'DESACTIVADO' })"
    } catch {
        Write-Status "UAC: no se pudo leer."
    }
}

function Set-Uac($enabled) {
    $value = if ($enabled) { 1 } else { 0 }
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value $value -Type DWord
        Write-Status "UAC: $(if ($enabled) {'ACTIVADO'} else {'DESACTIVADO'}). Requiere REINICIO."
    } catch {
        Write-Status "ERROR al cambiar UAC: $($_.Exception.Message)"
    }
}

Write-Detail "===== Iniciando accion: $Action ====="
switch ($Action) {
    "DisableSafe" {
        Save-BaselineIfNeeded
        $ok = 0
        foreach ($t in $SafeServices) { if (Set-ServiceDisabled $t) { $ok++ } }
        Write-Status "Servicios de telemetria/diagnostico: $ok/$($SafeServices.Count) desactivados."
    }
    "DisableExtended" {
        Save-BaselineIfNeeded
        $ok = 0
        foreach ($t in $SafeServices) { if (Set-ServiceDisabled $t) { $ok++ } }
        foreach ($t in $OptionalServices) { if (Set-ServiceDisabled $t) { $ok++ } }
        Write-Status "Servicios (incluye extendidos): $ok/$($SafeServices.Count + $OptionalServices.Count) desactivados."
    }
    "Restore" { Restore-AllServices }
    "Status"  { Show-Status }
    "UacOn"   { Set-Uac $true }
    "UacOff"  { Set-Uac $false }
}
Write-Detail "===== Accion '$Action' finalizada ====="
