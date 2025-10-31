<#
# 73-performance-insights.ps1

Command timing and performance insights for PowerShell profile.
Tracks command execution times and provides optimization suggestions.
#>

try {
    if ($null -ne (Get-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Initialize performance tracking
    if (-not $global:PSProfileCommandTimings) {
        $global:PSProfileCommandTimings = [System.Collections.Concurrent.ConcurrentDictionary[string, System.Collections.Generic.List[double]]]::new()
    }

    # Command timing tracker
    <#
    .SYNOPSIS
        Tracks command execution performance and provides insights.
    .DESCRIPTION
        Monitors command execution times and maintains statistics for optimization insights.
        Automatically tracks commands that take longer than a threshold.
    #>
    function Start-CommandTimer {
        param([string]$CommandName)

        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $global:PSProfileCommandTimer = @{
            Name  = $CommandName
            Timer = $timer
        }
    }

    <#
    .SYNOPSIS
        Stops command timing and records the duration.
    .DESCRIPTION
        Stops the command timer and records the execution duration for analysis.
    #>
    function Stop-CommandTimer {
        if ($global:PSProfileCommandTimer) {
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
            if ($duration -gt 1000) {
                # Commands taking more than 1 second
                Write-Host ("🐌 Slow command: {0} took {1:N2}s" -f $commandName, ($duration / 1000)) -ForegroundColor Yellow
            }

            $global:PSProfileCommandTimer = $null
        }
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
                Write-Host ("  - {0} (avg: {1:N0}ms, total impact: {2:N1}s)" -f $_.Command, $_.AvgTime, ($_.TotalTime / 1000))
            }
        }

        $frequentCommands = $commandStats | Where-Object { $_.Executions -gt 10 -and $_.AvgTime -gt 50 }
        if ($frequentCommands) {
            Write-Host "• Consider caching or optimizing these frequently used commands:"
            $frequentCommands | Sort-Object -Property Executions -Descending | Select-Object -First 5 | ForEach-Object {
                Write-Host ("  - {0} (used {1} times, avg: {2:N0}ms)" -f $_.Command, $_.Executions, $_.AvgTime)
            }
        }

        # Show memory usage
        $estimatedMemory = $global:PSProfileCommandTimings.Count * 200  # Rough estimate per command entry
        Write-Host ("`n📊 Tracking {0} commands, estimated memory usage: ~{1} KB" -f $global:PSProfileCommandTimings.Count, [math]::Round($estimatedMemory / 1024, 1))
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
        $process = Get-Process -Id $PID
        $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 1)
        Write-Host ("Memory usage: {0} MB" -f $memoryMB)

        # Command count
        $commandCount = $global:PSProfileCommandTimings.Count
        Write-Host ("Tracked commands: {0}" -f $commandCount)

        # Profile load time (if available)
        if ($global:PSProfileStartTime) {
            $uptime = [DateTime]::Now - $global:PSProfileStartTime
            Write-Host ("Profile uptime: {0:N1} minutes" -f $uptime.TotalMinutes)
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

    # Auto-track commands (integrate with prompt)
    if (-not $global:PSProfileOriginalPrompt) {
        $global:PSProfileOriginalPrompt = $function:prompt
    }

    # Enhanced prompt with timing
    function global:prompt {
        # Stop any running timer
        if ($global:PSProfileCommandTimer) {
            Stop-CommandTimer
        }

        # Call original prompt
        if ($global:PSProfileOriginalPrompt) {
            & $global:PSProfileOriginalPrompt
        }
        else {
            "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        }

        # Start timing for next command
        Start-CommandTimer -CommandName "prompt"
    }

    Set-Variable -Name 'PerformanceInsightsLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Performance insights fragment failed: $($_.Exception.Message)" }
}
