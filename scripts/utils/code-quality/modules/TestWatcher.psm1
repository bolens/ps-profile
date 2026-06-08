<#
scripts/utils/code-quality/modules/TestWatcher.psm1

.SYNOPSIS
    File system watcher utilities for watch mode.

.DESCRIPTION
    Provides functions for monitoring file changes and automatically re-running tests.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Locale module for locale-aware formatting
$localeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Locale.psm1'
if ($localeModulePath -and -not [string]::IsNullOrWhiteSpace($localeModulePath) -and (Test-Path -LiteralPath $localeModulePath)) {
    Import-Module $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Determines whether a changed file should trigger watch-mode callbacks.

.DESCRIPTION
    Matches file names against configured test/source patterns and falls back to
    common PowerShell file extensions when no explicit pattern matches.

.PARAMETER FileName
    Leaf file name of the changed file.

.PARAMETER FullPath
    Full path of the changed file.

.PARAMETER TestFiles
    Test file patterns to match (for example, *.tests.ps1).

.PARAMETER SourceFiles
    Source file patterns to match (for example, *.ps1, *.psm1).

.OUTPUTS
    System.Boolean
#>
function Test-WatcherFileMatch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter(Mandatory)]
        [string]$FullPath,

        [string[]]$TestFiles = @('*.tests.ps1'),

        [string[]]$SourceFiles = @('*.ps1', '*.psm1')
    )

    $patterns = @($TestFiles + $SourceFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    foreach ($pattern in $patterns) {
        if ($FileName -like $pattern) {
            return $true
        }
    }

    if ($FullPath -like '*.tests.ps1' -or $FullPath -like '*.ps1' -or $FullPath -like '*.psm1') {
        return $true
    }

    return $false
}

$script:TestWatcherConfig = @{
    TestFiles       = @('*.tests.ps1')
    SourceFiles     = @('*.ps1', '*.psm1')
    DebounceSeconds = 1
    OnChange        = $null
}
$script:TestWatcherChangeTimer = $null

<#
.SYNOPSIS
    Creates and registers a FileSystemWatcher for a single watch path.

.DESCRIPTION
    Internal helper that configures watcher filters and registers change events.

.OUTPUTS
    System.IO.FileSystemWatcher
#>
function New-RegisteredTestWatcher {
    [CmdletBinding()]
    [OutputType([System.IO.FileSystemWatcher])]
    param(
        [Parameter(Mandatory)]
        [string]$WatchPath
    )

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WatchPath
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName
    $watcher.EnableRaisingEvents = $true

    $fileChangeAction = {
        param($source, $e)

        $config = $Event.MessageData
        if (-not $config) {
            return
        }

        $fileName = Split-Path $e.FullPath -Leaf
        if (-not (Test-WatcherFileMatch -FileName $fileName -FullPath $e.FullPath -TestFiles $config.TestFiles -SourceFiles $config.SourceFiles)) {
            return
        }

        if ($script:TestWatcherChangeTimer) {
            $script:TestWatcherChangeTimer.Stop()
            $script:TestWatcherChangeTimer.Dispose()
            $script:TestWatcherChangeTimer = $null
        }

        $debounceState = @{
            OnChange = $config.OnChange
            FileName = $e.Name
        }

        $script:TestWatcherChangeTimer = New-Object System.Timers.Timer
        $script:TestWatcherChangeTimer.Interval = ($config.DebounceSeconds * 1000)
        $script:TestWatcherChangeTimer.AutoReset = $false

        Register-ObjectEvent -InputObject $script:TestWatcherChangeTimer -EventName 'Elapsed' -Action {
            param($sender, $eventArgs)

            $state = $Event.MessageData
            if ($script:TestWatcherChangeTimer) {
                $script:TestWatcherChangeTimer.Stop()
                $script:TestWatcherChangeTimer.Dispose()
                $script:TestWatcherChangeTimer = $null
            }

            if (-not $state) {
                return
            }

            $timeStr = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                Format-LocaleDate (Get-Date) -Format 'HH:mm:ss'
            }
            else {
                (Get-Date -Format 'HH:mm:ss')
            }

            Write-Host "`n[$timeStr] File changed: $($state.FileName)" -ForegroundColor Cyan
            if ($state.OnChange) {
                & $state.OnChange
            }
        } -MessageData $debounceState -SourceIdentifier "TestWatcher.Debounce.$([guid]::NewGuid().ToString())" | Out-Null
        $script:TestWatcherChangeTimer.Start()
    }

    Register-ObjectEvent -InputObject $watcher -EventName 'Changed' -Action $fileChangeAction -MessageData $script:TestWatcherConfig | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName 'Created' -Action $fileChangeAction -MessageData $script:TestWatcherConfig | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName 'Deleted' -Action $fileChangeAction -MessageData $script:TestWatcherConfig | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName 'Renamed' -Action $fileChangeAction -MessageData $script:TestWatcherConfig | Out-Null

    return $watcher
}

<#
.SYNOPSIS
    Disposes watcher resources and debounce timers.
#>
function Stop-TestWatcherResources {
    [CmdletBinding()]
    param(
        [System.IO.FileSystemWatcher[]]$Watchers
    )

    foreach ($watcher in @($Watchers)) {
        if ($watcher) {
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
        }
    }

    if ($script:TestWatcherChangeTimer) {
        $script:TestWatcherChangeTimer.Stop()
        $script:TestWatcherChangeTimer.Dispose()
        $script:TestWatcherChangeTimer = $null
    }

    Get-EventSubscriber -ErrorAction SilentlyContinue |
        Where-Object { $_.SourceIdentifier -like 'TestWatcher.Debounce.*' } |
        ForEach-Object { Unregister-Event -SubscriptionId $_.SubscriptionId -ErrorAction SilentlyContinue }
}

<#
.SYNOPSIS
    Watches for file changes and triggers test execution.

.DESCRIPTION
    Monitors specified directories for file changes and automatically re-runs tests
    when changes are detected. Supports debouncing to avoid excessive test runs.

.PARAMETER WatchPaths
    Array of directory paths to watch for changes.

.PARAMETER TestFiles
    Array of test file patterns to watch (e.g., *.tests.ps1).

.PARAMETER SourceFiles
    Array of source file patterns to watch (e.g., *.ps1, *.psm1).

.PARAMETER DebounceSeconds
    Number of seconds to wait after a change before triggering tests. Defaults to 1 second.

.PARAMETER OnChange
    ScriptBlock to execute when changes are detected.

.PARAMETER RepoRoot
    Repository root directory path.

.PARAMETER MaximumDurationSeconds
    Optional bounded runtime for watch mode. When greater than zero, watch mode exits
    automatically after the specified number of seconds. Defaults to zero (run until canceled).

.OUTPUTS
    None - runs until canceled or MaximumDurationSeconds elapses
#>
function Start-TestWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$WatchPaths,
        [string[]]$TestFiles = @('*.tests.ps1'),
        [string[]]$SourceFiles = @('*.ps1', '*.psm1'),
        [int]$DebounceSeconds = 1,
        [Parameter(Mandatory)]
        [scriptblock]$OnChange,
        [string]$RepoRoot,
        [int]$MaximumDurationSeconds = 0
    )

    $watchers = [System.Collections.Generic.List[System.IO.FileSystemWatcher]]::new()
    $isRunning = $true
    $watchStartedAt = Get-Date

    $cleanup = {
        Stop-TestWatcherResources -Watchers $watchers.ToArray()
    }

    Register-ObjectEvent -InputObject ([System.AppDomain]::CurrentDomain) -EventName 'ProcessExit' -Action $cleanup | Out-Null

    try {
        Write-Host "`n=== Watch Mode Active ===" -ForegroundColor Cyan
        Write-Host "Watching for changes in:" -ForegroundColor Yellow
        foreach ($path in $WatchPaths) {
            Write-Host "  - $path" -ForegroundColor Gray
        }
        Write-Host "`nPress Ctrl+C to stop watching" -ForegroundColor Yellow
        Write-Host ""

        $script:TestWatcherConfig = @{
            TestFiles       = $TestFiles
            SourceFiles     = $SourceFiles
            DebounceSeconds = $DebounceSeconds
            OnChange        = $OnChange
        }

        foreach ($watchPath in $WatchPaths) {
            if ($watchPath -and -not [string]::IsNullOrWhiteSpace($watchPath) -and -not (Test-Path -LiteralPath $watchPath)) {
                Write-ScriptMessage -Message "Warning: Watch path does not exist: $watchPath" -LogLevel 'Warning'
                continue
            }

            $watchers.Add((New-RegisteredTestWatcher -WatchPath $watchPath))
        }

        Write-Host "Watching for changes... (Press Ctrl+C to stop)" -ForegroundColor Green

        try {
            while ($isRunning) {
                if ($MaximumDurationSeconds -gt 0 -and ((Get-Date) - $watchStartedAt).TotalSeconds -ge $MaximumDurationSeconds) {
                    break
                }

                Start-Sleep -Seconds 1
            }
        }
        catch {
            $cancelMsg = if (Get-Command Get-LocalizedMessage -ErrorAction SilentlyContinue) {
                Get-LocalizedMessage -USMessage "Watch mode canceled by user" -UKMessage "Watch mode cancelled by user"
            }
            else {
                "Watch mode canceled by user"
            }
            Write-Host "`n$cancelMsg" -ForegroundColor Yellow
        }
    }
    finally {
        & $cleanup
    }
}

Export-ModuleMember -Function @(
    'Start-TestWatcher',
    'Test-WatcherFileMatch',
    'Stop-TestWatcherResources'
)
