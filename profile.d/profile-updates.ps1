<#

<#

# Tier: optional
# Dependencies: bootstrap, env
<#

<#
# profile-updates.ps1

Profile update checker with changelog display. Runs periodically to check for
updates and show recent changes when available.
#>

# Only run update checks in interactive sessions or test environments
if ((-not $Host.UI -or -not $Host.UI.RawUI) -and -not $env:PS_PROFILE_TEST_MODE) { return }

# Skip if already loaded (unless in test mode)
if ($null -ne (Get-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -ErrorAction SilentlyContinue) -and -not $env:PS_PROFILE_TEST_MODE) { return }

# Profile update checker
<#
.SYNOPSIS
    Checks for profile updates and displays changelog.
.DESCRIPTION
    Checks if the profile repository has new commits and displays a summary
    of recent changes. Only shows updates once per day to avoid spam.
#>
function Test-ProfileUpdates {
    param(
        [switch]$Force,
        [int]$MaxChanges = 10
    )

    $profileDir = Split-Path $PROFILE
    $lastCheckFile = Join-Path $profileDir '.profile-last-update-check'

    # Check if we should skip (already checked today unless forced)
    if (-not $Force -and
        ($lastCheckFile -and
        -not [string]::IsNullOrWhiteSpace($lastCheckFile) -and
        (Test-Path -LiteralPath $lastCheckFile))) {
        $lastCheck = Get-Content $lastCheckFile -Raw
        if ($lastCheck -and ([DateTime]::Parse($lastCheck) -gt [DateTime]::Today)) {
            return
        }
    }

    # Only check if we're in a git repository
    $gitPath = if ($profileDir -and -not [string]::IsNullOrWhiteSpace($profileDir)) { Join-Path $profileDir '.git' } else { $null }
    if (-not ($gitPath -and (Test-Path -LiteralPath $gitPath))) {
        Write-Verbose "Profile directory is not a git repository, skipping update check"
        return
    }

    try {
        Push-Location $profileDir

        # Get current branch and remote status
        $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $currentBranch) {
            Write-Verbose "Could not determine current git branch"
            return
        }

        # Check if we have upstream remote
        $hasUpstream = git rev-parse --abbrev-ref "@{upstream}" 2>$null
        if (-not $hasUpstream) {
            Write-Verbose "No upstream remote configured"
            return
        }

        # Fetch latest changes
        git fetch origin --quiet 2>$null

        # Check if we're behind
        $behindCount = git rev-list --count "$currentBranch..origin/$currentBranch" 2>$null
        if (-not $behindCount -or $behindCount -eq 0) {
            # Update last check time
            [DateTime]::Now.ToString('o') | Set-Content $lastCheckFile -Encoding UTF8
            return
        }

        # Get recent commits
        $recentCommits = git log --oneline --no-merges -n $MaxChanges "$currentBranch..origin/$currentBranch" 2>$null
        if (-not $recentCommits) {
            return
        }

        # Display update notification
        Write-Host ""
        Write-Host "🔄 Profile Updates Available!" -ForegroundColor Green
        Write-Host ("You're {0} commit(s) behind origin/{1}" -f $behindCount, $currentBranch)
        Write-Host ""
        Write-Host "Recent changes:" -ForegroundColor Yellow
        # Optimized: Use foreach loop instead of ForEach-Object
        foreach ($commit in $recentCommits) {
            Write-Host "  $commit"
        }

        # Check if there's a CHANGELOG.md
        $changelogPath = Join-Path $profileDir 'CHANGELOG.md'
        if ($changelogPath -and -not [string]::IsNullOrWhiteSpace($changelogPath) -and (Test-Path -LiteralPath $changelogPath)) {
            Write-Host ""
            Write-Host "📋 View full changelog: $changelogPath" -ForegroundColor Cyan
        }

        Write-Host ""
        Write-Host "💡 Run 'git pull' to update your profile" -ForegroundColor Magenta
        Write-Host ""

        # Update last check time
        [DateTime]::Now.ToString('o') | Set-Content $lastCheckFile -Encoding UTF8

    }
    catch {
        Write-Verbose "Profile update check failed: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

# Auto-check for updates (but only occasionally and not in CI)
if ($env:CI -ne 'true' -and $env:GITHUB_ACTIONS -ne 'true' -and -not (Test-EnvBool $env:PS_PROFILE_SKIP_UPDATES)) {
    # Schedule update check to run after profile load completes (truly async)
    # Use a timer to delay execution and avoid blocking startup
    try {
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 5000  # 5 seconds delay to let profile finish loading
        $timer.AutoReset = $false

        # Store timer and subscriber in global scope for cleanup
        $global:ProfileUpdateTimer = $timer
        $global:ProfileUpdateRunspaces = New-Object System.Collections.ArrayList

        $timerAction = {
            try {
                $profileDir = Split-Path $PROFILE
                
                # Use runspace for update check (much faster than job)
                $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
                $runspacePool.Open()
                
                $powershell = [PowerShell]::Create()
                $powershell.RunspacePool = $runspacePool
                
                $scriptBlock = {
                    param($ProfileDir)
                    try {
                        Set-Location $ProfileDir
                        Test-ProfileUpdates -MaxChanges 5
                    }
                    catch {
                        # Silently fail background update checks
                    }
                }
                
                $null = $powershell.AddScript($scriptBlock)
                $null = $powershell.AddArgument($profileDir)
                $handle = $powershell.BeginInvoke()
                
                # Track runspace for cleanup
                if ($global:ProfileUpdateRunspaces) {
                    [void]$global:ProfileUpdateRunspaces.Add(@{
                            PowerShell = $powershell
                            Handle     = $handle
                            Pool       = $runspacePool
                        })
                }
                
                # Clean up runspace after completion (async cleanup)
                $cleanupScript = {
                    param($PowerShellObj, $Handle, $Pool)
                    try {
                        # Wait for completion (max 20 seconds)
                        $timeout = 20000
                        $elapsed = 0
                        $pollInterval = 100
                        while ($elapsed -lt $timeout) {
                            if ($Handle.IsCompleted) {
                                break
                            }
                            Start-Sleep -Milliseconds $pollInterval
                            $elapsed += $pollInterval
                        }
                        
                        # Clean up
                        if ($Handle.IsCompleted) {
                            try {
                                $null = $PowerShellObj.EndInvoke($Handle)
                            }
                            catch {
                                # Ignore errors
                            }
                        }
                    }
                    catch {
                        # Silently fail cleanup
                    }
                    finally {
                        if ($PowerShellObj) {
                            $PowerShellObj.Dispose()
                        }
                        if ($Pool) {
                            $Pool.Close()
                            $Pool.Dispose()
                        }
                    }
                }
                
                # Start cleanup in background (using another runspace)
                $cleanupPool = [runspacefactory]::CreateRunspacePool(1, 1)
                $cleanupPool.Open()
                $cleanupPS = [PowerShell]::Create()
                $cleanupPS.RunspacePool = $cleanupPool
                $null = $cleanupPS.AddScript($cleanupScript)
                $null = $cleanupPS.AddArgument($powershell)
                $null = $cleanupPS.AddArgument($handle)
                $null = $cleanupPS.AddArgument($runspacePool)
                $cleanupHandle = $cleanupPS.BeginInvoke()
                
                # Track cleanup runspace
                if ($global:ProfileUpdateRunspaces) {
                    [void]$global:ProfileUpdateRunspaces.Add(@{
                            PowerShell = $cleanupPS
                            Handle     = $cleanupHandle
                            Pool       = $cleanupPool
                        })
                }
            }
            catch {
                # Silently fail timer-based update checks
            }
            finally {
                # Clean up timer
                if ($global:ProfileUpdateTimer) {
                    $global:ProfileUpdateTimer.Stop()
                    $global:ProfileUpdateTimer.Dispose()
                    $global:ProfileUpdateTimer = $null
                }
            }
        }

        # Store event subscriber for proper cleanup
        $global:ProfileUpdateEventSubscriber = Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action $timerAction
        $timer.Start()
    }
    catch {
        # Fallback: try to schedule with a simple delay if timer fails (using runspace)
        $profileDir = Split-Path $PROFILE
        
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
        $runspacePool.Open()
        
        $powershell = [PowerShell]::Create()
        $powershell.RunspacePool = $runspacePool
        
        $scriptBlock = {
            param($ProfileDir)
            try {
                Start-Sleep -Seconds 10  # Delay before running
                Set-Location $ProfileDir
                Test-ProfileUpdates -MaxChanges 5
            }
            catch {
                # Silently fail background update checks
            }
        }
        
        $null = $powershell.AddScript($scriptBlock)
        $null = $powershell.AddArgument($profileDir)
        $handle = $powershell.BeginInvoke()
        
        # Track fallback runspace for cleanup
        if (-not $global:ProfileUpdateRunspaces) {
            $global:ProfileUpdateRunspaces = New-Object System.Collections.ArrayList
        }
        [void]$global:ProfileUpdateRunspaces.Add(@{
                PowerShell = $powershell
                Handle     = $handle
                Pool       = $runspacePool
            })
    }
}

# Cleanup function for profile shutdown
function global:Stop-ProfileUpdateChecker {
    try {
        # Unregister event subscription
        if ($global:ProfileUpdateEventSubscriber) {
            Unregister-Event -SubscriptionId $global:ProfileUpdateEventSubscriber.Id -ErrorAction SilentlyContinue
            $global:ProfileUpdateEventSubscriber = $null
        }

        # Stop and dispose timer
        if ($global:ProfileUpdateTimer) {
            $global:ProfileUpdateTimer.Stop()
            $global:ProfileUpdateTimer.Dispose()
            $global:ProfileUpdateTimer = $null
        }

        # Clean up runspaces
        if ($global:ProfileUpdateRunspaces) {
            foreach ($rs in $global:ProfileUpdateRunspaces.ToArray()) {
                try {
                    if ($rs.PowerShell) {
                        if ($rs.Handle -and -not $rs.Handle.IsCompleted) {
                            $rs.PowerShell.Stop()
                        }
                        $rs.PowerShell.Dispose()
                    }
                    if ($rs.Pool) {
                        $rs.Pool.Close()
                        $rs.Pool.Dispose()
                    }
                }
                catch {
                    # Silently fail individual runspace cleanup
                }
            }
            $global:ProfileUpdateRunspaces.Clear()
        }
    }
    catch {
        # Silently fail cleanup
    }
}

# Register cleanup on PowerShell exit
# Store subscriber reference (though engine events auto-cleanup on exit)
$global:ProfileUpdateEngineEventSubscriber = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-ProfileUpdateChecker
}

Set-Variable -Name 'ProfileUpdatesLoaded' -Value $true -Scope Global -Force
