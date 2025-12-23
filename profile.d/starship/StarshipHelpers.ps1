# ===============================================
# StarshipHelpers.ps1
# Starship helper functions for testing and configuration
# ===============================================

<#
.SYNOPSIS
    Tests if Starship is already initialized.
.DESCRIPTION
    Checks if the current prompt function is a Starship prompt by examining the script block.
.OUTPUTS
    System.Boolean
#>
function Test-StarshipInitialized {
    $promptCmd = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
    if (-not $promptCmd) { return $false }
    
    # Check script block for Starship-specific patterns
    $script = $promptCmd.ScriptBlock.ToString()
    return ($script -match 'starship|Invoke-Native|Invoke-Starship')
}

<#
.SYNOPSIS
    Checks if a prompt function needs replacement.
.DESCRIPTION
    Module-scoped prompts can break when modules are unloaded, so we replace them
    with direct function calls to the starship executable for reliability.
.PARAMETER PromptCmd
    The prompt function to check.
.OUTPUTS
    System.Boolean
#>
function Test-PromptNeedsReplacement {
    param([System.Management.Automation.FunctionInfo]$PromptCmd)
    
    if ($PromptCmd.ModuleName -eq 'starship') { return $true }
    $script = $PromptCmd.ScriptBlock.ToString()
    if ($script -match 'Invoke-Native') { return $true }
    return $false
}

<#
.SYNOPSIS
    Builds arguments array for starship prompt command.
.DESCRIPTION
    Constructs the command-line arguments that Starship needs to render the prompt,
    including terminal width, job count, command status, and execution duration.
.PARAMETER LastCommandSucceeded
    Whether the last command succeeded.
.PARAMETER LastExitCode
    The exit code of the last command.
.OUTPUTS
    System.String[]
#>
function Get-StarshipPromptArguments {
    param(
        [bool]$LastCommandSucceeded,
        [int]$LastExitCode
    )
    
    $arguments = @("prompt")
    
    # Terminal width
    $width = 80
    try {
        if ($Host.UI.RawUI.WindowSize.Width) {
            $width = $Host.UI.RawUI.WindowSize.Width
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Failed to get terminal width: $($_.Exception.Message)"
        }
    }
    $arguments += "--terminal-width=$width"
    
    # Job count - with timeout protection to prevent hanging
    # Cache job count to avoid repeated expensive Get-Job calls
    $cacheKey = 'StarshipJobCount'
    $cacheTimeKey = 'StarshipJobCountTime'
    $cacheTimeout = 2  # Cache for 2 seconds
    
    $jobs = 0
    try {
        $now = Get-Date
        $cachedTime = Get-Variable -Name $cacheTimeKey -Scope Global -ErrorAction SilentlyContinue
        $cachedCount = Get-Variable -Name $cacheKey -Scope Global -ErrorAction SilentlyContinue
        
        # Use cached value if available and recent
        if ($cachedTime -and $cachedCount -and 
            ($now - $cachedTime.Value).TotalSeconds -lt $cacheTimeout) {
            $jobs = $cachedCount.Value
        }
        else {
            # Get fresh job count with timeout protection
            # Use a background job with timeout to prevent hanging
            $jobCountScript = {
                param($timeoutSeconds)
                $startTime = Get-Date
                $jobs = @()
                try {
                    # Try to get jobs with a timeout
                    $jobs = Get-Job -ErrorAction SilentlyContinue
                    $elapsed = (Get-Date) - $startTime
                    if ($elapsed.TotalSeconds -gt $timeoutSeconds) {
                        return 0
                    }
                    # Optimized: Single-pass counting instead of Where-Object
                    $runningCount = 0
                    foreach ($job in $jobs) {
                        if ($job.State -eq 'Running') {
                            $runningCount++
                        }
                    }
                    return $runningCount
                }
                catch {
                    return 0
                }
            }
            
            # Use runspace for job count (much faster than job)
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
            $runspacePool.Open()
            $powershell = [PowerShell]::Create()
            $powershell.RunspacePool = $runspacePool
            $null = $powershell.AddScript($jobCountScript)
            $null = $powershell.AddArgument(0.5)
            $handle = $powershell.BeginInvoke()
            
            # Wait with timeout using polling
            $timeoutMs = 1000
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
            
            if ($completed) {
                try {
                    $jobs = $powershell.EndInvoke($handle)
                    if ($null -eq $jobs) { $jobs = 0 }
                }
                catch {
                    $jobs = if ($cachedCount) { $cachedCount.Value } else { 0 }
                }
            }
            else {
                # Timeout occurred, stop and use cached/default value
                $powershell.Stop()
                $jobs = if ($cachedCount) { $cachedCount.Value } else { 0 }
            }
            
            $powershell.Dispose()
            $runspacePool.Close()
            $runspacePool.Dispose()
            
            # Update cache
            Set-Variable -Name $cacheKey -Value $jobs -Scope Global -Force
            Set-Variable -Name $cacheTimeKey -Value $now -Scope Global -Force
        }
    }
    catch {
        # Fallback: use cached value or default to 0
        $cachedCount = Get-Variable -Name $cacheKey -Scope Global -ErrorAction SilentlyContinue
        $jobs = if ($cachedCount) { $cachedCount.Value } else { 0 }
    }
    $arguments += "--jobs=$jobs"
    
    # Command status and duration from history
    $lastCmd = Get-History -Count 1 -ErrorAction SilentlyContinue
    if ($lastCmd) {
        $status = if ($LastCommandSucceeded) { 0 } else { 1 }
        $arguments += "--status=$status"
        
        try {
            $duration = [math]::Round(($lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime).TotalMilliseconds)
            $arguments += "--cmd-duration=$duration"
        }
        catch {
            $arguments += "--cmd-duration=0"
        }
    }
    else {
        $arguments += "--status=0"
    }
    
    return $arguments
}

