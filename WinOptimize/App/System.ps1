param(
    [string]$Lang = "ES"
)

function Get-DiskTypeLabel($disk) {
    $type = $disk.MediaType
    if ($type -eq "SSD" -and $disk.BusType -eq "NVMe") { return "NVMe" }
    if ($type -eq "Unspecified" -and $disk.SpindleSpeed -gt 0) { return "HDD" }
    if ($type -eq "Unspecified" -and $disk.SpindleSpeed -eq 0) { return "SSD" }
    if ($type -eq "Unspecified") { return "Desconocido" }
    return $type
}

function Show-SystemInfo {
    param([string]$Lang)
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        $sysDrive = $env:SystemDrive.TrimEnd(':')
        $fs = (Get-Volume -DriveLetter $sysDrive -ErrorAction SilentlyContinue).FileSystem
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
            $label = Get-DiskTypeLabel $_
            "$($_.FriendlyName) ($label, $([math]::Round($_.Size / 1GB, 0)) GB)"
        }

        if ($Lang -eq "EN") {
            Write-Host "  OS: $($os.Caption) | Build $($os.BuildNumber) | $($os.OSArchitecture)"
            Write-Host "  File system (system drive): $fs"
            Write-Host "  RAM: $ramGB GB"
            Write-Host "  GPU: $($gpus -join ', ')"
            Write-Host "  Disks:"
            foreach ($d in $disks) { Write-Host "    - $d" }
        } else {
            Write-Host "  Windows: $($os.Caption) | Compilacion $($os.BuildNumber) | $($os.OSArchitecture)"
            Write-Host "  Sistema de archivos (disco del sistema): $fs"
            Write-Host "  RAM: $ramGB GB"
            Write-Host "  GPU: $($gpus -join ', ')"
            Write-Host "  Discos:"
            foreach ($d in $disks) { Write-Host "    - $d" }
        }
    } catch {
        if ($Lang -eq "EN") {
            Write-Host "  Could not read full system info: $($_.Exception.Message)"
        } else {
            Write-Host "  No se pudo leer la info completa del sistema: $($_.Exception.Message)"
        }
    }
}

Show-SystemInfo -Lang $Lang
