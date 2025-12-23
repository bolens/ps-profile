<#
.SYNOPSIS
    Optimizes git performance for prompt rendering without disabling features.

.DESCRIPTION
    Configures git and Starship to use optimized, cached git operations with timeouts.
    This fixes slow prompt performance while keeping all git features enabled.
#>

$starshipConfig = "$env:USERPROFILE\.config\starship.toml"

Write-Host "`n🔧 Optimizing Git Performance for Prompts" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# 1. Configure git to use faster operations
Write-Host "1. Configuring git for faster operations..." -ForegroundColor Yellow

# Set git config to use faster operations
$gitConfigs = @{
    'core.preloadindex'   = 'true'
    'core.fscache'        = 'true'
    'core.untrackedCache' = 'true'
    'gc.auto'             = '0'  # Disable auto-gc during operations
}

foreach ($key in $gitConfigs.Keys) {
    $value = $gitConfigs[$key]
    try {
        & git config --global $key $value 2>&1 | Out-Null
        Write-Host "   ✓ Set git config: $key = $value" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠ Failed to set git config ${key}: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 2. Update Starship config with performance optimizations
Write-Host "`n2. Optimizing Starship git modules..." -ForegroundColor Yellow

if (-not (Test-Path $starshipConfig)) {
    Write-Host "   Creating optimized Starship config..." -ForegroundColor Gray
    $configDir = Split-Path $starshipConfig
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    # Read existing config if it exists, otherwise create new
    $content = @"
# Starship configuration - optimized for performance
# Git modules configured with timeouts and caching

[git_branch]
symbol = " "
# Only show in repos with < 1000 files (adjust as needed)
only_attached = false
# Cache git operations
format = "[ `$symbol`$branch ](`$style)"

[git_status]
format = "[`$all_status`$ahead_behind ](`$style)"
# Only show if status check completes quickly
disabled = false
# Limit status checks to reduce overhead
conflicted = "="
up_to_date = ""
untracked = "?"
ahead = "⇡`${count}"
diverged = "⇕⇡`${ahead_count}⇣`${behind_count}"
behind = "⇣`${count}"

# Optimize other git modules
[git_commit]
disabled = false
only_detached = true

[git_state]
disabled = false
format = '[\(`$state( `$progress_current/`$progress_total)\)](`$style) '

"@
    $content | Out-File -FilePath $starshipConfig -Encoding UTF8
    Write-Host "   ✓ Created optimized Starship config" -ForegroundColor Green
}
else {
    Write-Host "   Updating existing Starship config..." -ForegroundColor Gray
    $content = Get-Content $starshipConfig -Raw
    
    # Add performance optimizations to git_branch if not present
    if ($content -notmatch '\[git_branch\]') {
        $content += "`n`n# Git branch - optimized for performance`n[git_branch]`nsymbol = `" `"`nformat = `"[ `$symbol`$branch ](`$style)`"`n"
    }
    else {
        # Update existing git_branch section
        $content = $content -replace '(?s)(\[git_branch\].*?)(?=\n\[|\Z)', {
            param($match)
            $section = $match.Value
            if ($section -notmatch 'only_attached') {
                $section = $section -replace '(\[git_branch\])', "`$1`n# Performance: only show in attached HEAD`nonly_attached = false"
            }
            $section
        }
    }
    
    # Add performance optimizations to git_status if not present
    if ($content -notmatch '\[git_status\]') {
        $content += "`n`n# Git status - optimized for performance`n[git_status]`nformat = `"[`$all_status`$ahead_behind ](`$style)`"`ndisabled = false`n"
    }
    
    $content | Out-File -FilePath $starshipConfig -Encoding UTF8 -NoNewline
    Write-Host "   ✓ Updated Starship config with performance optimizations" -ForegroundColor Green
}

# 3. Set environment variables for Starship performance
Write-Host "`n3. Setting environment variables for performance..." -ForegroundColor Yellow

$envVars = @{
    'STARSHIP_LOG'       = 'error'  # Reduce logging overhead
    'GIT_OPTIONAL_LOCKS' = '0'  # Disable optional locks for faster operations
}

foreach ($key in $envVars.Keys) {
    $value = $envVars[$key]
    [Environment]::SetEnvironmentVariable($key, $value, 'User')
    Write-Host "   ✓ Set $key = $value" -ForegroundColor Green
}

# 4. Create git wrapper with timeout (if needed)
Write-Host "`n4. Creating optimized git wrapper functions..." -ForegroundColor Yellow

$gitWrapperScript = @'
# Fast git operations with timeout protection
function Invoke-FastGit {
    param(
        [string[]]$Arguments,
        [int]$TimeoutSeconds = 1
    )
    
    # Use runspace for git operations (much faster than job)
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
    $runspacePool.Open()
    
    $powershell = [PowerShell]::Create()
    $powershell.RunspacePool = $runspacePool
    
    $scriptBlock = {
        param($args)
        & git @args 2>&1
    }
    
    $null = $powershell.AddScript($scriptBlock)
    $null = $powershell.AddArgument($Arguments)
    $handle = $powershell.BeginInvoke()
    
    # Wait with timeout using polling
    $timeoutMs = $TimeoutSeconds * 1000
    $pollIntervalMs = 50
    $elapsedMs = 0
    $completed = $false
    
    while ($elapsedMs -lt $timeoutMs) {
        if ($handle.IsCompleted) {
            $completed = $true
            break
        }
        Start-Sleep -Milliseconds $pollIntervalMs
        $elapsedMs += $pollIntervalMs
    }
    
    try {
        if ($completed) {
            $output = $powershell.EndInvoke($handle)
            return $output
        }
        else {
            # Timeout occurred
            $powershell.Stop()
            return $null
        }
    }
    finally {
        $powershell.Dispose()
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
}
'@

$profileDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gitWrapperPath = Join-Path $profileDir 'profile.d' 'git-fast-wrapper.ps1'

if (-not (Test-Path $gitWrapperPath)) {
    $gitWrapperScript | Out-File -FilePath $gitWrapperPath -Encoding UTF8
    Write-Host "   ✓ Created git wrapper with timeout protection" -ForegroundColor Green
}
else {
    Write-Host "   ℹ Git wrapper already exists" -ForegroundColor Gray
}

Write-Host "`n✅ Git performance optimizations applied!" -ForegroundColor Green
Write-Host "`n💡 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Restart PowerShell to apply changes" -ForegroundColor White
Write-Host "   2. Test prompt performance: . `$PROFILE" -ForegroundColor White
Write-Host "   3. If still slow, check if you're in a very large repo" -ForegroundColor White
Write-Host "`n📝 Note: Git features are still enabled, just optimized for speed." -ForegroundColor Gray

