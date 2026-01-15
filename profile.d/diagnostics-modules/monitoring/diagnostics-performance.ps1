# ===============================================
# Performance insights diagnostic functions
# Command timing, performance tracking, and optimization suggestions
# ===============================================

<#
Command timing and performance insights for PowerShell profile.
Tracks command execution times and provides optimization suggestions.
#>

try {
    if ($null -ne (Get-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Initialize performance tracking
    if (-not $global:PSProfileCommandTimings) {
        $global:PSProfileCommandTimings = [System.Collections.Concurrent.ConcurrentDictionary[string, System.Collections.Generic.List[double]]]::new()
    }

    # Command timing tracker - ensure global scope for hook access
    if (-not (Test-Path "Function:\\global:Start-CommandTimer")) {
        <#
        .SYNOPSIS
            Tracks command execution performance and provides insights.
        .DESCRIPTION
            Monitors command execution times and maintains statistics for optimization insights.
            Automatically tracks commands that take longer than a threshold.
        #>
        $sbStart = {
            param([string]$CommandName)

            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 3) {
                    Write-Host "  [performance.timer] Starting timer for command: $CommandName" -ForegroundColor DarkGray
                }
            }

            try {
                $timer = [System.Diagnostics.Stopwatch]::StartNew()
                $startTime = [DateTime]::Now
                $global:PSProfileCommandTimer = @{
                    Name      = $CommandName
                    Timer     = $timer
                    StartTime = $startTime
                }
                
                # Level 2: Log timer start
                if ($debugLevel -ge 2) {
                    Write-Verbose "[performance.timer] Started timer for command: $CommandName"
                }
                
                # Level 3: Detailed timer start information
                if ($debugLevel -ge 3) {
                    Write-Host "  [performance.timer] Timer started for '$CommandName' at $($startTime.ToString('HH:mm:ss.fff'))" -ForegroundColor DarkGray
                }
            }
            catch {
                # Level 1: Log error
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'performance.timer.start' -Context @{
                            command = $CommandName
                        }
                    }
                    else {
                        Write-Error "Failed to start command timer: $($_.Exception.Message)"
                    }
                }
                
                # Level 2: More details
                if ($debugLevel -ge 2) {
                    Write-Verbose "[performance.timer] Error starting timer: $($_.Exception.Message)"
                }
                
                # Level 3: Full error details
                if ($debugLevel -ge 3) {
                    Write-Host "  [performance.timer] Timer start error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Command: $CommandName" -ForegroundColor DarkGray
                }
            }
        }
        # Create function in global scope explicitly
        Set-Item -Path "Function:\global:Start-CommandTimer" -Value $sbStart -Force | Out-Null
    }

    if (-not (Test-Path "Function:\\global:Stop-CommandTimer")) {
        # Try to import Command History Database module for persistent storage
        $commandHistoryModule = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'scripts' 'lib' 'database' 'CommandHistoryDatabase.psm1'
        $script:UseCommandHistoryDb = $false
        if ($commandHistoryModule -and (Test-Path -LiteralPath $commandHistoryModule)) {
            try {
                Import-Module $commandHistoryModule -DisableNameChecking -ErrorAction SilentlyContinue
                if (Get-Command Add-CommandHistory -ErrorAction SilentlyContinue) {
                    $script:UseCommandHistoryDb = $true
                }
            }
            catch {
                # Command history database not available, continue with in-memory only
            }
        }
        
        <#
        .SYNOPSIS
            Stops command timing and records the duration.
        .DESCRIPTION
            Stops the command timer and records the execution duration for analysis.
            Also records to persistent SQLite database if available.
        #>
        $sbStop = {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                # Debug level is available
            }

            if ($global:PSProfileCommandTimer) {
                # Only show debug message when there's actually a timer to stop
                if ($debugLevel -ge 3) {
                    Write-Host "  [performance.timer] Stopping command timer (if running)" -ForegroundColor DarkGray
                }
                try {
                    # Stop the timer immediately to get execution time as close as possible
                    $global:PSProfileCommandTimer.Timer.Stop()
                    $duration = $global:PSProfileCommandTimer.Timer.Elapsed.TotalMilliseconds
                    $commandName = $global:PSProfileCommandTimer.Name
                    $startTime = $global:PSProfileCommandTimer.StartTime
                    $endTime = [DateTime]::Now

                    # Level 2: Log timing information
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[performance.timer] Command execution completed: $commandName took ${duration}ms"
                    }
                    
                    # Level 3: Detailed timing breakdown
                    if ($debugLevel -ge 3) {
                        Write-Host "  [performance.timer] Execution time: ${duration}ms (started at $($startTime.ToString('HH:mm:ss.fff')), stopped at $($endTime.ToString('HH:mm:ss.fff')))" -ForegroundColor DarkGray
                    }

                    # Warn if timing seems incorrect (likely measuring time between commands)
                    if ($duration -gt 5000 -and $debugLevel -ge 1) {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Unusually long command execution time detected - may be measuring time between commands instead of execution time" -OperationName 'performance.timer' -Context @{
                                command      = $commandName
                                duration_ms  = $duration
                                start_time   = $startTime.ToString('o')
                                stop_time    = $endTime.ToString('o')
                                warning_code = 'TIMING_SUSPICIOUS'
                            } -Code 'TIMING_SUSPICIOUS'
                        }
                        else {
                            Write-Warning "Unusually long command execution time detected for '$commandName' (${duration}ms) - may be measuring time between commands instead of execution time"
                        }
                    }

                    # Record timing for analysis (in-memory)
                    if (-not $global:PSProfileCommandTimings.ContainsKey($commandName)) {
                        $global:PSProfileCommandTimings[$commandName] = [System.Collections.Generic.List[double]]::new()
                    }
                    $global:PSProfileCommandTimings[$commandName].Add($duration)

                    # Keep only last 100 timings per command to avoid memory bloat
                    if ($global:PSProfileCommandTimings[$commandName].Count -gt 100) {
                        $global:PSProfileCommandTimings[$commandName].RemoveAt(0)
                    }

                    # Record to persistent database if available
                    if ($script:UseCommandHistoryDb) {
                        try {
                            # Get the actual command line from history if available
                            $commandLine = $commandName
                            $lastHistory = Get-History -Count 1 -ErrorAction SilentlyContinue
                            if ($lastHistory) {
                                $commandLine = $lastHistory.CommandLine
                            }
                            
                            # Get exit code
                            $exitCode = if ($LASTEXITCODE) { $LASTEXITCODE } else { if ($?) { 0 } else { 1 } }
                            
                            Add-CommandHistory -CommandLine $commandLine -ExecutionTime $duration -ExitCode $exitCode -StartTime $startTime -EndTime $endTime
                            
                            # Level 3: Log database recording
                            if ($debugLevel -ge 3) {
                                Write-Host "  [performance.timer] Recorded to database: $commandLine" -ForegroundColor DarkGray
                            }
                        }
                        catch {
                            # Level 1: Log error
                            if ($debugLevel -ge 1) {
                                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                    Write-StructuredError -ErrorRecord $_ -OperationName 'performance.timer.database' -Context @{
                                        command      = $commandName
                                        command_line = $commandLine
                                    }
                                }
                                else {
                                    Write-Error "Failed to record command to database: $($_.Exception.Message)"
                                }
                            }
                            
                            # Level 2: More details
                            if ($debugLevel -ge 2) {
                                Write-Verbose "[performance.timer] Database recording error: $($_.Exception.Message)"
                            }
                            
                            # Level 3: Full error details
                            if ($debugLevel -ge 3) {
                                Write-Host "  [performance.timer] Database error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                            }
                        }
                    }

                    # Show timing for slow commands
                    # Note: This measurement includes minimal overhead from command lookup and prompt rendering
                    # For precise execution-only timing, use Measure-Command { command }
                    if ($duration -gt 1000) {
                        # Commands taking more than 1 second
                        # $duration is in milliseconds, convert to seconds
                        $durationSeconds = [Math]::Round($duration / 1000, 2)
                        # Use locale-aware number formatting if available
                        $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                            Format-LocaleNumber $durationSeconds -Format 'F2'
                        }
                        else {
                            $durationSeconds.ToString("F2")
                        }
                        Write-Host ("🐌 Slow command: {0} took {1}s" -f $commandName, $durationStr) -ForegroundColor Yellow
                    }

                    $global:PSProfileCommandTimer = $null
                }
                catch {
                    # Level 1: Log error
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'performance.timer.stop' -Context @{
                                command = if ($global:PSProfileCommandTimer) { $global:PSProfileCommandTimer.Name } else { 'unknown' }
                            }
                        }
                        else {
                            Write-Error "Failed to stop command timer: $($_.Exception.Message)"
                        }
                    }
                    
                    # Level 2: More details
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[performance.timer] Error stopping timer: $($_.Exception.Message)"
                    }
                    
                    # Level 3: Full error details
                    if ($debugLevel -ge 3) {
                        Write-Host "  [performance.timer] Timer stop error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                    }
                    
                    # Clear timer on error to prevent stale state
                    $global:PSProfileCommandTimer = $null
                }
            }
            # Suppress "No active timer to stop" message - it's not useful and creates noise during profile reload
        }
        # Create function in global scope explicitly
        Set-Item -Path "Function:\global:Stop-CommandTimer" -Value $sbStop -Force | Out-Null
    }

    # Performance insights and analysis
    <#
    .SYNOPSIS
        Shows performance insights for command execution.
    .DESCRIPTION
        Analyzes command execution times and provides optimization suggestions.
        Shows slowest commands, trends, and potential improvements.
    #>
    function Show-PerformanceInsights {
        Write-Host "⚡ Performance Insights" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan

        if (-not $global:PSProfileCommandTimings -or $global:PSProfileCommandTimings.Count -eq 0) {
            Write-Host "No command timing data collected yet."
            Write-Host "Commands will be tracked automatically as you use them."
            return
        }

        # Calculate statistics for each command
        $commandStats = @()
        foreach ($entry in $global:PSProfileCommandTimings.GetEnumerator()) {
            $timings = $entry.Value
            if ($timings.Count -gt 0) {
                $avg = $timings | Measure-Object -Average | Select-Object -ExpandProperty Average
                $max = $timings | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
                $count = $timings.Count

                $commandStats += [PSCustomObject]@{
                    Command    = $entry.Key
                    AvgTime    = $avg
                    MaxTime    = $max
                    Executions = $count
                    TotalTime  = $avg * $count
                }
            }
        }

        if ($commandStats.Count -eq 0) {
            Write-Host "No timing statistics available."
            return
        }

        # Show slowest commands
        Write-Host "`n🐌 Slowest Commands (by average execution time):" -ForegroundColor Yellow
        $commandStats |
        Where-Object { $_.AvgTime -gt 100 } |  # Only show commands that take > 100ms on average
        Sort-Object -Property AvgTime -Descending |
        Select-Object -First 10 |
        Format-Table -Property @{
            Name       = "Command"
            Expression = { $_.Command }
            Width      = 25
        }, @{
            Name       = "Avg Time"
            Expression = { "{0:N0}ms" -f $_.AvgTime }
            Width      = 10
            Alignment  = "Right"
        }, @{
            Name       = "Max Time"
            Expression = { "{0:N0}ms" -f $_.MaxTime }
            Width      = 10
            Alignment  = "Right"
        }, @{
            Name       = "Executions"
            Expression = { $_.Executions }
            Width      = 10
            Alignment  = "Right"
        } -AutoSize

        # Show most executed commands
        Write-Host "`n🔄 Most Executed Commands:" -ForegroundColor Green
        $commandStats |
        Sort-Object -Property Executions -Descending |
        Select-Object -First 10 |
        Format-Table -Property @{
            Name       = "Command"
            Expression = { $_.Command }
            Width      = 25
        }, @{
            Name       = "Executions"
            Expression = { $_.Executions }
            Width      = 10
            Alignment  = "Right"
        }, @{
            Name       = "Avg Time"
            Expression = { "{0:N0}ms" -f $_.AvgTime }
            Width      = 10
            Alignment  = "Right"
        } -AutoSize

        # Show optimization suggestions
        Write-Host "`n💡 Optimization Suggestions:" -ForegroundColor Magenta

        $slowCommands = $commandStats | Where-Object { $_.AvgTime -gt 500 } | Sort-Object -Property TotalTime -Descending
        if ($slowCommands) {
            Write-Host "• Consider optimizing these frequently slow commands:"
            $slowCommands | Select-Object -First 5 | ForEach-Object {
                $avgTimeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $_.AvgTime -Format 'N0'
                }
                else {
                    $_.AvgTime.ToString("N0")
                }
                $totalTimeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber ($_.TotalTime / 1000) -Format 'N1'
                }
                else {
                    ($_.TotalTime / 1000).ToString("N1")
                }
                Write-Host ("  - {0} (avg: {1}ms, total impact: {2}s)" -f $_.Command, $avgTimeStr, $totalTimeStr)
            }
        }

        $frequentCommands = $commandStats | Where-Object { $_.Executions -gt 10 -and $_.AvgTime -gt 50 }
        if ($frequentCommands) {
            Write-Host "• Consider caching or optimizing these frequently used commands:"
            $frequentCommands | Sort-Object -Property Executions -Descending | Select-Object -First 5 | ForEach-Object {
                $avgTimeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $_.AvgTime -Format 'N0'
                }
                else {
                    $_.AvgTime.ToString("N0")
                }
                Write-Host ("  - {0} (used {1} times, avg: {2}ms)" -f $_.Command, $_.Executions, $avgTimeStr)
            }
        }

        # Show memory usage
        $estimatedMemory = $global:PSProfileCommandTimings.Count * 200  # Rough estimate per command entry
        $memoryKBStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber ([math]::Round($estimatedMemory / 1024, 1)) -Format 'N1'
        }
        else {
            [math]::Round($estimatedMemory / 1024, 1).ToString("N1")
        }
        Write-Host ("`n📊 Tracking {0} commands, estimated memory usage: ~{1} KB" -f $global:PSProfileCommandTimings.Count, $memoryKBStr)
    }

    # Quick performance check
    <#
    .SYNOPSIS
        Performs a quick performance check of the current session.
    .DESCRIPTION
        Shows current memory usage, command count, and basic performance metrics.
    #>
    function Test-PerformanceHealth {
        Write-Host "🏥 Performance Health Check" -ForegroundColor Blue
        Write-Host "===========================" -ForegroundColor Blue

        # Memory usage
        try {
            $process = Get-Process -Id $PID -ErrorAction Stop
            $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 1)
            Write-Host ("Memory usage: {0} MB" -f $memoryMB)
        }
        catch {
            Write-Host "Memory usage: Unable to retrieve process information" -ForegroundColor Yellow
        }

        # Command count
        $commandCount = $global:PSProfileCommandTimings.Count
        Write-Host ("Tracked commands: {0}" -f $commandCount)

        # Profile load time (if available)
        if ($global:PSProfileStartTime) {
            $uptime = [DateTime]::Now - $global:PSProfileStartTime
            $uptimeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $uptime.TotalMinutes -Format 'N1'
            }
            else {
                $uptime.TotalMinutes.ToString("N1")
            }
            Write-Host ("Profile uptime: {0} minutes" -f $uptimeStr)
        }

        # Performance rating
        $rating = if ($memoryMB -lt 100) { "Excellent" }
        elseif ($memoryMB -lt 200) { "Good" }
        elseif ($memoryMB -lt 300) { "Fair" }
        else { "Needs optimization" }

        Write-Host ("Performance rating: {0}" -f $rating)

        if ($rating -eq "Needs optimization") {
            Write-Host "`n💡 Consider running 'Show-PerformanceInsights' for optimization suggestions."
        }
    }

    # Clear performance data
    <#
    .SYNOPSIS
        Clears all collected performance data.
    .DESCRIPTION
        Removes all command timing data and resets performance tracking.
    #>
    function Clear-PerformanceData {
        $global:PSProfileCommandTimings = [System.Collections.Concurrent.ConcurrentDictionary[string, System.Collections.Generic.List[double]]]::new()
        Write-Host "🧹 Performance data cleared."
    }

    # Auto-track commands (integrate with prompt or InvokeCommand events)
    # Set up command tracking regardless of prompt framework
    if (-not $global:PSProfileCommandTrackingSetup) {
        # Use PostCommandLookupAction to start timing right before command execution
        # This fires after command lookup/resolution but before actual execution begins
        # This is more accurate than PreCommandLookupAction which fires too early (during parsing)
        # PreCommandLookupAction would include time between commands, not just execution time
        $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
            param($command, $eventArgs)
            
            # CRITICAL: Use recursion guard to prevent infinite loops
            # This flag is set when we're already processing inside the handler
            if ($global:PSProfilePostCommandLookupInProgress) {
                return
            }
            $global:PSProfilePostCommandLookupInProgress = $true
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
                # Depth 0 = PostCommandLookupAction itself, Depth 1 = command invocation, Depth 2+ = internal calls
                # Do this BEFORE any logging to avoid recursive calls
                # Use recursion guard when calling Get-PSCallStack to prevent re-entry
                $tempGuard = $global:PSProfilePostCommandLookupInProgress
                $global:PSProfilePostCommandLookupInProgress = $false
                try {
                    $stackDepth = (Get-PSCallStack).Count
                }
                finally {
                    $global:PSProfilePostCommandLookupInProgress = $tempGuard
                }
                if ($stackDepth -gt 3) {
                    return
                }
                
                # Also skip if we're currently in the prompt function (internal prompt calls)
                $tempGuard = $global:PSProfilePostCommandLookupInProgress
                $global:PSProfilePostCommandLookupInProgress = $false
                try {
                    $callStack = Get-PSCallStack
                    $isInPrompt = $callStack | Where-Object { $_.FunctionName -eq 'prompt' -or $_.ScriptName -like '*prompt*' -or $_.ScriptName -like '*diagnostics-performance*' }
                }
                finally {
                    $global:PSProfilePostCommandLookupInProgress = $tempGuard
                }
                if ($isInPrompt) {
                    return
                }
                
                # Now safe to do debug logging (after exclusions)
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 3) {
                        # Temporarily disable guard for Write-Host (it's excluded, but be safe)
                        $tempGuard = $global:PSProfilePostCommandLookupInProgress
                        $global:PSProfilePostCommandLookupInProgress = $false
                        try {
                            Write-Host "  [performance.tracking] PostCommandLookupAction fired for command: $commandName" -ForegroundColor DarkGray
                        }
                        finally {
                            $global:PSProfilePostCommandLookupInProgress = $tempGuard
                        }
                    }
                }
                
                # Only start timer if one isn't already running (prevents multiple starts for aliases)
                if (-not $global:PSProfileCommandTimer) {
                    try {
                        Start-CommandTimer -CommandName $commandName
                    }
                    catch {
                        # Level 1: Log error
                        if ($debugLevel -ge 1) {
                            $tempGuard = $global:PSProfilePostCommandLookupInProgress
                            $global:PSProfilePostCommandLookupInProgress = $false
                            try {
                                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                    Write-StructuredError -ErrorRecord $_ -OperationName 'performance.tracking.start' -Context @{
                                        command = $commandName
                                    }
                                }
                                else {
                                    Write-Error "Failed to start command timer: $($_.Exception.Message)"
                                }
                            }
                            finally {
                                $global:PSProfilePostCommandLookupInProgress = $tempGuard
                            }
                        }
                        
                        # Level 2: More details
                        if ($debugLevel -ge 2) {
                            $tempGuard = $global:PSProfilePostCommandLookupInProgress
                            $global:PSProfilePostCommandLookupInProgress = $false
                            try {
                                Write-Verbose "[performance.tracking] Error starting timer: $($_.Exception.Message)"
                            }
                            finally {
                                $global:PSProfilePostCommandLookupInProgress = $tempGuard
                            }
                        }
                        
                        # Level 3: Full error details
                        if ($debugLevel -ge 3) {
                            $tempGuard = $global:PSProfilePostCommandLookupInProgress
                            $global:PSProfilePostCommandLookupInProgress = $false
                            try {
                                Write-Host "  [performance.tracking] Timer start error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Command: $commandName" -ForegroundColor DarkGray
                            }
                            finally {
                                $global:PSProfilePostCommandLookupInProgress = $tempGuard
                            }
                        }
                    }
                }
                elseif ($debugLevel -ge 2) {
                    $tempGuard = $global:PSProfilePostCommandLookupInProgress
                    $global:PSProfilePostCommandLookupInProgress = $false
                    try {
                        Write-Verbose "[performance.tracking] Timer already running, skipping start for command: $commandName"
                    }
                    finally {
                        $global:PSProfilePostCommandLookupInProgress = $tempGuard
                    }
                }
            }
            finally {
                $global:PSProfilePostCommandLookupInProgress = $false
            }
        }

        $global:PSProfileCommandTrackingSetup = $true
        
        # Level 1: Log setup completion
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
            Write-Verbose "[performance.tracking] Command tracking initialized using PostCommandLookupAction"
        }
    }

    <#
    .SYNOPSIS
        Wraps the current prompt function with performance timing.
    
    .DESCRIPTION
        Wraps the active prompt function (Starship, Oh-My-Posh, or default) with
        performance timing functionality. This function can be called multiple times
        to re-wrap the prompt after prompt frameworks initialize, ensuring performance
        insights work correctly with any prompt system.
    
    .NOTES
        This function is called automatically when the performance insights fragment loads,
        and should be called again after Starship or other prompt frameworks initialize
        to ensure the wrapper captures the final prompt function.
    
    .EXAMPLE
        Update-PerformanceInsightsPrompt
        
        Wraps the current prompt function with performance timing.
    #>
    function Update-PerformanceInsightsPrompt {
        $currentPrompt = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
        if ($currentPrompt) {
            # Check if this is already our wrapper (avoid double-wrapping)
            $promptScript = $currentPrompt.ScriptBlock.ToString()
            if ($promptScript -match 'PSProfileCommandTimer|Start-CommandTimer') {
                # Already wrapped, just update the stored prompt
                if (-not $global:PSProfileOriginalPrompt) {
                    # Extract the original prompt from the wrapper if possible
                    # For now, just store the current prompt as-is
                    $global:PSProfileOriginalPrompt = $currentPrompt.ScriptBlock
                }
                return
            }
            
            # Store the current prompt function as a script block
            $global:PSProfileOriginalPrompt = $currentPrompt.ScriptBlock
        }
        else {
            # Fallback to default prompt if none exists
            if (-not $global:PSProfileOriginalPrompt) {
                $global:PSProfileOriginalPrompt = {
                    "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                }
            }
        }

        # Enhanced prompt with timing that wraps the existing prompt
        function global:prompt {
            # Stop timer IMMEDIATELY at the start of prompt (before any prompt rendering)
            # This minimizes the overhead from output rendering and prompt generation
            # The timer was started in PostCommandLookupAction (just before execution)
            # so this measures: execution time + minimal prompt overhead
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                # Debug level is available
            }
            
            if ($global:PSProfileCommandTimer) {
                # Only show debug message when there's actually a timer to stop
                if ($debugLevel -ge 3) {
                    Write-Host "  [performance.prompt] Stopping command timer (if running)" -ForegroundColor DarkGray
                }
                
                try {
                    Stop-CommandTimer
                }
                catch {
                    # Level 1: Log error
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'performance.prompt' -Context @{
                                operation = 'stop_timer'
                            }
                        }
                        else {
                            Write-Error "Failed to stop command timer in prompt: $($_.Exception.Message)"
                        }
                    }
                    
                    # Level 2: More details
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[performance.prompt] Error stopping timer: $($_.Exception.Message)"
                    }
                    
                    # Level 3: Full error details
                    if ($debugLevel -ge 3) {
                        Write-Host "  [performance.prompt] Timer stop error - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                    }
                }
            }
            # Suppress "No active timer to stop" message - it's not useful and creates noise during profile reload

            # Call original prompt (works with Starship, Oh-My-Posh, or default)
            if ($global:PSProfileOriginalPrompt) {
                & $global:PSProfileOriginalPrompt
            }
            else {
                "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
            }

            # Note: We don't start a timer here because PostCommandLookupAction will handle it
            # when a command is about to execute. Starting a timer here would measure
            # the time between prompts, not command execution time.
        }
    }

    # Initial wrap of the current prompt
    Update-PerformanceInsightsPrompt

    # Export the function so it can be called after Starship initializes
    # Ensure function is available in global scope
    if (-not (Get-Command Update-PerformanceInsightsPrompt -Scope Global -ErrorAction SilentlyContinue)) {
        # Copy function to global scope
        $null = New-Item -Path 'Function:\global:Update-PerformanceInsightsPrompt' -Value $function:Update-PerformanceInsightsPrompt -Force -ErrorAction SilentlyContinue
    }

    Set-Variable -Name 'PerformanceInsightsLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Performance insights fragment failed: $($_.Exception.Message)" }
}


