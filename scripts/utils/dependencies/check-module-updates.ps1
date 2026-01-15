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
    Frequency for scheduled updates. Can be an UpdateFrequency enum value or string for backward compatibility.
    Valid values: Daily, Weekly, Monthly. Required when using -Schedule.

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

    [UpdateFrequency]$ScheduleFrequency

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

C# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import CommonEnums for UpdateFrequency enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import module update modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
$requiredModules = @(
    'ModuleUpdateChecker.psm1',
    'ModuleUpdateInstaller.psm1',
    'ModuleUpdateScheduler.psm1',
    'ModuleUpdateNotifier.psm1',
    'ModuleUpdateHistory.psm1'
)

foreach ($moduleName in $requiredModules) {
    $modulePath = Join-Path $modulesPath $moduleName
    if (-not (Test-Path $modulePath)) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Required module not found: $modulePath"
    }
    
    try {
        Import-Module $modulePath -DisableNameChecking -ErrorAction Stop
    }
    catch {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to import required module '$moduleName': $($_.Exception.Message)"
    }
}

# Get repository root and modules directory
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $localModulesPath = Join-Path $repoRoot 'Modules'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Scheduled task name
$scheduledTaskName = "PowerShell-Module-Updates"

# Handle email parameter parsing (support comma-separated string from command line)
if ($EmailTo.Count -eq 1 -and $EmailTo[0] -match ',') {
    $EmailTo = $EmailTo[0] -split ',' | ForEach-Object { $_.Trim() }
}

# Handle scheduling operations
if ($RemoveSchedule) {
    Remove-UpdateSchedule -ScheduledTaskName $scheduledTaskName
    Exit-WithCode -ExitCode [ExitCode]::Success
}

if ($Schedule) {
    # Convert ScheduleFrequency to appropriate format (Register-UpdateSchedule handles enum/string conversion)
    Register-UpdateSchedule -ScheduledTaskName $scheduledTaskName -RepoRoot $repoRoot -ScheduleFrequency $ScheduleFrequency -ScheduleTime $ScheduleTime -ScheduleDays $ScheduleDays -ScheduleDayOfMonth $ScheduleDayOfMonth -TrackHistory:$TrackHistory -EmailTo $EmailTo -EmailFrom $EmailFrom -EmailSmtpServer $EmailSmtpServer -EmailSmtpPort $EmailSmtpPort -EmailOnlyOnUpdates:$EmailOnlyOnUpdates
    # Continue to run the check after scheduling
}

Write-ScriptMessage -Message "Checking for PowerShell module updates..."

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-updates] Starting module update check"
    Write-Verbose "[dependencies.check-updates] Local modules path: $localModulesPath"
}

# Get local modules
$localModules = Get-LocalModules -LocalModulesPath $localModulesPath

# Level 2: Module list details
if ($debugLevel -ge 2) {
    Write-Verbose "[dependencies.check-updates] Found $($localModules.Count) local modules"
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
        Exit-WithCode -ExitCode [ExitCode]::Success
    }
}

# Level 1: Update check start
if ($debugLevel -ge 1) {
    Write-Verbose "[dependencies.check-updates] Checking $($modulesToCheck.Count) modules for updates"
}

# Check for updates (with retry logic and exponential backoff in ModuleUpdateChecker.psm1)
# The Get-ModuleUpdates function uses retry logic with exponential backoff for network operations
# Retry logic: maxRetries = 3, retryCount starts at 0, exponential backoff: Start-Sleep -Milliseconds (500 * retryCount)
# Handles timeout errors, network failures, and all retry attempts failing gracefully
$checkStartTime = Get-Date
$updatesAvailable = Get-ModuleUpdates -ModulesToCheck $modulesToCheck -LocalModules $localModules
$checkDuration = ((Get-Date) - $checkStartTime).TotalMilliseconds

# Level 2: Timing information
if ($debugLevel -ge 2) {
    Write-Verbose "[dependencies.check-updates] Update check completed in ${checkDuration}ms"
    Write-Verbose "[dependencies.check-updates] Updates available: $($updatesAvailable.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgCheckTime = if ($modulesToCheck.Count -gt 0) { $checkDuration / $modulesToCheck.Count } else { 0 }
    Write-Host "  [dependencies.check-updates] Performance - Total: ${checkDuration}ms, Avg per module: ${avgCheckTime}ms, Modules: $($modulesToCheck.Count)" -ForegroundColor DarkGray
}

# Track which modules were successfully updated (for report)
$updatedModules = @{}

if ($updatesAvailable.Count -gt 0) {
    Write-ScriptMessage -Message "`nUpdates available:"
    $updatesAvailable | Format-Table -AutoSize

    if ($DryRun) {
        Write-ScriptMessage -Message "`nDRY RUN MODE: No updates will be installed. Run with -Update to install updates."
        Exit-WithCode -ExitCode [ExitCode]::Success
    }

    if ($Update) {
        Write-ScriptMessage -Message "`nUpdating modules..."
        
        # Level 1: Update start
        if ($debugLevel -ge 1) {
            Write-Verbose "[dependencies.check-updates] Starting module updates"
            Write-Verbose "[dependencies.check-updates] Modules to update: $($updatesAvailable.Count)"
        }
        
        $updateStartTime = Get-Date
        $updatedModules = Install-ModuleUpdates -UpdatesAvailable $updatesAvailable
        $updateDuration = ((Get-Date) - $updateStartTime).TotalMilliseconds
        
        # Level 2: Update timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[dependencies.check-updates] Updates completed in ${updateDuration}ms"
            Write-Verbose "[dependencies.check-updates] Successfully updated: $($updatedModules.Count) modules"
        }
        
        # Level 3: Performance breakdown
        if ($debugLevel -ge 3) {
            $avgUpdateTime = if ($updatesAvailable.Count -gt 0) { $updateDuration / $updatesAvailable.Count } else { 0 }
            Write-Host "  [dependencies.check-updates] Update performance - Total: ${updateDuration}ms, Avg per module: ${avgUpdateTime}ms, Updated: $($updatedModules.Count)" -ForegroundColor DarkGray
        }
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

            Write-JsonFile -Path $ReportFile -InputObject $reportData -Depth 5 -EnsureDirectory
            Write-ScriptMessage -Message "`nReport saved to: $ReportFile" -LogLevel Info
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to save module update report" -OperationName 'dependencies.check-updates.save-report' -Context @{
                    report_file = $ReportFile
                } -Code 'ReportSaveFailed'
            }
            else {
                Write-ScriptMessage -Message "Failed to save report: $($_.Exception.Message)" -IsWarning
            }
        }
    }
    elseif ($Update) {
        # Auto-save report if updating
        $dataDir = Join-Path $repoRoot 'scripts' 'data'
        Ensure-DirectoryExists -Path $dataDir
        $defaultReportFile = Join-Path $dataDir "module-updates-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        try {
            Write-JsonFile -Path $defaultReportFile -InputObject $reportData -Depth 5 -EnsureDirectory
            Write-ScriptMessage -Message "`nUpdate report saved to: $defaultReportFile" -LogLevel Info
        }
        catch {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to save module update report" -OperationName 'dependencies.check-updates.save-report' -Context @{
                    report_file = $defaultReportFile
                } -Code 'ReportSaveFailed'
            }
            else {
                Write-ScriptMessage -Message "Failed to save update report: $($_.Exception.Message)" -IsWarning
            }
        }
    }
}

# Save update history if requested
if ($TrackHistory) {
    Save-UpdateHistory -ReportData $reportData -RepoRoot $repoRoot
}

# Send email notification if configured
$updatesAvailableCount = $updatesAvailable.Count -gt 0
Send-UpdateNotification -ReportData $reportData -UpdatesAvailable $updatesAvailableCount -EmailTo $EmailTo -EmailFrom $EmailFrom -EmailSmtpServer $EmailSmtpServer -EmailSmtpPort $EmailSmtpPort -EmailSmtpCredential $EmailSmtpCredential -EmailOnlyOnUpdates:$EmailOnlyOnUpdates

Exit-WithCode -ExitCode [ExitCode]::Success
