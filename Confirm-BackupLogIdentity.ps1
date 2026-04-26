<#
.SYNOPSIS
     This script is an example of how to comfirm tha the most recent backup log
     corresponds to the current backup operation by comparing the copy ID.
    This script is an example of how to comfirm tha the most recent backup log
    corresponds to the current backup operation by comparing the copy ID.
.DESCRIPTION
    Compares the copy ID of the most recent backup log with the copy ID of the
.NOTES
    Copied from Copilot idea. Not tested.
    
#>

# CopyID from the actual copy
# It should be obtained from the main script and passed as a parameter to this log
# analysis script.
$CopyID = "97c17e9b-0c41-466b-bfad-e319dcee6b0f"

# ... Here goes your backup execution or you call this one from ...

# Get the most recent log file from the AOMEI logs directory
$BRLogPath = "C:\ProgramData\AomeiBR\brlog.xml"

# Load XML
[xml]$BRLog = Get-Content -Path $BRLogPath

# Extraer ID del log
$LogID = $BRLog.BRLog.LastChild.ID.Trim("{}")

Write-Host "CopyID script:       $CopyID"
Write-Host "CopyID log:          $LogID"


# ID check
if ($LogID -eq $CopyID) {
    Write-Host "✔ The log ID corresponds exactly to this execution."
    exit 0
} else {
    Write-Host "✘ The log ID does not match the current copy operation."
    exit 1
}
