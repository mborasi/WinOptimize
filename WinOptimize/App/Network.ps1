param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("FastDnsOn", "FastDnsOff", "Status")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$RootDir    = Split-Path $PSScriptRoot -Parent
$LogsDir    = Join-Path $RootDir "Logs"
$ConfigsDir = Join-Path $RootDir "Configs"
if (-not (Test-Path $LogsDir))    { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (-not (Test-Path $ConfigsDir)) { New-Item -ItemType Directory -Path $ConfigsDir -Force | Out-Null }

$LogFile   = Join-Path $LogsDir "network.log"
$StateFile = Join-Path $ConfigsDir "dns_baseline.json"

function Write-Detail {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" -Encoding UTF8
}
function Write-Status {
    param([string]$Message)
    Write-Detail $Message
    Write-Host "  $Message"
}

# Cloudflare: rapido y con buena politica de privacidad publica.
# Se aplica solo a adaptadores activos (Up), no a los desconectados.
$FastDnsServers = @("1.1.1.1", "1.0.0.1")

function Get-ActiveAdapters {
    return Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
}

function Set-FastDns {
    $adapters = Get-ActiveAdapters
    if (-not $adapters) {
        Write-Status "No se detectaron adaptadores de red activos."
        return
    }

    if (-not (Test-Path $StateFile)) {
        $baseline = @{}
        foreach ($a in $adapters) {
            try {
                $current = Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction Stop
                $baseline[$a.ifIndex.ToString()] = @{ Name = $a.Name; Servers = @($current.ServerAddresses) }
            } catch { }
        }
        $baseline | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFile -Encoding UTF8
        Write-Detail "Configuracion de DNS original guardada."
    } else {
        Write-Detail "Ya existe una configuracion de DNS original guardada, no se sobreescribe."
    }

    $ok = 0
    foreach ($a in $adapters) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $FastDnsServers -ErrorAction Stop
            Write-Detail "[$($a.Name)] DNS configurado a $($FastDnsServers -join ', ')."
            $ok++
        } catch {
            Write-Detail "[$($a.Name)] ERROR al configurar DNS: $($_.Exception.Message)"
        }
    }
    Write-Status "DNS rapido (Cloudflare): aplicado en $ok adaptador(es). Requiere reiniciar el navegador o el adaptador para notarlo."
}

function Restore-Dns {
    if (-not (Test-Path $StateFile)) {
        Write-Status "No hay una configuracion de DNS original guardada. Nada que restaurar."
        return
    }
    $baseline = Get-Content $StateFile -Raw | ConvertFrom-Json
    $ok = 0
    foreach ($prop in $baseline.PSObject.Properties) {
        $ifIndex = $prop.Name
        $entry = $prop.Value
        try {
            if ($entry.Servers -and $entry.Servers.Count -gt 0) {
                Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $entry.Servers -ErrorAction Stop
            } else {
                Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ResetServerAddresses -ErrorAction Stop
            }
            Write-Detail "[$($entry.Name)] DNS restaurado."
            $ok++
        } catch {
            Write-Detail "[$($entry.Name)] ERROR al restaurar DNS: $($_.Exception.Message)"
        }
    }
    Write-Status "DNS: $ok adaptador(es) restaurados a su configuracion original."
    Remove-Item $StateFile -Force -ErrorAction SilentlyContinue
}

function Show-Status {
    $adapters = Get-ActiveAdapters
    foreach ($a in $adapters) {
        try {
            $dns = Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction Stop
            Write-Status "[$($a.Name)] DNS actual: $($dns.ServerAddresses -join ', ')"
        } catch { }
    }
}

Write-Detail "===== Iniciando accion: $Action ====="
switch ($Action) {
    "FastDnsOn"  { Set-FastDns }
    "FastDnsOff" { Restore-Dns }
    "Status"     { Show-Status }
}
Write-Detail "===== Accion '$Action' finalizada ====="
