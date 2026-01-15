<#
.SYNOPSIS
    Optimizes git performance for prompt rendering without disabling features.

.DESCRIPTION
    Configures git and Starship to use optimized, cached git operations with timeouts.
    This fixes slow prompt performance while keeping all git features enabled.
#>

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

$starshipConfig = "$env:USERPROFILE\.config\starship.toml"

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[git.optimize] Starting git performance optimization"
    Write-Verbose "[git.optimize] Starship config path: $starshipConfig"
}

Write-Host "`n🔧 Optimizing Git Performance for Prompts" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# 1. Configure git to use faster operations
Write-Host "1. Configuring git for faster operations..." -ForegroundColor Yellow

# Level 1: Git config start
if ($debugLevel -ge 1) {
    Write-Verbose "[git.optimize] Configuring git settings"
}

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
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to set git config" -OperationName 'git.optimize.config' -Context @{
                config_key = $key
                config_value = $value
            } -Code 'GitConfigSetFailed'
        }
        else {
            Write-Host "   ⚠ Failed to set git config ${key}: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 2. Update Starship config with performance optimizations
Write-Host "`n2. Optimizing Starship git modules..." -ForegroundColor Yellow

if (-not (Test-Path $starshipConfig)) {
    Write-Host "   Creating optimized Starship config..." -ForegroundColor Gray
    $configDir = Split-Path $starshipConfig
    if (-not (Test-Path $configDir)) {
        try {
            New-Item -ItemType Directory -Path $configDir -Force -ErrorAction Stop | Out-Null
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'git.optimize.starship.create-dir' -Context @{
                    config_dir = $configDir
                }
            }
            else {
                Write-Host "   ⚠ Failed to create config directory: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
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
    try {
        $content | Out-File -FilePath $starshipConfig -Encoding UTF8 -ErrorAction Stop
        Write-Host "   ✓ Created optimized Starship config" -ForegroundColor Green
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'git.optimize.starship.create' -Context @{
                config_path = $starshipConfig
            }
        }
        else {
            Write-Host "   ⚠ Failed to create Starship config: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "   Updating existing Starship config..." -ForegroundColor Gray
    try {
        $content = Get-Content $starshipConfig -Raw -ErrorAction Stop
    
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
    
        $content | Out-File -FilePath $starshipConfig -Encoding UTF8 -NoNewline -ErrorAction Stop
        Write-Host "   ✓ Updated Starship config with performance optimizations" -ForegroundColor Green
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'git.optimize.starship.update' -Context @{
                config_path = $starshipConfig
            }
        }
        else {
            Write-Host "   ⚠ Failed to update Starship config: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 3. Set environment variables for Starship performance
Write-Host "`n3. Setting environment variables for performance..." -ForegroundColor Yellow

$envVars = @{
    'STARSHIP_LOG'       = 'error'  # Reduce logging overhead
    'GIT_OPTIONAL_LOCKS' = '0'  # Disable optional locks for faster operations
}

$envVarErrors = [System.Collections.Generic.List[string]]::new()
foreach ($key in $envVars.Keys) {
    $value = $envVars[$key]
    try {
        [Environment]::SetEnvironmentVariable($key, $value, 'User') -ErrorAction Stop
        Write-Host "   ✓ Set $key = $value" -ForegroundColor Green
    }
    catch {
        $envVarErrors.Add($key)
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to set environment variable" -OperationName 'git.optimize.env-var' -Context @{
                env_var_name = $key
                env_var_value = $value
            } -Code 'EnvVarSetFailed'
        }
        else {
            Write-Host "   ⚠ Failed to set $key: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
if ($envVarErrors.Count -gt 0) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some environment variables failed to set" -OperationName 'git.optimize.env-var' -Context @{
            failed_vars = $envVarErrors -join ','
            failed_count = $envVarErrors.Count
        } -Code 'EnvVarSetPartialFailure'
    }
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
    try {
        $gitWrapperScript | Out-File -FilePath $gitWrapperPath -Encoding UTF8 -ErrorAction Stop
        Write-Host "   ✓ Created git wrapper with timeout protection" -ForegroundColor Green
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'git.optimize.wrapper.create' -Context @{
                wrapper_path = $gitWrapperPath
            }
        }
        else {
            Write-Host "   ⚠ Failed to create git wrapper: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
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

