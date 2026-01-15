# ===============================================
# SmartPrompt.ps1
# Smart fallback prompt when Starship is unavailable
# ===============================================

<#
.SYNOPSIS
    Initializes a smart fallback prompt when Starship is not available.
.DESCRIPTION
    Sets up an enhanced PowerShell prompt that shows git branch, project status (uv/npm/rust/go/docker/poetry/pnpm),
    error status, execution time, and other useful information when Starship is not available.
    
    Features can be enabled via environment variables:
    - PS_PROFILE_SHOW_GIT_BRANCH: Show git branch (default: disabled)
    - PS_PROFILE_SHOW_UV: Show uv project status (default: disabled)
    - PS_PROFILE_SHOW_NPM: Show npm project status (default: disabled)
    - PS_PROFILE_SHOW_RUST: Show Rust project status (default: disabled)
    - PS_PROFILE_SHOW_GO: Show Go project status (default: disabled)
    - PS_PROFILE_SHOW_DOCKER: Show Docker project status (default: disabled)
    - PS_PROFILE_SHOW_POETRY: Show Poetry project status (default: disabled)
    - PS_PROFILE_SHOW_PNPM: Show pnpm/yarn project status (default: disabled)
#>
function global:Initialize-SmartPrompt {
    try {
        if ($null -ne (Get-Variable -Name "SmartPromptInitialized" -Scope Global -ErrorAction SilentlyContinue)) {
            return
        }
        
        # Store original prompt
        if (-not $global:OriginalPrompt) {
            $global:OriginalPrompt = $function:prompt
        }
        
        # Enhanced prompt function
        function global:prompt {
            # Stop timer for the command that just completed (prompt runs AFTER command execution)
            # This measures the actual command execution time, not the time between prompts
            if ($global:CommandStartTime) {
                $global:LastCommandDuration = [DateTime]::Now - $global:CommandStartTime
                $global:CommandStartTime = $null
            }
            
            $lastCommandSucceeded = $?
            try {
                $lastExitCode = $LASTEXITCODE
                $currentPath = $executionContext.SessionState.Path.CurrentLocation.Path
                $promptParts = @()
                
                # User and computer
                $promptParts += "$env:USERNAME@$env:COMPUTERNAME"
                
                # Current directory (shortened)
                $shortPath = $currentPath -replace [regex]::Escape($env:USERPROFILE), "~"
                if ($shortPath.Length -gt 40) {
                    $shortPath = "..." + $shortPath.Substring($shortPath.Length - 37)
                }
                $promptParts += $shortPath
                
                # Git branch (if in git repo) - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_GIT_BRANCH = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_GIT_BRANCH) {
                    try {
                        if (Test-CachedCommand git) {
                            if (Test-Path ".git" -ErrorAction SilentlyContinue) {
                                $gitBranch = & git rev-parse --abbrev-ref HEAD 2>&1
                                $gitExitCode = $LASTEXITCODE
                                if ($gitExitCode -eq 0 -and
                                    $gitBranch -and
                                    $gitBranch.Trim() -ne "HEAD" -and
                                    $gitBranch.Trim() -ne "") {
                                    $promptParts += "git:($($gitBranch.Trim()))"
                                }
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to get git branch for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # UV project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_UV = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_UV) {
                    try {
                        if (Test-CachedCommand uv) {
                            # Check for uv project indicators (pyproject.toml, .python-version, or .venv)
                            $hasUvProject = $false
                            $checkPath = $currentPath
                            $maxDepth = 3  # Check up to 3 parent directories
                            $depth = 0
                            
                            while ($depth -lt $maxDepth -and $checkPath) {
                                if ((Test-Path (Join-Path $checkPath "pyproject.toml") -ErrorAction SilentlyContinue) -or
                                    (Test-Path (Join-Path $checkPath ".python-version") -ErrorAction SilentlyContinue) -or
                                    (Test-Path (Join-Path $checkPath ".venv") -ErrorAction SilentlyContinue)) {
                                    $hasUvProject = $true
                                    break
                                }
                                
                                $parentPath = Split-Path -Parent $checkPath
                                if ($parentPath -eq $checkPath) {
                                    break  # Reached root
                                }
                                $checkPath = $parentPath
                                $depth++
                            }
                            
                            if ($hasUvProject) {
                                # Try to get Python version from uv
                                try {
                                    $pythonVersion = & uv python list --only-installed 2>&1 | Select-Object -First 1
                                    if ($pythonVersion -and $LASTEXITCODE -eq 0) {
                                        # Extract version number if available
                                        if ($pythonVersion -match '(\d+\.\d+\.\d+)') {
                                            $promptParts += "uv:py$($matches[1])"
                                        }
                                        else {
                                            $promptParts += "uv"
                                        }
                                    }
                                    else {
                                        $promptParts += "uv"
                                    }
                                }
                                catch {
                                    $promptParts += "uv"
                                }
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect uv project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # NPM project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_NPM = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_NPM) {
                    try {
                        if (Test-CachedCommand npm) {
                            # Check for package.json in current or parent directories
                            $hasNpmProject = $false
                            $checkPath = $currentPath
                            $maxDepth = 3  # Check up to 3 parent directories
                            $depth = 0
                            
                            while ($depth -lt $maxDepth -and $checkPath) {
                                if (Test-Path (Join-Path $checkPath "package.json") -ErrorAction SilentlyContinue) {
                                    $hasNpmProject = $true
                                    break
                                }
                                
                                $parentPath = Split-Path -Parent $checkPath
                                if ($parentPath -eq $checkPath) {
                                    break  # Reached root
                                }
                                $checkPath = $parentPath
                                $depth++
                            }
                            
                            if ($hasNpmProject) {
                                # Try to get Node version
                                try {
                                    $nodeVersion = & node --version 2>&1
                                    if ($nodeVersion -and $LASTEXITCODE -eq 0) {
                                        # Remove 'v' prefix if present
                                        $version = $nodeVersion.ToString().Trim() -replace '^v', ''
                                        $promptParts += "npm:node$version"
                                    }
                                    else {
                                        $promptParts += "npm"
                                    }
                                }
                                catch {
                                    $promptParts += "npm"
                                }
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect npm project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # Rust project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_RUST = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_RUST) {
                    try {
                        # Check for Cargo.toml in current or parent directories
                        $hasRustProject = $false
                        $checkPath = $currentPath
                        $maxDepth = 3  # Check up to 3 parent directories
                        $depth = 0
                        
                        while ($depth -lt $maxDepth -and $checkPath) {
                            if (Test-Path (Join-Path $checkPath "Cargo.toml") -ErrorAction SilentlyContinue) {
                                $hasRustProject = $true
                                break
                            }
                            
                            $parentPath = Split-Path -Parent $checkPath
                            if ($parentPath -eq $checkPath) {
                                break  # Reached root
                            }
                            $checkPath = $parentPath
                            $depth++
                        }
                        
                        if ($hasRustProject) {
                            # Try to get Rust version
                            try {
                                if (Test-CachedCommand rustc) {
                                    $rustVersion = & rustc --version 2>&1
                                    if ($rustVersion -and $LASTEXITCODE -eq 0) {
                                        # Extract version number if available (e.g., "rustc 1.75.0")
                                        if ($rustVersion -match 'rustc\s+(\d+\.\d+\.\d+)') {
                                            $promptParts += "rust:$($matches[1])"
                                        }
                                        else {
                                            $promptParts += "rust"
                                        }
                                    }
                                    else {
                                        $promptParts += "rust"
                                    }
                                }
                                else {
                                    $promptParts += "rust"
                                }
                            }
                            catch {
                                $promptParts += "rust"
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect Rust project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # Go project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_GO = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_GO) {
                    try {
                        # Check for go.mod in current or parent directories
                        $hasGoProject = $false
                        $checkPath = $currentPath
                        $maxDepth = 3  # Check up to 3 parent directories
                        $depth = 0
                        
                        while ($depth -lt $maxDepth -and $checkPath) {
                            if (Test-Path (Join-Path $checkPath "go.mod") -ErrorAction SilentlyContinue) {
                                $hasGoProject = $true
                                break
                            }
                            
                            $parentPath = Split-Path -Parent $checkPath
                            if ($parentPath -eq $checkPath) {
                                break  # Reached root
                            }
                            $checkPath = $parentPath
                            $depth++
                        }
                        
                        if ($hasGoProject) {
                            # Try to get Go version
                            try {
                                if (Test-CachedCommand go) {
                                    $goVersion = & go version 2>&1
                                    if ($goVersion -and $LASTEXITCODE -eq 0) {
                                        # Extract version number if available (e.g., "go version go1.21.5")
                                        if ($goVersion -match 'go(\d+\.\d+(?:\.\d+)?)') {
                                            $promptParts += "go:$($matches[1])"
                                        }
                                        else {
                                            $promptParts += "go"
                                        }
                                    }
                                    else {
                                        $promptParts += "go"
                                    }
                                }
                                else {
                                    $promptParts += "go"
                                }
                            }
                            catch {
                                $promptParts += "go"
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect Go project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # Docker project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_DOCKER = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_DOCKER) {
                    try {
                        # Check for Dockerfile or docker-compose.yml in current or parent directories
                        $hasDockerProject = $false
                        $checkPath = $currentPath
                        $maxDepth = 3  # Check up to 3 parent directories
                        $depth = 0
                        
                        while ($depth -lt $maxDepth -and $checkPath) {
                            if ((Test-Path (Join-Path $checkPath "Dockerfile") -ErrorAction SilentlyContinue) -or
                                (Test-Path (Join-Path $checkPath "docker-compose.yml") -ErrorAction SilentlyContinue) -or
                                (Test-Path (Join-Path $checkPath "docker-compose.yaml") -ErrorAction SilentlyContinue)) {
                                $hasDockerProject = $true
                                break
                            }
                            
                            $parentPath = Split-Path -Parent $checkPath
                            if ($parentPath -eq $checkPath) {
                                break  # Reached root
                            }
                            $checkPath = $parentPath
                            $depth++
                        }
                        
                        if ($hasDockerProject) {
                            $promptParts += "docker"
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect Docker project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # Poetry project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_POETRY = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_POETRY) {
                    try {
                        if (Test-CachedCommand poetry) {
                            # Check for poetry.lock or pyproject.toml (with poetry section) in current or parent directories
                            $hasPoetryProject = $false
                            $checkPath = $currentPath
                            $maxDepth = 3  # Check up to 3 parent directories
                            $depth = 0
                            
                            while ($depth -lt $maxDepth -and $checkPath) {
                                if ((Test-Path (Join-Path $checkPath "poetry.lock") -ErrorAction SilentlyContinue) -or
                                    (Test-Path (Join-Path $checkPath "pyproject.toml") -ErrorAction SilentlyContinue)) {
                                    $hasPoetryProject = $true
                                    break
                                }
                                
                                $parentPath = Split-Path -Parent $checkPath
                                if ($parentPath -eq $checkPath) {
                                    break  # Reached root
                                }
                                $checkPath = $parentPath
                                $depth++
                            }
                            
                            if ($hasPoetryProject) {
                                # Try to get Python version from poetry
                                try {
                                    $poetryEnvInfo = & poetry env info 2>&1
                                    if ($poetryEnvInfo -and $LASTEXITCODE -eq 0) {
                                        # Extract version number if available (e.g., "Python: 3.11.5")
                                        if ($poetryEnvInfo -match 'Python:\s*(\d+\.\d+\.\d+)') {
                                            $promptParts += "poetry:py$($matches[1])"
                                        }
                                        else {
                                            $promptParts += "poetry"
                                        }
                                    }
                                    else {
                                        $promptParts += "poetry"
                                    }
                                }
                                catch {
                                    $promptParts += "poetry"
                                }
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect Poetry project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # pnpm/yarn project detection - disabled by default to prevent slow prompts
                # Enable by setting $env:PS_PROFILE_SHOW_PNPM = '1' or 'true'
                if (Test-EnvBool $env:PS_PROFILE_SHOW_PNPM) {
                    try {
                        # Check for pnpm-lock.yaml or yarn.lock in current or parent directories
                        $hasPnpmProject = $false
                        $packageManager = $null
                        $checkPath = $currentPath
                        $maxDepth = 3  # Check up to 3 parent directories
                        $depth = 0
                        
                        while ($depth -lt $maxDepth -and $checkPath) {
                            if (Test-Path (Join-Path $checkPath "pnpm-lock.yaml") -ErrorAction SilentlyContinue) {
                                $hasPnpmProject = $true
                                $packageManager = "pnpm"
                                break
                            }
                            elseif (Test-Path (Join-Path $checkPath "yarn.lock") -ErrorAction SilentlyContinue) {
                                $hasPnpmProject = $true
                                $packageManager = "yarn"
                                break
                            }
                            
                            $parentPath = Split-Path -Parent $checkPath
                            if ($parentPath -eq $checkPath) {
                                break  # Reached root
                            }
                            $checkPath = $parentPath
                            $depth++
                        }
                        
                        if ($hasPnpmProject) {
                            # Try to get version
                            try {
                                if ($packageManager -eq "pnpm" -and (Test-CachedCommand pnpm)) {
                                    $pnpmVersion = & pnpm --version 2>&1
                                    if ($pnpmVersion -and $LASTEXITCODE -eq 0) {
                                        $version = $pnpmVersion.ToString().Trim()
                                        $promptParts += "pnpm:$version"
                                    }
                                    else {
                                        $promptParts += "pnpm"
                                    }
                                }
                                elseif ($packageManager -eq "yarn" -and (Test-CachedCommand yarn)) {
                                    $yarnVersion = & yarn --version 2>&1
                                    if ($yarnVersion -and $LASTEXITCODE -eq 0) {
                                        $version = $yarnVersion.ToString().Trim()
                                        $promptParts += "yarn:$version"
                                    }
                                    else {
                                        $promptParts += "yarn"
                                    }
                                }
                                else {
                                    $promptParts += $packageManager
                                }
                            }
                            catch {
                                $promptParts += $packageManager
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to detect pnpm/yarn project for prompt: $($_.Exception.Message)"
                        }
                    }
                }
                
                # Execution time (if available) - shows duration of the command that just completed
                if ($global:LastCommandDuration) {
                    $duration = $global:LastCommandDuration.TotalMilliseconds
                    if ($duration -gt 1000) {
                        $promptParts += ("{0:N0}ms" -f $duration)
                    }
                }
                
                # Admin indicator
                try {
                    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
                    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                        $promptParts += "🔑"
                    }
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Verbose "Failed to check administrator role for prompt: $($_.Exception.Message)"
                    }
                }
                
                # Display prompt
                $promptString = $promptParts -join " │ "
                Write-Host $promptString -NoNewline -ForegroundColor Cyan
                Write-Host "`n❯ " -NoNewline -ForegroundColor Green
                
                $global:LASTEXITCODE = $lastExitCode
                
                # Note: Timer for next command will be started by PreCommandLookupAction
                # when the user actually types a command. We don't start it here to avoid
                # measuring the time between prompts (which includes user thinking/typing time).
                
                return " "
            }
            catch {
                Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> " -NoNewline -ForegroundColor Yellow
                return " "
            }
        }
        
        # Track command execution time using PreCommandLookupAction
        # This fires when a command is about to execute, allowing us to measure actual execution time
        if (-not $global:SmartPromptCommandTrackingSetup) {
            $ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = {
                param($command, $eventArgs)
                # Only start timer if one isn't already running (prevents multiple starts for aliases)
                if (-not $global:CommandStartTime) {
                    $global:CommandStartTime = [DateTime]::Now
                }
            }
            $global:SmartPromptCommandTrackingSetup = $true
        }
        
        Set-Variable -Name "SmartPromptInitialized" -Value $true -Scope Global -Force
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Smart prompt initialized (Starship fallback)"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Initialize-SmartPrompt failed: $($_.Exception.Message)"
        }
    }
}

# Track command execution time using PostCommandLookupAction
# This fires AFTER command lookup/resolution but BEFORE actual execution begins
# This is more accurate than PreCommandLookupAction which fires too early (during parsing)
# PreCommandLookupAction would include time between commands, not just execution time
if (-not $global:SmartPromptCommandTrackingSetup) {
    $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
        param($command, $eventArgs)
        
        # CRITICAL: Use recursion guard to prevent infinite loops
        # This flag is set when we're already processing inside the handler
        if ($global:SmartPromptPostCommandLookupInProgress) {
            return
        }
        $global:SmartPromptPostCommandLookupInProgress = $true
        try {
            # Normalize command to string (handle both string and CommandInfo objects)
            $commandName = if ($command -is [string]) {
                $command
            }
            elseif ($command -is [System.Management.Automation.CommandInfo]) {
                $command.Name
            }
            else {
                $command.ToString()
            }
            
            # CRITICAL: Exclude output/logging commands FIRST to prevent infinite loops
            # These commands would trigger PostCommandLookupAction recursively
            $excludedCommands = @(
                'Write-Host', 'Write-Verbose', 'Write-Error', 'Write-Warning', 'Write-Output',
                'Write-Debug', 'Write-Information', 'Write-Progress',
                'Out-Host', 'Out-String', 'Out-Default',
                'Test-Path', 'Get-PSCallStack', 'Get-Command'
            )
            if ($commandName -in $excludedCommands) {
                return
            }
            
            # Skip timing for internal calls (commands called from within prompt/profile code)
            # Check call stack depth - if > 3, it's likely an internal call
            # Do this BEFORE any logging to avoid recursive calls
            # Use recursion guard when calling Get-PSCallStack to prevent re-entry
            $tempGuard = $global:SmartPromptPostCommandLookupInProgress
            $global:SmartPromptPostCommandLookupInProgress = $false
            try {
                $stackDepth = (Get-PSCallStack).Count
            }
            finally {
                $global:SmartPromptPostCommandLookupInProgress = $tempGuard
            }
            if ($stackDepth -gt 3) {
                return
            }
            
            # Also skip if we're currently in the prompt function (internal prompt calls)
            $tempGuard = $global:SmartPromptPostCommandLookupInProgress
            $global:SmartPromptPostCommandLookupInProgress = $false
            try {
                $callStack = Get-PSCallStack
                $isInPrompt = $callStack | Where-Object { $_.FunctionName -eq 'prompt' -or $_.ScriptName -like '*prompt*' -or $_.ScriptName -like '*SmartPrompt*' }
            }
            finally {
                $global:SmartPromptPostCommandLookupInProgress = $tempGuard
            }
            if ($isInPrompt) {
                return
            }
        
            # Now safe to do debug logging (after exclusions)
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 3) {
                    # Temporarily disable guard for Write-Host (it's excluded, but be safe)
                    $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                    $global:SmartPromptPostCommandLookupInProgress = $false
                    try {
                        Write-Host "  [prompt.timing] PostCommandLookupAction fired for command: $commandName" -ForegroundColor DarkGray
                    }
                    finally {
                        $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                    }
                }
            }
                    
            # Only start timer if one isn't already running (prevents multiple starts for aliases)
            if (-not $global:CommandStartTime) {
                try {
                    $global:CommandStartTime = [DateTime]::Now
                            
                    # Level 2: Log timer start
                    if ($debugLevel -ge 2) {
                        $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                        $global:SmartPromptPostCommandLookupInProgress = $false
                        try {
                            Write-Verbose "[prompt.timing] Started timer for command: $commandName"
                        }
                        finally {
                            $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                        }
                    }
                            
                    # Level 3: Detailed timer start information
                    if ($debugLevel -ge 3) {
                        $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                        $global:SmartPromptPostCommandLookupInProgress = $false
                        try {
                            Write-Host "  [prompt.timing] Timer started for '$commandName' at $($global:CommandStartTime.ToString('HH:mm:ss.fff'))" -ForegroundColor DarkGray
                        }
                        finally {
                            $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                        }
                    }
                }
                catch {
                    # Level 1: Log error
                    if ($debugLevel -ge 1) {
                        $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                        $global:SmartPromptPostCommandLookupInProgress = $false
                        try {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'prompt.timing' -Context @{
                                    operation = 'start_timer'
                                    command   = $commandName
                                }
                            }
                            else {
                                Write-Error "Failed to start command timer: $($_.Exception.Message)"
                            }
                        }
                        finally {
                            $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                        }
                    }
                            
                    # Level 2: More details
                    if ($debugLevel -ge 2) {
                        $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                        $global:SmartPromptPostCommandLookupInProgress = $false
                        try {
                            Write-Verbose "[prompt.timing] Error starting timer: $($_.Exception.Message)"
                        }
                        finally {
                            $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                        }
                    }
                            
                    # Level 3: Full error details
                    if ($debugLevel -ge 3) {
                        $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                        $global:SmartPromptPostCommandLookupInProgress = $false
                        try {
                            Write-Host "  [prompt.timing] Timer start error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Command: $commandName" -ForegroundColor DarkGray
                        }
                        finally {
                            $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                        }
                    }
                }
            }
            elseif ($debugLevel -ge 2) {
                $tempGuard = $global:SmartPromptPostCommandLookupInProgress
                $global:SmartPromptPostCommandLookupInProgress = $false
                try {
                    Write-Verbose "[prompt.timing] Timer already running, skipping start for command: $commandName"
                }
                finally {
                    $global:SmartPromptPostCommandLookupInProgress = $tempGuard
                }
            }
        }
        finally {
            $global:SmartPromptPostCommandLookupInProgress = $false
        }
    }
    $global:SmartPromptCommandTrackingSetup = $true
            
    # Level 1: Log setup completion
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
        Write-Verbose "[prompt.timing] Command tracking initialized using PostCommandLookupAction"
    }
}
