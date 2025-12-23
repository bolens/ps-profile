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

            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $global:PSProfileCommandTimer = @{
                Name  = $CommandName
                Timer = $timer
            }
        }
        # Create function in global scope explicitly
        Set-Item -Path "Function:\global:Start-CommandTimer" -Value $sbStart -Force | Out-Null
    }

    if (-not (Test-Path "Function:\\global:Stop-CommandTimer")) {
        <#
        .SYNOPSIS
            Stops command timing and records the duration.
        .DESCRIPTION
            Stops the command timer and records the execution duration for analysis.
        #>
        $sbStop = {
            if ($global:PSProfileCommandTimer) {
                # Stop the timer immediately to get execution time as close as possible
                $global:PSProfileCommandTimer.Timer.Stop()
                $duration = $global:PSProfileCommandTimer.Timer.Elapsed.TotalMilliseconds
                $commandName = $global:PSProfileCommandTimer.Name

                # Record timing for analysis
                if (-not $global:PSProfileCommandTimings.ContainsKey($commandName)) {
                    $global:PSProfileCommandTimings[$commandName] = [System.Collections.Generic.List[double]]::new()
                }
                $global:PSProfileCommandTimings[$commandName].Add($duration)

                # Keep only last 100 timings per command to avoid memory bloat
                if ($global:PSProfileCommandTimings[$commandName].Count -gt 100) {
                    $global:PSProfileCommandTimings[$commandName].RemoveAt(0)
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
        $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
            param($command, $eventArgs)
            
            # Skip timing for internal calls (commands called from within prompt/profile code)
            # Check call stack depth - if > 2, it's likely an internal call
            # Depth 0 = PostCommandLookupAction itself, Depth 1 = command invocation, Depth 2+ = internal calls
            $stackDepth = (Get-PSCallStack).Count
            if ($stackDepth -gt 3) {
                # This is likely an internal call from prompt/profile code, skip timing
                return
            }
            
            # Also skip if we're currently in the prompt function (internal prompt calls)
            $callStack = Get-PSCallStack
            $isInPrompt = $callStack | Where-Object { $_.FunctionName -eq 'prompt' -or $_.ScriptName -like '*prompt*' -or $_.ScriptName -like '*diagnostics-performance*' }
            if ($isInPrompt) {
                # This is a call from within the prompt or performance monitoring code itself, skip
                return
            }
            
            # Exclude Test-Path from measurements (too frequent and not meaningful for performance insights)
            if ($command -eq 'Test-Path') {
                return
            }
            
            # Only start timer if one isn't already running (prevents multiple starts for aliases)
            if (-not $global:PSProfileCommandTimer) {
                Start-CommandTimer -CommandName $command
            }
        }

        $global:PSProfileCommandTrackingSetup = $true
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
            if ($global:PSProfileCommandTimer) {
                Stop-CommandTimer
            }

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

