<#
.SYNOPSIS
    Launches the AOMEI Backupper process and waits for the backup operation to complete.
.DESCRIPTION
    This script starts the AOMEI Backupper launcher with specific arguments, waits for the backup process to start, and then waits for it to finish. It also attempts to retrieve the exit code of the backup process.
    To do it captures the son process of the launcher, which is the one that performs the actual backup operation.
.NOTES
    Copied from Copilot idea. Not tested.
#>
# Executable path
$exe = "C:\Program Files (x86)\AOMEI\AOMEI Backupper\ABLauncher.exe"

# Arguments
$arguments = "97c17e9b-0c41-466b-bfad-e319dcee6b0f 1 /laucherType:3"

# Lanzar el proceso sin que PowerShell lo interprete
$process = Start-Process -FilePath $exe -ArgumentList $arguments -PassThru

Write-Host "Lanzador iniciado. PID: $($process.Id)"

# Esperar a que aparezca el proceso real de copia
Write-Host "Esperando a que comience la copia..."

$targetProcess = $null
while (-not $targetProcess) {
    $targetProcess = Get-Process -Name "ABEngine" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

Write-Host "Copia iniciada. PID: $($targetProcess.Id)"

# Esperar a que termine la copia
Wait-Process -Id $targetProcess.Id

Write-Host "Copia finalizada."

# Comprobar código de salida si existe
try {
    $exitCode = $targetProcess.ExitCode
    Write-Host "Código de salida: $exitCode"
} catch {
    Write-Host "No se pudo obtener el código de salida."
}
