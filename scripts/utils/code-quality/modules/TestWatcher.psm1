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

.OUTPUTS
    None - runs until canceled
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
        [string]$RepoRoot
    )

    $watchers = @()
    $changeTimer = $null
    $lastChangeTime = $null
    $isRunning = $true

    # Cleanup function
    $cleanup = {
        foreach ($watcher in $watchers) {
            if ($watcher) {
                $watcher.Dispose()
            }
        }
        if ($changeTimer) {
            $changeTimer.Dispose()
        }
    }

    # Register cleanup on script exit
    Register-ObjectEvent -InputObject ([System.AppDomain]::CurrentDomain) -EventName 'ProcessExit' -Action $cleanup | Out-Null

    try {
        Write-Host "`n=== Watch Mode Active ===" -ForegroundColor Cyan
        Write-Host "Watching for changes in:" -ForegroundColor Yellow
        foreach ($path in $WatchPaths) {
            Write-Host "  - $path" -ForegroundColor Gray
        }
        Write-Host "`nPress Ctrl+C to stop watching" -ForegroundColor Yellow
        Write-Host ""

        # Create file system watchers for each path
        foreach ($watchPath in $WatchPaths) {
            if ($watchPath -and -not [string]::IsNullOrWhiteSpace($watchPath) -and -not (Test-Path -LiteralPath $watchPath)) {
                Write-ScriptMessage -Message "Warning: Watch path does not exist: $watchPath" -LogLevel 'Warning'
                continue
            }

            $watcher = New-Object System.IO.FileSystemWatcher
            $watcher.Path = $watchPath
            $watcher.IncludeSubdirectories = $true
            $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName
            $watcher.EnableRaisingEvents = $true

            # Filter for relevant file types - capture in local scope for closure
            $localTestFiles = $TestFiles
            $localSourceFiles = $SourceFiles
            $localDebounceSeconds = $DebounceSeconds
            $localOnChange = $OnChange
            $allPatterns = $localTestFiles + $localSourceFiles

            # Register change event - capture variables in closure
            $action = {
                param($source, $e)
                
                # Capture variables from outer scope
                $patterns = $localTestFiles + $localSourceFiles
                $debounceSecs = $localDebounceSeconds
                $onChangeScript = $localOnChange
                
                # Check if file matches our patterns
                $fileName = Split-Path $e.FullPath -Leaf
                $matchesPattern = $false
                
                foreach ($pattern in $patterns) {
                    if ($fileName -like $pattern) {
                        $matchesPattern = $true
                        break
                    }
                }
                
                # Also check if it's a test file or source file
                if (-not $matchesPattern) {
                    if ($e.FullPath -like '*.tests.ps1' -or $e.FullPath -like '*.ps1' -or $e.FullPath -like '*.psm1') {
                        $matchesPattern = $true
                    }
                }
                
                if ($matchesPattern) {
                    # Capture file name for timer event
                    $changedFileName = $e.Name
                    
                    # Debounce: wait for quiet period before triggering
                    if ($script:changeTimer) {
                        $script:changeTimer.Stop()
                        $script:changeTimer.Dispose()
                    }
                    
                    $script:changeTimer = New-Object System.Timers.Timer
                    $script:changeTimer.Interval = ($debounceSecs * 1000)
                    $script:changeTimer.AutoReset = $false
                    $script:changeTimer.Add_Elapsed({
                            param($sender, $eventArgs)
                            $script:changeTimer.Stop()
                            $timeStr = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                                Format-LocaleDate (Get-Date) -Format 'HH:mm:ss'
                            }
                            else {
                                (Get-Date -Format 'HH:mm:ss')
                            }
                            Write-Host "`n[$timeStr] File changed: $changedFileName" -ForegroundColor Cyan
                            & $onChangeScript
                        })
                    $script:changeTimer.Start()
                }
            }

            Register-ObjectEvent -InputObject $watcher -EventName 'Changed' -Action $action | Out-Null
            Register-ObjectEvent -InputObject $watcher -EventName 'Created' -Action $action | Out-Null
            Register-ObjectEvent -InputObject $watcher -EventName 'Deleted' -Action $action | Out-Null
            Register-ObjectEvent -InputObject $watcher -EventName 'Renamed' -Action $action | Out-Null

            $watchers += $watcher
        }

        # Wait for user to cancel
        Write-Host "Watching for changes... (Press Ctrl+C to stop)" -ForegroundColor Green
        
        try {
            while ($isRunning) {
                Start-Sleep -Seconds 1
            }
        }
        catch {
            # User canceled (Ctrl+C)
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
    'Start-TestWatcher'
)

