<#
.SYNOPSIS
    This script is an example of how to compare the timestamp of a backup log 
    file with the start time of a backup operation.
.DESCRIPTION
    Compares the timestamp of a backup log file with the start time of a backup 
    operation.
    Exits with code 0 if the log corresponds to the current backup, or 1 if it 
    belongs to a previous backup.
.NOTES
    Copied from Copilot idea. Not tested.
#>
# Save the start time of the script
# This should be done by the main script and passed as a parameter to this log
# analysis script.
$ScriptStart = Get-Date

# ... Here the main script or you call this one from it ...

# Get the most recent log file from the AOMEI logs directory
$BRLogPath = "C:\ProgramData\AomeiBR\brlog.xml"

# Load XML
[xml]$BRLog = Get-Content -Path $BRLogPath

# Convertir epoch a DateTime
$LogEpoch = [int64]$BRLog.BRLog.LastChild.Time
$LogDate = [DateTimeOffset]::FromUnixTimeSeconds($LogEpoch).ToLocalTime().DateTime

Write-Host "Fecha inicio script: $ScriptStart"
Write-Host "Fecha del log:       $LogDate"

# Comparación
if ($LogDate -ge $ScriptStart) {
    Write-Host "✔ El log corresponde a esta ejecución."
    exit 0
} else {
    Write-Host "✘ El log pertenece a una copia anterior."
    exit 1
}
