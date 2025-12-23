# ===============================================
# Enhanced history utility functions
# Advanced history search, navigation, and management
# ===============================================

try {
    if ($null -ne (Get-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Enhanced history search with fuzzy matching
    <#
    .SYNOPSIS
        Performs fuzzy search on command history.
    .DESCRIPTION
        Searches through PowerShell command history using fuzzy matching.
        Supports partial matches and shows results with context.
    .PARAMETER Pattern
        The search pattern to match against history.
    .PARAMETER CaseSensitive
        If specified, performs case-sensitive search.
    .PARAMETER MaxResults
        Maximum number of results to return (default: 20).
    #>
    function Find-HistoryFuzzy {
        param(
            [string]$Pattern,
            [switch]$CaseSensitive,
            [int]$MaxResults = 20
        )

        if (-not $Pattern) {
            Write-Warning "Please provide a search pattern."
            return
        }

        $history = Get-History
        if (-not $history) {
            Write-Host "No command history available."
            return
        }

        # Limit history to last 500 items for performance and safety
        $history = $history | Select-Object -Last 500

        # Simple substring matching (much safer than complex patterns)
        $fuzzyMatches = $history | Where-Object {
            $cmd = $_.CommandLine
            if (-not $CaseSensitive) {
                $cmd.ToLower().Contains($Pattern.ToLower())
            }
            else {
                $cmd.Contains($Pattern)
            }
        } | Select-Object -First $MaxResults

        if ($fuzzyMatches.Count -eq 0) {
            Write-Host "No matches found for pattern: $Pattern"
            return
        }

        Write-Host "🔍 Fuzzy search results for '$Pattern' ($($fuzzyMatches.Count) matches):" -ForegroundColor Cyan
        Write-Host ""

        try {
            $fuzzyMatches | Format-Table -Property @(
                @{
                    Name       = "Id"
                    Expression = { $_.Id }
                    Width      = 5
                    Alignment  = "Right"
                },
                @{
                    Name       = "Command"
                    Expression = {
                        $cmd = $_.CommandLine
                        if ($cmd.Length -gt 80) {
                            $cmd.Substring(0, 77) + "..."
                        }
                        else {
                            $cmd
                        }
                    }
                    Width      = 80
                },
                @{
                    Name       = "Time"
                    Expression = {
                        if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                            Format-LocaleDate $_.StartExecutionTime -Format 'HH:mm:ss'
                        }
                        else {
                            $_.StartExecutionTime.ToString("HH:mm:ss")
                        }
                    }
                    Width      = 8
                }
            ) -AutoSize
        }
        catch {
            # Fallback to simple output if Format-Table fails
            Write-Host "Error displaying results, showing simple list:" -ForegroundColor Yellow
            $fuzzyMatches | ForEach-Object {
                $cmd = $_.CommandLine
                if ($cmd.Length -gt 60) {
                    $cmd = $cmd.Substring(0, 57) + "..."
                }
                $timeStr = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                    Format-LocaleDate $_.StartExecutionTime -Format 'HH:mm:ss'
                }
                else {
                    $_.StartExecutionTime.ToString("HH:mm:ss")
                }
                Write-Host ("{0,5} {1} {2}" -f $_.Id, $cmd, $timeStr)
            }
        }
    }

    # Quick history search - optimized implementation
    <#
    .SYNOPSIS
        Quick search in command history.
    .DESCRIPTION
        Searches command history for the specified pattern.
    #>
    function Find-HistoryQuick {
        param([string]$Pattern)

        if (-not $Pattern) {
            Write-Warning "Please provide a search pattern."
            return
        }

        $history = Get-History | Select-Object -Last 200  # Limit for performance
        if (-not $history -or $history.Count -eq 0) {
            Write-Host "No command history available."
            return
        }

        # Use efficient array operations
        $matches = @()
        foreach ($item in $history) {
            if ($item.CommandLine -like "*$Pattern*") {
                $matches += $item
                if ($matches.Count -ge 10) { break }  # Limit results
            }
        }

        if ($matches.Count -eq 0) {
            Write-Host "No matches found for: $Pattern"
            return
        }

        Write-Host "Search results for '$Pattern' ($($matches.Count) matches):" -ForegroundColor Cyan
        foreach ($item in $matches) {
            $cmd = $item.CommandLine
            if ($cmd.Length -gt 60) { $cmd = $cmd.Substring(0, 57) + "..." }
            Write-Host ("{0,5} {1}" -f $item.Id, $cmd)
        }
    }
    Set-Alias -Name fh -Value Find-HistoryQuick -ErrorAction SilentlyContinue

    # History statistics and insights
    <#
    .SYNOPSIS
        Shows statistics about command history usage.
    .DESCRIPTION
        Analyzes command history and shows usage patterns, frequently used commands,
        and time-based statistics.
    #>
    function Show-HistoryStats {
        $history = Get-History
        if (-not $history) {
            Write-Host "No command history available."
            return
        }

        Write-Host "📊 History Statistics" -ForegroundColor Green
        Write-Host "===================" -ForegroundColor Green

        # Basic stats
        $totalCommands = $history.Count
        $oldestCommand = $history | Sort-Object StartExecutionTime | Select-Object -First 1
        $newestCommand = $history | Sort-Object StartExecutionTime -Descending | Select-Object -First 1

        Write-Host "Total commands in history: $totalCommands"

        if ($oldestCommand -and $newestCommand) {
            $timeSpan = $newestCommand.StartExecutionTime - $oldestCommand.StartExecutionTime
            $daysStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $timeSpan.TotalDays -Format 'N1'
            }
            else {
                $timeSpan.TotalDays.ToString("N1")
            }
            $avgCommandsStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ($totalCommands / $timeSpan.TotalDays) -Format 'N1'
            }
            else {
                ($totalCommands / $timeSpan.TotalDays).ToString("N1")
            }
            Write-Host ("History spans: {0} days" -f $daysStr)
            Write-Host ("Average commands per day: {0}" -f $avgCommandsStr)
        }

        # Most frequent commands
        Write-Host "`n🔄 Most Frequent Commands:" -ForegroundColor Yellow
        $commandFrequency = $history | Group-Object {
            # Simplify command to base command (remove arguments)
            ($_.CommandLine -split '\s+')[0]
        } | Sort-Object Count -Descending | Select-Object -First 10

        $commandFrequency | Format-Table -Property @{
            Name       = "Command"
            Expression = { $_.Name }
            Width      = 20
        }, @{
            Name       = "Count"
            Expression = { $_.Count }
            Width      = 8
            Alignment  = "Right"
        }, @{
            Name       = "Percentage"
            Expression = { "{0:P1}" -f ($_.Count / $totalCommands) }
            Width      = 10
            Alignment  = "Right"
        } -AutoSize

        # Recent activity by hour
        Write-Host "`n🕐 Commands by Hour of Day:" -ForegroundColor Magenta
        $hourlyStats = $history | Group-Object {
            $_.StartExecutionTime.Hour
        } | Sort-Object Name

        $hourlyStats | ForEach-Object {
            $hour = $_.Name
            $count = $_.Count
            $hour12 = if ($hour -eq 0) { "12 AM" } elseif ($hour -lt 12) { "$hour AM" } elseif ($hour -eq 12) { "12 PM" } else { "$($hour - 12) PM" }
            Write-Host ("  {0,-6}: {1,3} commands" -f $hour12, $count)
        }

        # Longest commands
        Write-Host "`n📏 Longest Commands:" -ForegroundColor Red
        $longestCommands = $history | Sort-Object { $_.CommandLine.Length } -Descending | Select-Object -First 5
        $longestCommands | ForEach-Object -Begin { $i = 1 } -Process {
            $cmd = $_.CommandLine
            if ($cmd.Length -gt 60) {
                $cmd = $cmd.Substring(0, 57) + "..."
            }
            Write-Host ("  {0}. {1} ({2} chars)" -f $i, $cmd, $_.CommandLine.Length)
            $i++
        }
    }

    # History cleanup utilities
    <#
    .SYNOPSIS
        Removes duplicate commands from history.
    .DESCRIPTION
        Removes duplicate command entries from PowerShell history, keeping the most recent occurrence.
    #>
    function Remove-HistoryDuplicates {
        $history = Get-History
        if (-not $history) {
            Write-Host "No history to clean."
            return
        }

        $uniqueCommands = @{}
        $duplicatesRemoved = 0

        # Process history in reverse order (newest first)
        $history | Sort-Object Id -Descending | ForEach-Object {
            if (-not $uniqueCommands.ContainsKey($_.CommandLine)) {
                $uniqueCommands[$_.CommandLine] = $_.Id
            }
            else {
                Clear-History -Id $_.Id -ErrorAction SilentlyContinue
                $duplicatesRemoved++
            }
        }

        Write-Host "🧹 Removed $duplicatesRemoved duplicate commands from history."
    }

    <#
    .SYNOPSIS
        Removes old commands from history.
    .DESCRIPTION
        Removes commands older than the specified number of days from PowerShell history.
    .PARAMETER Days
        Number of days of history to keep (default: 30).
    #>
    function Remove-OldHistory {
        param([int]$Days = 30)

        $cutoffDate = (Get-Date).AddDays(-$Days)
        $history = Get-History | Where-Object { $_.StartExecutionTime -lt $cutoffDate }

        if ($history.Count -eq 0) {
            Write-Host "No commands older than $Days days found."
            return
        }

        $history | ForEach-Object {
            Clear-History -Id $_.Id -ErrorAction SilentlyContinue
        }

        Write-Host "🗑️ Removed $($history.Count) commands older than $Days days."
    }

    # Smart history recall
    <#
    .SYNOPSIS
        Shows the last command matching a pattern.
    .DESCRIPTION
        Finds the most recent command matching the pattern and displays it for manual execution.
    .PARAMETER Pattern
        Pattern to match against command history.
    #>
    function Invoke-LastCommand {
        param([string]$Pattern)

        if (-not $Pattern) {
            Write-Warning "Please provide a search pattern."
            return
        }

        $lastCommand = Get-History | Where-Object { $_.CommandLine -like "*$Pattern*" } | Sort-Object Id -Descending | Select-Object -First 1

        if (-not $lastCommand) {
            Write-Warning "No command found matching pattern: $Pattern"
            return
        }

        Write-Host "🔍 Found command: $($lastCommand.CommandLine)" -ForegroundColor Cyan
        Write-Host "💡 Copy and execute manually, or use 'r <pattern>' to search and execute." -ForegroundColor Yellow
    }

    # Quick access to recent commands
    <#
    .SYNOPSIS
        Shows recent commands with quick selection.
    .DESCRIPTION
        Displays recent commands with numbers for quick execution.
    .PARAMETER Count
        Number of recent commands to show (default: 10).
    #>
    function Show-RecentCommands {
        param([int]$Count = 10)

        $recent = Get-History | Sort-Object Id -Descending | Select-Object -First $Count

        if ($recent.Count -eq 0) {
            Write-Host "No command history available."
            return
        }

        Write-Host "📋 Recent Commands (use 'r <number>' to execute):" -ForegroundColor Blue
        Write-Host ""

        $recent | ForEach-Object -Begin { $i = 1 } -Process {
            $cmd = $_.CommandLine
            if ($cmd.Length -gt 80) {
                $cmd = $cmd.Substring(0, 77) + "..."
            }
            Write-Host ("  {0,2}. {1}" -f $i, $cmd)
            $i++
        }
        Write-Host ""
        Write-Host "💡 Use 'r <number>' to execute a command, or 'r <pattern>' to search and execute."
    }

    # Quick command recall by number
    <#
    .SYNOPSIS
        Executes a command from recent history by number or pattern.
    .DESCRIPTION
        Executes a command from the recent history list by its number,
        or finds and executes the most recent command matching a pattern.
    .PARAMETER CommandInput
        Either a number (for recent commands) or a pattern to search for.
    #>
    function r {
        param([string]$CommandInput)

        if (-not $CommandInput) {
            Show-RecentCommands
            return
        }

        # Try to parse as number
        if ($CommandInput -match '^\d+$') {
            $number = [int]$CommandInput
            $command = Get-History | Sort-Object Id -Descending | Select-Object -Skip ($number - 1) -First 1

            if (-not $command) {
                Write-Warning "Command number $number not found in recent history."
                return
            }

            Write-Host "🔄 Executing: $($command.CommandLine)" -ForegroundColor Cyan

            # Security: Ask for confirmation before executing command from history
            $confirmation = Read-Host "Execute this command? (y/N)"
            if ($confirmation -match '^y(es)?$') {
                try {
                    # Execute command safely using script block
                    $scriptBlock = [scriptblock]::Create($command.CommandLine)
                    & $scriptBlock
                }
                catch {
                    Write-Warning "Command execution failed: $($_.Exception.Message)"
                }
            }
            else {
                Write-Host "Command execution canceled." -ForegroundColor Yellow
            }
        }
        else {
            # Treat as pattern
            Invoke-LastCommand -Pattern $CommandInput
        }
    }

    # Override the built-in r alias (which points to Invoke-History) with our custom function
    Remove-Alias -Name r -ErrorAction SilentlyContinue
    Set-Alias -Name r -Value r -Option AllScope -Force

    # Enhanced history search with preview
    <#
    .SYNOPSIS
        Interactive history search with preview.
    .DESCRIPTION
        Provides an interactive way to search through command history
        with live preview of matching commands.
    #>
    function Search-HistoryInteractive {
        # In test mode, return early to avoid hanging on ReadKey
        if (Test-EnvBool $env:PS_PROFILE_TEST_MODE) {
            Write-Host "🔍 Interactive History Search (test mode - skipping interactive input)" -ForegroundColor Cyan
            return
        }

        Write-Host "🔍 Interactive History Search" -ForegroundColor Cyan
        Write-Host "===========================" -ForegroundColor Cyan
        Write-Host "Type to search (Ctrl+C to exit):"

        $searchTerm = ""
        while ($true) {
            try {
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                if ($key.ControlKeyState -band [System.ConsoleModifiers]::Control) {
                    if ($key.VirtualKeyCode -eq 67) {
                        # Ctrl+C
                        Write-Host ""
                        break
                    }
                }
                elseif ($key.VirtualKeyCode -eq 13) {
                    # Enter
                    Write-Host ""
                    if ($searchTerm) {
                        Find-HistoryFuzzy -Pattern $searchTerm -MaxResults 5
                    }
                    break
                }
                elseif ($key.VirtualKeyCode -eq 8) {
                    # Backspace
                    if ($searchTerm.Length -gt 0) {
                        $searchTerm = $searchTerm.Substring(0, $searchTerm.Length - 1)
                        Write-Host ("`rSearch: {0} " -f $searchTerm) -NoNewline
                    }
                }
                elseif ($key.Character) {
                    $searchTerm += $key.Character
                    Write-Host ("`rSearch: {0}" -f $searchTerm) -NoNewline
                }
            }
            catch {
                break
            }
        }
    }

    Set-Variable -Name 'EnhancedHistoryLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Enhanced history fragment failed: $($_.Exception.Message)" }
}

