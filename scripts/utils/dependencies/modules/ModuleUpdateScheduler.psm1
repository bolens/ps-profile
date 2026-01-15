<#
scripts/utils/dependencies/modules/ModuleUpdateScheduler.psm1

.SYNOPSIS
    Module update scheduling utilities.

.DESCRIPTION
    Provides functions for managing Windows Scheduled Tasks for automatic module updates.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe schedule frequency handling.
#>

# Import CommonEnums for UpdateFrequency enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import ExitCodes for ExitCode enum
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and (Test-Path -LiteralPath $moduleImportPath)) {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
}

<#
.SYNOPSIS
    Creates or updates a Windows Scheduled Task for automatic module updates.

.DESCRIPTION
    Creates a scheduled task that runs the module update script at the specified frequency.

.PARAMETER ScheduledTaskName
    Name of the scheduled task.

.PARAMETER RepoRoot
    Repository root directory path.

.PARAMETER ScheduleFrequency
    Frequency for scheduled updates. Must be an UpdateFrequency enum value.

.PARAMETER ScheduleTime
    Time to run scheduled updates (HH:mm format, 24-hour).

.PARAMETER ScheduleDays
    Days of week for Weekly schedule (e.g., Monday,Wednesday,Friday).

.PARAMETER ScheduleDayOfMonth
    Day of month for Monthly schedule (1-31).

.PARAMETER TrackHistory
    Whether to track update history.

.PARAMETER EmailTo
    Email addresses to send notifications to.

.PARAMETER EmailFrom
    Email address to send notifications from.

.PARAMETER EmailSmtpServer
    SMTP server address.

.PARAMETER EmailSmtpPort
    SMTP server port.

.PARAMETER EmailOnlyOnUpdates
    Whether to only send email when updates are available.
#>
function Register-UpdateSchedule {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScheduledTaskName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot,

        [Parameter(Mandatory)]
        [UpdateFrequency]$ScheduleFrequency,

        [ValidatePattern('^\d{2}:\d{2}$')]
        [string]$ScheduleTime = "02:00",

        [string[]]$ScheduleDays = @(),

        [ValidateRange(1, 31)]
        [int]$ScheduleDayOfMonth = 1,

        [switch]$TrackHistory,

        [string[]]$EmailTo = @(),

        [string]$EmailFrom = $null,

        [string]$EmailSmtpServer = "localhost",

        [int]$EmailSmtpPort = 25,

        [switch]$EmailOnlyOnUpdates
    )

    # Convert enum to string
    $scheduleFrequencyString = $ScheduleFrequency.ToString()

    # Validate schedule time format (ValidatePattern handles basic format, but check ranges)
    $timeParts = $ScheduleTime -split ':'
    $hour = [int]$timeParts[0]
    $minute = [int]$timeParts[1]

    if ($hour -lt 0 -or $hour -gt 23 -or $minute -lt 0 -or $minute -gt 59) {
        Write-ScriptMessage -Message "Invalid time: $ScheduleTime. Hour must be 0-23, minute must be 0-59" -IsError
        Exit-WithCode -ExitCode [ExitCode]::SetupError
    }

    try {
        # Get PowerShell executable path
        $pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
    }
    catch {
        Write-ScriptMessage -Message "PowerShell (pwsh) not found. Cannot create scheduled task." -IsError
        Exit-WithCode -ExitCode [ExitCode]::SetupError
    }

    # Build script path
    $scriptPath = Join-Path $RepoRoot 'scripts' 'utils' 'dependencies' 'check-module-updates.ps1'
    if (-not (Test-Path $scriptPath)) {
        Write-ScriptMessage -Message "Script not found at: $scriptPath" -IsError
        Exit-WithCode -ExitCode [ExitCode]::SetupError
    }

    # Build arguments
    $arguments = @(
        "-NoProfile",
        "-File",
        "`"$scriptPath`"",
        "-Update"
    )

    if ($TrackHistory) {
        $arguments += "-TrackHistory"
    }

    if ($EmailTo.Count -gt 0) {
        # Join email addresses with comma for command line
        $emailToArg = $EmailTo -join ','
        $arguments += "-EmailTo"
        $arguments += $emailToArg
        if ($EmailFrom) {
            $arguments += "-EmailFrom"
            $arguments += $EmailFrom
            $arguments += "-EmailSmtpServer"
            $arguments += $EmailSmtpServer
            $arguments += "-EmailSmtpPort"
            $arguments += $EmailSmtpPort.ToString()
        }
        if ($EmailOnlyOnUpdates) {
            $arguments += "-EmailOnlyOnUpdates"
        }
    }

    $action = New-ScheduledTaskAction -Execute $pwshPath -Argument ($arguments -join ' ')

    # Create trigger based on frequency
    $trigger = $null
    switch ($scheduleFrequencyString) {
        'Daily' {
            $trigger = New-ScheduledTaskTrigger -Daily -At $ScheduleTime
        }
        'Weekly' {
            if ($ScheduleDays.Count -eq 0) {
                Write-ScriptMessage -Message "ScheduleDays is required for Weekly frequency" -IsError
                Exit-WithCode -ExitCode [ExitCode]::SetupError
            }
            $daysOfWeek = $ScheduleDays | ForEach-Object {
                [System.DayOfWeek]::Parse($_, $true)
            }
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $daysOfWeek -At $ScheduleTime
        }
        'Monthly' {
            if ($ScheduleDayOfMonth -lt 1 -or $ScheduleDayOfMonth -gt 31) {
                Write-ScriptMessage -Message "ScheduleDayOfMonth must be between 1 and 31" -IsError
                Exit-WithCode -ExitCode [ExitCode]::SetupError
            }
            $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek ([System.DayOfWeek]::Sunday) -At $ScheduleTime
            # Note: Monthly triggers are complex in Task Scheduler. This is a simplified approach.
            Write-ScriptMessage -Message "Monthly scheduling uses a 4-week interval. For exact monthly, consider using Daily with a custom condition." -IsWarning
        }
    }

    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-ScriptMessage -Message "Updating existing scheduled task: $ScheduledTaskName"
        Set-ScheduledTask -TaskName $ScheduledTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    }
    else {
        Write-ScriptMessage -Message "Creating scheduled task: $ScheduledTaskName"
        Register-ScheduledTask -TaskName $ScheduledTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatically checks and updates PowerShell modules" | Out-Null
    }

        Write-ScriptMessage -Message "Scheduled task configured: $scheduleFrequencyString at $ScheduleTime" -LogLevel Info
}

<#
.SYNOPSIS
    Removes the scheduled task for module updates.

.PARAMETER ScheduledTaskName
    Name of the scheduled task to remove.
#>
function Remove-UpdateSchedule {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$ScheduledTaskName
    )

    try {
        $task = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction Stop
        Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
        Write-ScriptMessage -Message "Removed scheduled task: $ScheduledTaskName" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Scheduled task not found or could not be removed: $($_.Exception.Message)" -IsWarning
    }
}

Export-ModuleMember -Function @(
    'Register-UpdateSchedule',
    'Remove-UpdateSchedule'
)

