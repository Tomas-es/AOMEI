<#
.SYNOPSIS
    Invokes the AOMEI Backupper process and monitors its logs to determine the 
    result of the backup operation.
.DESCRIPTION
    This script starts the AOMEI Backupper launcher with specific arguments, 
    waits for the backup process to start and finish, and then analyzes the most
    recent log file to determine if the backup was successful or if there were 
    errors.
    The script looks for specific messages in the log to classify the result as 
    OK, ERROR, or INDETERMINADO.
    Exits with code:
    0: Backup completed successfully (OK).
    1: Backup completed with errors (ERROR).
    2: Backup completed but log date is before script start date.
    3: Backup completed but log ID does not match the current copy ID.
    .DEPENDENCIES
    This script depends on the BackupTools module for log analysis functions.
.NOTES
    Copied from Copilot idea. Not tested.
    ABEengine.exe is usually the process that performs the actual backup, but it 
    may vary on version or configuration. Confirm the process name if necessary.
    You can customize to follow other processes.
    Encoded in UTF-8 with BOM to ensure proper character encodign in elevated 
    PowerShell conoles.
    This encoding is important too to work with AzCopy and Azure Storage.
    
#>
# PARAMETERS AND CONFIGURATION
#################################################################################
param(
    [string]$LauncherPath = "C:\Program Files (x86)\AOMEI\AOMEI Backupper\ABLauncher.exe",
    [string]$CopyID = "97c17e9b-0c41-466b-bfad-e319dcee6b0f",
     # Task Type: 0 (Full Backup) 1 (Incremental Backup)
    [int]$TaskType = 1,
    [string]$EngineProcessName = "ABCore",   # Change if your process is different
    [string]$LogPath = "C:\ProgramData\AomeiBR\brlog.xml"
)
$LauncherPath = "C:\Program Files (x86)\AOMEI\AOMEI Backupper\ABLauncher.exe"
<# 
    Arguments example: 
    Copy ID: 97c17e9b-0c41-466b-bfad-e319dcee6b0f
    Task Type: 0 (Full Backup) 1 (Incremental Backup)
    Launcher Type: 3 (From desktop link)
#>

<#
    Testing values:
    $CopyID = "97c17e9b-0c41-466b-bfad-e319dcee6b0f"
    $TaskType = 1 # Change to 1 for Incrementla Backup
    #$EngineProcessName = "ABEngine"   # Cambiar si tu proceso es otro
    $EngineProcessName = "ABCore"   # Cambiar si tu proceso es otro
    $LogPath = "C:\ProgramData\AomeiBR\brlog.xml"
#>

$Arguments = "$CopyID $TaskType /laucherType:3"
$ScriptStart = Get-Date

# Module with log analysis functions
# Test module path and import
$modulePath = ".\BackupTools\BackupTools.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "BackupTools module imported successfully."
} else {
    Write-Host "ERROR: BackupTools module not found at path: $modulePath"
    return
}

# MAIN EXECUTION
###############################################################################
# EXECUTE LAUNCHER
###############################################################################
Write-Host "Starting AOMEI backup task..."

$launcher = Start-Process -FilePath $LauncherPath -ArgumentList $Arguments -PassThru
Write-Host "Launcher started. PID: $($launcher.Id)"


# WAIT FOR THE BACKUP TO START
###############################################################################
Write-Host "Waiting for the backup engine ($EngineProcessName.exe) to start..."

$engine = $null
while (-not $engine) {
    $engine = Get-Process -Name $EngineProcessName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

Write-Host "Backup engine started. PID: $($engine.Id)"

# WAIT FOR THE BACKUP TO COMPLETE
###############################################################################
Write-Host "Waiting for the backup to complete..."
<#
    Wait-Process needs elevated permissions to wait for the AOMEI process.
    Run this script as administrator or use a loop with Get-Process and
    Start-Sleep to check for process existence.
Wait-Process -Id $engine.Id
#>
while (Get-Process -Id $engine.Id -ErrorAction SilentlyContinue) {
    Start-Sleep -Seconds 1
    <#
        TODO: Add a timeout to avoid infinite loops in case of issues.
        Show an ongoing status message or spinner to indicate that the script 
        is still running.
    #>
}

Write-Host "Backup completed."


# READ THE LAST LOG
###############################################################################
Write-Host "Analyzing logs..."

# TODO: The log file is an xml. We should parse it as xml and look for specific 
# nodes or attributes instead of doing a raw text search.
# Get the most recent log file from the AOMEI logs directory

# Test log file existence
if (-not (Test-Path -Path $LogPath)) {
    Write-Host "ERROR: Log file not found at path: $LogPath"
    exit 1
}
# Load XML
[xml]$BRLog = Get-Content -Path $LogPath

# Convertir epoch a DateTime
$LogEpoch = [int64]$BRLog.BRLog.LastChild.Time
$LogDate = [DateTimeOffset]::FromUnixTimeSeconds($LogEpoch).ToLocalTime().DateTime

Write-Host "Script start date: $ScriptStart"
Write-Host "Log date:       $LogDate"

# Extraer ID del log
$LogID = $BRLog.BRLog.LastChild.ID.Trim("{}")

Write-Host "Script CopyID:       $CopyID"
Write-Host "Log CopyID:          $LogID"

# Date and ID check
$dateResult = Test-BackupDate -ScriptStart $ScriptStart -LogXml $BRLog
$idResult = Test-BackupID -CopyID $CopyID -LogXml $BRLog
Write-Host "Date result: $dateResult"
Write-Host "ID result: $idResult"
if ($dateResult.IsDateValid -and $idResult.IsIDValid) {
    Write-Host "✔ The log corresponds to this execution based on both date and ID."
    exit 0
} else {
    Write-Host "✘ The log does not correspond to this execution."
    if (-not $dateResult.IsDateValid) {
        Write-Host "  - The log date ($($dateResult.LogDate)) is older than the script start time ($ScriptStart)."
        exit 2
    }
    if (-not $idResult.IsIDValid) {
        Write-Host "  - The log ID ($($idResult.LogID)) does not match the current copy ID ($CopyID)."
        exit 3
    }
}
