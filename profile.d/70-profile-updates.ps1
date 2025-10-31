<#
# 70-profile-updates.ps1

Profile update checker with changelog display. Runs periodically to check for
updates and show recent changes when available.
#>

# Only run update checks in interactive sessions
if (-not $Host.UI -or -not $Host.UI.RawUI) { return }

# Skip if already loaded
if ($null -ne (Get-Variable -Name 'ProfileUpdatesLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

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
    if (-not $Force -and (Test-Path $lastCheckFile)) {
        $lastCheck = Get-Content $lastCheckFile -Raw
        if ($lastCheck -and ([DateTime]::Parse($lastCheck) -gt [DateTime]::Today)) {
            return
        }
    }

    # Only check if we're in a git repository
    if (-not (Test-Path (Join-Path $profileDir '.git'))) {
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
        $recentCommits | ForEach-Object { Write-Host "  $_" }

        # Check if there's a CHANGELOG.md
        $changelogPath = Join-Path $profileDir 'CHANGELOG.md'
        if (Test-Path $changelogPath) {
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
if ($env:CI -ne 'true' -and $env:GITHUB_ACTIONS -ne 'true' -and -not $env:PS_PROFILE_SKIP_UPDATES) {
    # Check for updates in background (don't block startup)
    $job = Start-Job -ScriptBlock {
        param($profileDir)
        try {
            Set-Location $profileDir
            Test-ProfileUpdates -MaxChanges 5
        }
        catch {
            # Silently fail background update checks
        }
    } -ArgumentList (Split-Path $PROFILE)

    # Clean up the job after a reasonable time
    Start-Job -ScriptBlock {
        param($jobId)
        Start-Sleep -Seconds 30
        if (Get-Job -Id $jobId -ErrorAction SilentlyContinue) {
            Remove-Job -Id $jobId -Force -ErrorAction SilentlyContinue
        }
    } -ArgumentList $job.Id | Out-Null
}

Set-Variable -Name 'ProfileUpdatesLoaded' -Value $true -Scope Global -Force
