function Test-BackupDate {
<#
.SYNOPSIS
    Tests if the log date is valid (not before the script start date).
.DESCRIPTION
    Compares the timestamp of a backup log file with the start time of a backup
    operation. This is used to determine if the log could correspond to the 
    current backup or if it belongs to a previous backup.
.PARAMETER ScriptStart
    The start time of the backup script execution. This should be passed from the
    main script to ensure consistency.
    This parameter is obligatory to perform the date comparison.
.PARAMETER LogXml
    The XML content of the backup log file. This should be loaded and passed from
    the main script to avoid redundant file access.
.OUTPUT
    An object containing:
    - LogDate: The date extracted from the log.
    - IsDateValid: A boolean indicating if the log date is greater than or equal
      to the script start date.
#>
    param(
        [parameter(mandatory=$true)]
        [datetime]$ScriptStart,
        [parameter(mandatory=$true)]
        [xml]$LogXml
    )

    $LogEpoch = [int64]$LogXml.BRLog.LastChild.Time
    $LogDate  = [DateTimeOffset]::FromUnixTimeSeconds($LogEpoch).ToLocalTime().DateTime

    [pscustomobject]@{
        LogDate      = $LogDate
        IsDateValid  = $LogDate -ge $ScriptStart
    }
}

function Test-BackupID {
<#
.SYNOPSIS
    Tests if the log ID matches the expected copy ID.
.DESCRIPTION
    Compares the ID of a backup log file with the expected copy ID to determine
    if the log corresponds to the current backup operation.
.PARAMETER CopyID
    The expected copy ID for the backup operation.
.PARAMETER LogXml
    The XML content of the backup log file. This should be loaded and passed from
    the main script to avoid redundant file access.
.OUTPUT
    An object containing:
    - LogID: The ID extracted from the log.
    - IsIDValid: A boolean indicating if the log ID matches the expected copy ID.
#>
    param(
        [parameter(mandatory=$true)]
        [string]$CopyID,
        [parameter(mandatory=$true)]
        [xml]$LogXml
    )
    # Just for debugging
    if (-not $LogXml) {
    throw "LogXml parameter is null. The log file was not loaded correctly."
    }

    Write-Host "Test CopyID param:       $CopyID"
    Write-Host "Test LogXml param:       $LogXml"

    $LogID = $LogXml.BRLog.LastChild.ID.Trim('{}')

    Write-Host "Test LogID extracted:    $LogID"

    [pscustomobject]@{
        LogID     = $LogID
        IsIDValid = $LogID -eq $CopyID
    }
}

# This tell PoserShell which functions are public.
Export-ModuleMember -Function Test-BackupDate, Test-BackupID

