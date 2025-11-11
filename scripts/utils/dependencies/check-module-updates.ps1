<#
scripts/utils/dependencies/check-module-updates.ps1

.SYNOPSIS
    Checks for available updates to PowerShell modules.

.DESCRIPTION
    Checks for available updates to PowerShell modules in the Modules directory and other
    commonly used modules like PSScriptAnalyzer, Pester, and PowerShell-Beautifier. Compares
    installed versions with latest versions available in the PowerShell Gallery.

    Supports scheduling automatic updates, email notifications, and update history tracking.

.PARAMETER Update
    If specified, automatically updates all modules that have available updates. Otherwise,
    only reports available updates without installing them.

.PARAMETER DryRun
    If specified, shows what would be updated without actually installing updates.

.PARAMETER ModuleFilter
    Array of module names to check. If not specified, checks all configured modules.

.PARAMETER ReportFile
    Path to save the update report JSON file. If not specified and -Update is used, saves to scripts/data/.

.PARAMETER Schedule
    If specified, creates or updates a Windows Scheduled Task to run this script automatically.
    Requires -ScheduleFrequency and optionally -ScheduleTime.

.PARAMETER ScheduleFrequency
    Frequency for scheduled updates: Daily, Weekly, or Monthly. Required when using -Schedule.

.PARAMETER ScheduleTime
    Time to run scheduled updates (HH:mm format, 24-hour). Defaults to 02:00 if not specified.

.PARAMETER ScheduleDays
    Days of week for Weekly schedule (e.g., Monday,Wednesday,Friday). Comma-separated.

.PARAMETER ScheduleDayOfMonth
    Day of month for Monthly schedule (1-31). Defaults to 1.

.PARAMETER RemoveSchedule
    If specified, removes the scheduled task instead of creating/updating it.

.PARAMETER EmailTo
    Email address(es) to send notifications to. Comma-separated for multiple recipients.

.PARAMETER EmailFrom
    Email address to send notifications from. Required if -EmailTo is specified.

.PARAMETER EmailSmtpServer
    SMTP server address. Defaults to localhost if not specified.

.PARAMETER EmailSmtpPort
    SMTP server port. Defaults to 25 if not specified.

.PARAMETER EmailSmtpCredential
    Credential for SMTP authentication. Optional.

.PARAMETER EmailOnlyOnUpdates
    If specified, only sends email when updates are available. Otherwise sends email for all runs.

.PARAMETER TrackHistory
    If specified, saves update history to scripts/data/module-update-history.json.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1

    Checks for available module updates and displays them.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1 -Update

    Checks for updates and automatically installs them.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1 -ReportFile updates.json

    Checks for updates and saves report to updates.json.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1 -Schedule -ScheduleFrequency Daily -ScheduleTime "03:00" -Update

    Schedules daily automatic updates at 3:00 AM.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1 -EmailTo "admin@example.com" -EmailFrom "noreply@example.com" -EmailSmtpServer "smtp.example.com" -EmailOnlyOnUpdates

    Sends email notifications only when updates are available.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1 -Update -TrackHistory

    Updates modules and saves history to track update records.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\dependencies\check-module-updates.ps1 -RemoveSchedule

    Removes the scheduled task.

.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): Check completed successfully
    - 2 (EXIT_SETUP_ERROR): Error accessing PowerShell Gallery or module installation failed

    Modules checked:
    - Local modules in Modules/ directory
    - PSScriptAnalyzer
    - Pester
    - PowerShell-Beautifier

    Requires access to PowerShell Gallery. Network connectivity may be required.
    Scheduling requires administrator privileges on Windows.
#>

param(
    [switch]$Update,

    [switch]$DryRun,

    [string[]]$ModuleFilter = @(),

    [string]$ReportFile = $null,

    [switch]$Schedule,

    [ValidateSet('Daily', 'Weekly', 'Monthly')]
    [string]$ScheduleFrequency = $null,

    [string]$ScheduleTime = "02:00",

    [string[]]$ScheduleDays = @(),

    [int]$ScheduleDayOfMonth = 1,

    [switch]$RemoveSchedule,

    [string[]]$EmailTo = @(),

    [string]$EmailFrom = $null,

    [string]$EmailSmtpServer = "localhost",

    [int]$EmailSmtpPort = 25,

    [System.Management.Automation.PSCredential]$EmailSmtpCredential = $null,

    [switch]$EmailOnlyOnUpdates,

    [switch]$TrackHistory
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Get repository root and modules directory
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $localModulesPath = Join-Path $repoRoot 'Modules'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Scheduled task name
$scheduledTaskName = "PowerShell-Module-Updates"

<#
.SYNOPSIS
    Creates or updates a Windows Scheduled Task for automatic module updates.

.DESCRIPTION
    Creates a scheduled task that runs this script with the -Update parameter at the specified frequency.
#>
function Register-UpdateSchedule {
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if (-not $ScheduleFrequency) {
        Write-ScriptMessage -Message "ScheduleFrequency is required when using -Schedule" -IsError
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
    }

    # Validate schedule time format
    if ($ScheduleTime -notmatch '^\d{2}:\d{2}$') {
        Write-ScriptMessage -Message "ScheduleTime must be in HH:mm format (e.g., 02:00)" -IsError
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
    }

    $timeParts = $ScheduleTime -split ':'
    $hour = [int]$timeParts[0]
    $minute = [int]$timeParts[1]

    if ($hour -lt 0 -or $hour -gt 23 -or $minute -lt 0 -or $minute -gt 59) {
        Write-ScriptMessage -Message "Invalid time: $ScheduleTime. Hour must be 0-23, minute must be 0-59" -IsError
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
    }

    try {
        # Get PowerShell executable path
        $pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
    }
    catch {
        Write-ScriptMessage -Message "PowerShell (pwsh) not found. Cannot create scheduled task." -IsError
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
    }

    # Build script path
    $scriptPath = Join-Path $repoRoot 'scripts' 'utils' 'dependencies' 'check-module-updates.ps1'
    if (-not (Test-Path $scriptPath)) {
        Write-ScriptMessage -Message "Script not found at: $scriptPath" -IsError
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
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
    switch ($ScheduleFrequency) {
        'Daily' {
            $trigger = New-ScheduledTaskTrigger -Daily -At $ScheduleTime
        }
        'Weekly' {
            if ($ScheduleDays.Count -eq 0) {
                Write-ScriptMessage -Message "ScheduleDays is required for Weekly frequency" -IsError
                Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
            }
            $daysOfWeek = $ScheduleDays | ForEach-Object {
                [System.DayOfWeek]::Parse($_, $true)
            }
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $daysOfWeek -At $ScheduleTime
        }
        'Monthly' {
            if ($ScheduleDayOfMonth -lt 1 -or $ScheduleDayOfMonth -gt 31) {
                Write-ScriptMessage -Message "ScheduleDayOfMonth must be between 1 and 31" -IsError
                Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
            }
            $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek ([System.DayOfWeek]::Sunday) -At $ScheduleTime
            # Note: Monthly triggers are complex in Task Scheduler. This is a simplified approach.
            Write-ScriptMessage -Message "Monthly scheduling uses a 4-week interval. For exact monthly, consider using Daily with a custom condition." -IsWarning
        }
    }

    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $scheduledTaskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-ScriptMessage -Message "Updating existing scheduled task: $scheduledTaskName"
        Set-ScheduledTask -TaskName $scheduledTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    }
    else {
        Write-ScriptMessage -Message "Creating scheduled task: $scheduledTaskName"
        Register-ScheduledTask -TaskName $scheduledTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatically checks and updates PowerShell modules" | Out-Null
    }

    Write-ScriptMessage -Message "Scheduled task configured: $ScheduleFrequency at $ScheduleTime" -LogLevel Info
}

<#
.SYNOPSIS
    Removes the scheduled task for module updates.
#>
function Remove-UpdateSchedule {
    [CmdletBinding()]
    [OutputType([void])]
    param()

    try {
        $task = Get-ScheduledTask -TaskName $scheduledTaskName -ErrorAction Stop
        Unregister-ScheduledTask -TaskName $scheduledTaskName -Confirm:$false
        Write-ScriptMessage -Message "Removed scheduled task: $scheduledTaskName" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Scheduled task not found or could not be removed: $($_.Exception.Message)" -IsWarning
    }
}

<#
.SYNOPSIS
    Sends email notification about module updates.

.DESCRIPTION
    Sends an email notification with update information. Can be configured to only send when updates are available.
#>
function Send-UpdateNotification {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ReportData,
        
        [Parameter(Mandatory)]
        [bool]$UpdatesAvailable
    )

    if ($EmailTo.Count -eq 0) {
        return
    }

    if (-not $EmailFrom) {
        Write-ScriptMessage -Message "EmailFrom is required when using EmailTo" -IsWarning
        return
    }

    if ($EmailOnlyOnUpdates -and -not $UpdatesAvailable) {
        Write-Verbose "EmailOnlyOnUpdates is set and no updates available. Skipping email."
        return
    }

    try {
        $subject = if ($UpdatesAvailable) {
            "PowerShell Module Updates Available - $($ReportData.UpdatesAvailable) module(s)"
        }
        else {
            "PowerShell Module Update Check - All modules up to date"
        }

        $body = @"
PowerShell Module Update Report
Generated: $($ReportData.Timestamp)

Modules Checked: $($ReportData.ModulesChecked)
Updates Available: $($ReportData.UpdatesAvailable)
Modules Updated: $($ReportData.ModulesUpdated)

"@

        if ($UpdatesAvailable -and $ReportData.Updates.Count -gt 0) {
            $body += "`nAvailable Updates:`n"
            $body += "==================`n"
            foreach ($update in $ReportData.Updates) {
                $status = if ($update.Updated) { "[UPDATED]" } else { "[PENDING]" }
                $body += "$status $($update.Name): $($update.CurrentVersion) -> $($update.LatestVersion) ($($update.Source))`n"
            }
        }
        else {
            $body += "`nAll modules are up to date.`n"
        }

        $mailParams = @{
            To          = $EmailTo
            From        = $EmailFrom
            Subject     = $subject
            Body        = $body
            SmtpServer  = $EmailSmtpServer
            Port        = $EmailSmtpPort
            ErrorAction = 'Stop'
        }

        if ($EmailSmtpCredential) {
            $mailParams['Credential'] = $EmailSmtpCredential
        }

        Send-MailMessage @mailParams
        Write-ScriptMessage -Message "Email notification sent to: $($EmailTo -join ', ')" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to send email notification: $($_.Exception.Message)" -IsWarning
    }
}

<#
.SYNOPSIS
    Saves update history to track update records over time.

.DESCRIPTION
    Maintains a history file with all update checks and their results.
#>
function Save-UpdateHistory {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ReportData
    )

    $historyFile = Join-Path $repoRoot 'scripts' 'data' 'module-update-history.json'
    $historyDir = Split-Path -Path $historyFile -Parent
    Ensure-DirectoryExists -Path $historyDir

    $history = @()
    if (Test-Path $historyFile) {
        try {
            $existingContent = Get-Content -Path $historyFile -Raw -Encoding UTF8
            $history = $existingContent | ConvertFrom-Json
            if (-not $history) {
                $history = @()
            }
        }
        catch {
            Write-ScriptMessage -Message "Failed to read existing history file, creating new one: $($_.Exception.Message)" -IsWarning
            $history = @()
        }
    }

    # Add current report to history
    $historyEntry = [PSCustomObject]@{
        Timestamp        = $ReportData.Timestamp
        ModulesChecked   = $ReportData.ModulesChecked
        UpdatesAvailable = $ReportData.UpdatesAvailable
        ModulesUpdated   = $ReportData.ModulesUpdated
        Updates          = $ReportData.Updates
    }

    $history += $historyEntry

    # Keep only last 100 entries to prevent file from growing too large
    if ($history.Count -gt 100) {
        $history = $history | Select-Object -Last 100
    }

    try {
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $historyFile -Encoding UTF8
        Write-ScriptMessage -Message "Update history saved to: $historyFile" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to save update history: $($_.Exception.Message)" -IsWarning
    }
}

# Handle email parameter parsing (support comma-separated string from command line)
if ($EmailTo.Count -eq 1 -and $EmailTo[0] -match ',') {
    $EmailTo = $EmailTo[0] -split ',' | ForEach-Object { $_.Trim() }
}

# Handle scheduling operations
if ($RemoveSchedule) {
    Remove-UpdateSchedule
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

if ($Schedule) {
    Register-UpdateSchedule
    # Continue to run the check after scheduling
}

Write-ScriptMessage -Message "Checking for PowerShell module updates..."

$localModules = @()

if (Test-Path $localModulesPath) {
    $localModules = Get-ChildItem -Path $localModulesPath -Directory | ForEach-Object {
        $modulePath = Join-Path $_.FullName "$($_.Name).psd1"
        if (Test-Path $modulePath) {
            try {
                $moduleInfo = Import-CachedPowerShellDataFile -Path $modulePath
                [PSCustomObject]@{
                    Name    = $_.Name
                    Version = $moduleInfo.ModuleVersion
                    Path    = $_.FullName
                    Source  = "Local"
                }
            }
            catch {
                Write-ScriptMessage -Message "Failed to read module info for $($_.Name): $($_.Exception.Message)" -IsWarning
            }
        }
    }
}

# Check for updates from PowerShell Gallery
$modulesToCheck = @(
    # Local modules
    $localModules | Select-Object -ExpandProperty Name
    # Commonly used modules that might be installed
    'PSScriptAnalyzer',
    'Pester',
    'PowerShell-Beautifier'
) | Select-Object -Unique

# Apply module filter if specified
if ($ModuleFilter.Count -gt 0) {
    $modulesToCheck = $modulesToCheck | Where-Object { $_ -in $ModuleFilter }
    if ($modulesToCheck.Count -eq 0) {
        Write-ScriptMessage -Message "No modules match the specified filter" -IsWarning
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }
}

# Use List for better performance than array concatenation
$updatesAvailable = [System.Collections.Generic.List[PSCustomObject]]::new()

# Track which modules were successfully updated (for report)
$updatedModules = @{}

# Progress tracking
$totalModules = $modulesToCheck.Count
$currentModule = 0

foreach ($moduleName in $modulesToCheck) {
    $currentModule++
    $percentComplete = [math]::Round(($currentModule / $totalModules) * 100)
    
    try {
        Write-Progress -Activity "Checking module updates" -Status "Checking $moduleName ($currentModule/$totalModules)" -PercentComplete $percentComplete
        Write-ScriptMessage -Message "[$currentModule/$totalModules] Checking $moduleName..."

        # Try to get cached module version first (cache for 5 minutes)
        $cacheKey = "ModuleVersion_$moduleName"
        $cachedVersion = Get-CachedValue -Key $cacheKey
        
        if ($null -ne $cachedVersion) {
            Write-Verbose "Using cached version info for $moduleName"
            $installed = $cachedVersion.Installed
            $galleryInfo = $cachedVersion.Gallery
        }
        else {
            # Get installed version with retry logic
            $maxRetries = 3
            $retryCount = 0
            $installed = $null
            
            while ($retryCount -lt $maxRetries -and $null -eq $installed) {
                try {
                    $installed = Get-Module -Name $moduleName -ListAvailable -ErrorAction Stop |
                    Sort-Object Version -Descending | Select-Object -First 1
                }
                catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Verbose "Retry $retryCount/$maxRetries for Get-Module $moduleName"
                        Start-Sleep -Milliseconds (500 * $retryCount)  # Exponential backoff
                    }
                    else {
                        throw
                    }
                }
            }

            # Check PowerShell Gallery for latest version with retry logic
            $galleryInfo = $null
            $retryCount = 0
            
            while ($retryCount -lt $maxRetries -and $null -eq $galleryInfo) {
                try {
                    $galleryInfo = Find-Module -Name $moduleName -ErrorAction Stop
                }
                catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Verbose "Retry $retryCount/$maxRetries for Find-Module $moduleName"
                        Start-Sleep -Milliseconds (500 * $retryCount)  # Exponential backoff
                    }
                    else {
                        Write-Verbose "Could not find module $moduleName in gallery (may not be published)"
                        $galleryInfo = $null
                    }
                }
            }

            # Cache the results for 5 minutes
            if ($null -ne $installed -or $null -ne $galleryInfo) {
                Set-CachedValue -Key $cacheKey -Value @{
                    Installed = $installed
                    Gallery   = $galleryInfo
                } -ExpirationSeconds 300
            }
        }

        if ($installed) {
            if ($galleryInfo -and [version]$galleryInfo.Version -gt [version]$installed.Version) {
                $updatesAvailable.Add([PSCustomObject]@{
                        Name           = $moduleName
                        CurrentVersion = $installed.Version.ToString()
                        LatestVersion  = $galleryInfo.Version
                        Source         = if ($localModules | Where-Object { $_.Name -eq $moduleName }) { "Local" } else { "System" }
                    })
            }
        }
        else {
            Write-ScriptMessage -Message "Module $moduleName is not installed" -IsWarning
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to check updates for $moduleName`: $($_.Exception.Message)" -IsWarning
    }
}

Write-Progress -Activity "Checking module updates" -Completed

if ($updatesAvailable.Count -gt 0) {
    Write-ScriptMessage -Message "`nUpdates available:"
    $updatesAvailable | Format-Table -AutoSize

    if ($DryRun) {
        Write-ScriptMessage -Message "`nDRY RUN MODE: No updates will be installed. Run with -Update to install updates."
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }

    if ($Update) {
        Write-ScriptMessage -Message "`nUpdating modules..."
        $updateCount = 0
        $totalUpdates = $updatesAvailable.Count
        
        foreach ($moduleUpdate in $updatesAvailable) {
            $updateCount++
            $percentComplete = [math]::Round(($updateCount / $totalUpdates) * 100)
            
            Write-Progress -Activity "Updating modules" -Status "Updating $($moduleUpdate.Name) ($updateCount/$totalUpdates)" -PercentComplete $percentComplete
            
            try {
                Write-ScriptMessage -Message "[$updateCount/$totalUpdates] Updating $($moduleUpdate.Name) from $($moduleUpdate.CurrentVersion) to $($moduleUpdate.LatestVersion)..."
                
                # Retry logic for module updates
                $maxRetries = 3
                $retryCount = 0
                $updateSuccess = $false
                
                while ($retryCount -lt $maxRetries -and -not $updateSuccess) {
                    try {
                        if ($moduleUpdate.Source -eq "Local") {
                            # For local modules, update in place
                            Update-Module -Name $moduleUpdate.Name -RequiredVersion $moduleUpdate.LatestVersion -Force -ErrorAction Stop
                        }
                        else {
                            # For system modules, update normally
                            Install-Module -Name $moduleUpdate.Name -RequiredVersion $moduleUpdate.LatestVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                        }
                        $updateSuccess = $true
                        Write-ScriptMessage -Message "✓ Updated $($moduleUpdate.Name)"
                        
                        # Track successful update
                        $updatedModules[$moduleUpdate.Name] = $true
                        
                        # Clear cache for this module
                        Clear-CachedValue -Key "ModuleVersion_$($moduleUpdate.Name)"
                    }
                    catch {
                        $retryCount++
                        if ($retryCount -lt $maxRetries) {
                            Write-ScriptMessage -Message "Retry $retryCount/$maxRetries for updating $($moduleUpdate.Name)..." -IsWarning
                            Start-Sleep -Seconds (2 * $retryCount)  # Exponential backoff
                        }
                        else {
                            throw
                        }
                    }
                }
            }
            catch {
                Write-ScriptMessage -Message "Failed to update $($moduleUpdate.Name): $($_.Exception.Message)" -IsWarning
            }
        }
        
        Write-Progress -Activity "Updating modules" -Completed
    }
    else {
        Write-ScriptMessage -Message "`nRun with -Update switch to install updates"
    }
}
else {
    Write-ScriptMessage -Message "`nAll modules are up to date"
}

# Generate report data
$reportData = [PSCustomObject]@{
    Timestamp        = [DateTime]::UtcNow.ToString('o')
    ModulesChecked   = $modulesToCheck.Count
    UpdatesAvailable = $updatesAvailable.Count
    ModulesUpdated   = if ($Update) { $updatedModules.Count } else { 0 }
    Updates          = $updatesAvailable | ForEach-Object {
        [PSCustomObject]@{
            Name           = $_.Name
            CurrentVersion = $_.CurrentVersion
            LatestVersion  = $_.LatestVersion
            Source         = $_.Source
            Updated        = if ($Update) { $updatedModules.ContainsKey($_.Name) } else { $false }
        }
    }
}

# Save report if requested
if ($ReportFile -or ($Update -and $updatesAvailable.Count -gt 0)) {
    if ($ReportFile) {
        try {
            $reportDir = Split-Path -Path $ReportFile -Parent
            if ($reportDir -and -not (Test-Path -Path $reportDir)) {
                Ensure-DirectoryExists -Path $reportDir
            }
            
            $reportData | ConvertTo-Json -Depth 5 | Set-Content -Path $ReportFile -Encoding UTF8
            Write-ScriptMessage -Message "`nReport saved to: $ReportFile" -LogLevel Info
        }
        catch {
            Write-ScriptMessage -Message "Failed to save report: $($_.Exception.Message)" -IsWarning
        }
    }
    elseif ($Update) {
        # Auto-save report if updating
        $dataDir = Join-Path $repoRoot 'scripts' 'data'
        Ensure-DirectoryExists -Path $dataDir
        $defaultReportFile = Join-Path $dataDir "module-updates-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        try {
            $reportData | ConvertTo-Json -Depth 5 | Set-Content -Path $defaultReportFile -Encoding UTF8
            Write-ScriptMessage -Message "`nUpdate report saved to: $defaultReportFile" -LogLevel Info
        }
        catch {
            Write-ScriptMessage -Message "Failed to save update report: $($_.Exception.Message)" -IsWarning
        }
    }
}

# Save update history if requested
if ($TrackHistory) {
    Save-UpdateHistory -ReportData $reportData
}

# Send email notification if configured
$updatesAvailableCount = $updatesAvailable.Count -gt 0
Send-UpdateNotification -ReportData $reportData -UpdatesAvailable $updatesAvailableCount

Exit-WithCode -ExitCode $EXIT_SUCCESS

