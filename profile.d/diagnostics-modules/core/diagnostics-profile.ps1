# ===============================================
# Profile diagnostic functions
# Profile health checks, startup time, and command usage statistics
# ===============================================

<#
Small diagnostics helpers that are only verbose when `PS_PROFILE_DEBUG` is
set. Useful to surface environment and tool status without polluting normal
interactive startup.
#>

# Register diagnostics helpers
try {
    $diagnosticsLoaded = Get-Variable -Name 'PSProfileDiagnosticsLoaded' -Scope Global -ErrorAction SilentlyContinue

    if ($diagnosticsLoaded) {
        $missingCommands = @(
            'Show-ProfileDiagnostic'
            'Show-ProfileStartupTime'
            'Test-ProfileHealth'
            'Show-CommandUsageStats'
        ) | Where-Object {
            -not (Get-Command $_ -CommandType Function -ErrorAction SilentlyContinue)
        }

        if (-not $missingCommands) { return }
    }

    if ($env:PS_PROFILE_DEBUG) {
        $requiredNetworkFunctions = @('Test-NetworkConnectivity', 'Invoke-HttpRequestWithRetry')
        $missingNetworkFunctions = $requiredNetworkFunctions | Where-Object {
            -not (Get-Command $_ -CommandType Function -ErrorAction SilentlyContinue)
        }

        if ($missingNetworkFunctions) {
            $profileRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            $networkUtilsPath = Join-Path $profileRoot 'network-utils.ps1'
            if ($networkUtilsPath -and -not [string]::IsNullOrWhiteSpace($networkUtilsPath) -and (Test-Path -LiteralPath $networkUtilsPath)) {
                . $networkUtilsPath
            }
        }

        # Track profile startup time
        $global:PSProfileStartTime = [DateTime]::Now

        # Show profile diagnostics - PowerShell version, PATH, Podman status
        <#
        .SYNOPSIS
            Shows profile diagnostic information.
        .DESCRIPTION
            Displays diagnostic information including PowerShell version, PATH entries,
            Podman machine status, and configured Podman connections. Only available
            when PS_PROFILE_DEBUG environment variable is set.
        #>
        function Show-ProfileDiagnostic {
            Write-Host "-- Profile diagnostic --"
            Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
            Write-Host "PATH entries:"
            $env:Path -split ';' | ForEach-Object { Write-Host " - $_" }
            Write-Host "Podman machine(s):"; podman machine list | Out-Host
            Write-Host "Configured podman connections:"; podman system connection list | Out-Host
        }

        # Show profile startup time
        <#
        .SYNOPSIS
            Shows profile startup time information.
        .DESCRIPTION
            Displays how long the profile took to load and which fragments were slowest.
            Only available when PS_PROFILE_DEBUG environment variable is set.
        #>
        function Show-ProfileStartupTime {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.profile.startup] Calculating profile startup time"
                }
                if ($debugLevel -ge 3) {
                    Write-Host "  [diagnostics.profile.startup] Profile start time: $($global:PSProfileStartTime.ToString('o'))" -ForegroundColor DarkGray
                }
            }

            try {
                if (-not $global:PSProfileStartTime) {
                    Write-Warning "Profile start time not available. Startup time cannot be calculated."
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Profile start time not available" -OperationName 'diagnostics.profile.startup' -Code 'START_TIME_MISSING'
                        }
                    }
                    return
                }

                $startupTime = [DateTime]::Now - $global:PSProfileStartTime
                
                # Use locale-aware number formatting if available
                $startupTimeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $startupTime.TotalSeconds -Format 'N2'
                }
                else {
                    $startupTime.TotalSeconds.ToString("N2")
                }
                
                Write-Host "-- Profile startup time --"
                Write-Host ("Total startup time: {0} seconds" -f $startupTimeStr)

                # Level 2: Log timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.profile.startup] Total startup time: $($startupTime.TotalSeconds) seconds"
                }
                
                # Level 3: Detailed timing breakdown
                if ($debugLevel -ge 3) {
                    Write-Host "  [diagnostics.profile.startup] Startup time breakdown - Total: $($startupTime.TotalSeconds)s, Start: $($global:PSProfileStartTime.ToString('HH:mm:ss.fff')), End: $([DateTime]::Now.ToString('HH:mm:ss.fff'))" -ForegroundColor DarkGray
                }
            }
            catch {
                # Level 1: Log error
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.profile.startup' -Context @{
                            operation = 'calculate_startup_time'
                        }
                    }
                    else {
                        Write-Error "Failed to calculate profile startup time: $($_.Exception.Message)"
                    }
                }
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.profile.startup] Error calculating startup time: $($_.Exception.Message)"
                }
                if ($debugLevel -ge 3) {
                    Write-Host "  [diagnostics.profile.startup] Error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }

            # Show fragment load times if available
            try {
                if ($global:PSProfileFragmentTimes -and $global:PSProfileFragmentTimes.Count -gt 0) {
                    Write-Host "Fragment load times (slowest first):"
                    $global:PSProfileFragmentTimes | Sort-Object -Property Duration -Descending | Select-Object -First 10 | ForEach-Object {
                        $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                            Format-LocaleNumber $_.Duration -Format 'N2'
                        }
                        else {
                            $_.Duration.ToString("N2")
                        }
                        Write-Host ("  {0}: {1}ms" -f $_.Fragment, $durationStr)
                            
                        # Level 3: Log slow fragment details
                        if ($debugLevel -ge 3) {
                            Write-Host "    [diagnostics.profile.startup] Fragment: $($_.Fragment), Duration: $($_.Duration)ms" -ForegroundColor DarkGray
                        }
                    }
                }
                elseif ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.profile.startup] No fragment timing data available"
                }
            }
            catch {
                # Level 2: Log error in fragment timing display
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.profile.startup] Error displaying fragment times: $($_.Exception.Message)"
                }
            }
        }

        # Health check for critical dependencies
        <#
        .SYNOPSIS
            Performs basic health checks for critical dependencies.
        .DESCRIPTION
            Checks the availability and basic functionality of critical tools and services.
            Only available when PS_PROFILE_DEBUG environment variable is set.
        #>
        function Test-ProfileHealth {
            Write-Host "-- Profile Health Check --"

            $healthChecks = @(
                @{
                    Name    = "PowerShell Version"
                    Test    = { $PSVersionTable.PSVersion -ge [version]"7.0" }
                    Message = "PowerShell 7.0+ recommended for best experience"
                },
                @{
                    Name    = "Scoop"
                    Test    = { Test-CachedCommand scoop }
                    Message = "Scoop package manager not found"
                },
                @{
                    Name    = "Git"
                    Test    = { Test-CachedCommand git }
                    Message = "Git not found - version control features will be limited"
                },
                @{
                    Name    = "PSReadLine"
                    Test    = {
                        if (Get-Module PSReadLine -ErrorAction SilentlyContinue) { return $true }

                        $available = Get-Module -ListAvailable -Name PSReadLine -ErrorAction SilentlyContinue | Select-Object -First 1
                        if (-not $available) { return $false }

                        try {
                            Import-Module $available -ErrorAction Stop | Out-Null
                            return $true
                        }
                        catch {
                            return $false
                        }
                    }
                    Message = "PSReadLine module not available - enhanced command line experience disabled"
                },
                @{
                    Name    = "Profile Directory"
                    Test    = { Test-Path (Join-Path (Split-Path $PROFILE) 'profile.d') }
                    Message = "Profile.d directory not found"
                },
                @{
                    Name    = "Network Connectivity"
                    Test    = { Test-NetworkConnectivity -Target "8.8.8.8" -Port 53 -TimeoutSeconds 3 }
                    Message = "DNS connectivity issues detected - network-dependent features may fail"
                },
                @{
                    Name    = "Internet Access"
                    Test    = { Invoke-HttpRequestWithRetry -Uri "https://www.google.com" -TimeoutSeconds 5 -MaxRetries 1 }
                    Message = "Internet connectivity issues - update checks and web features may fail"
                }
            )

            $allHealthy = $true
            foreach ($check in $healthChecks) {
                try {
                    $result = & $check.Test
                    if ($result) {
                        Write-Host ("✓ {0}" -f $check.Name)
                    }
                    else {
                        Write-Host ("⚠ {0}: {1}" -f $check.Name, $check.Message)
                        $allHealthy = $false
                    }
                }
                catch {
                    Write-Host ("✗ {0}: Error during check - {1}" -f $check.Name, $_.Exception.Message)
                    $allHealthy = $false
                    
                    # Level 1: Log error
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.profile.health' -Context @{
                                    check_name = $check.Name
                                }
                            }
                        }
                        if ($debugLevel -ge 2) {
                            Write-Verbose "[diagnostics.profile.health] Check error: $($check.Name) - $($_.Exception.Message)"
                        }
                        if ($debugLevel -ge 3) {
                            Write-Host "  [diagnostics.profile.health] Check error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                        }
                    }
                }
            }

            if ($allHealthy) {
                Write-Host "`n🎉 All critical dependencies are healthy!"
            }
            else {
                Write-Host "`n⚠️  Some dependencies have issues. Check warnings above."
            }
        }

        # Command usage statistics
        <#
        .SYNOPSIS
            Shows command usage statistics for optimization insights.
        .DESCRIPTION
            Displays which profile functions are used most frequently to help
            identify optimization opportunities. Only available when PS_PROFILE_DEBUG
            environment variable is set.
        #>
        function Show-CommandUsageStats {
            Write-Host "-- Command Usage Statistics --"

            if (-not $global:PSProfileCommandUsage) {
                Write-Host "No usage statistics collected yet. Usage tracking starts after profile load."
                Write-Host "Run commands and check back later, or set PS_PROFILE_DEBUG=1 to enable tracking."
                return
            }

            $stats = $global:PSProfileCommandUsage.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 20

            if ($stats.Count -eq 0) {
                Write-Host "No command usage data available."
                return
            }

            Write-Host "Top 20 most used profile functions:"
            $stats | ForEach-Object -Begin { $i = 1 } -Process {
                Write-Host ("{0,2}. {1,-25} {2,6} calls" -f $i, $_.Key, $_.Value)
                $i++
            }

            # Show optimization suggestions
            $totalCalls = ($global:PSProfileCommandUsage.Values | Measure-Object -Sum).Sum
            Write-Host "`nOptimization Insights:"
            Write-Host ("Total tracked calls: {0}" -f $totalCalls)

            # Find functions that might benefit from eager loading
            $frequentlyUsed = $stats | Where-Object { $_.Value -gt 10 } | Select-Object -First 5
            if ($frequentlyUsed) {
                Write-Host "`nFrequently used functions (consider eager loading):"
                $frequentlyUsed | ForEach-Object {
                    Write-Host ("  - {0} ({1} calls)" -f $_.Key, $_.Value)
                }
            }

            # Show memory usage estimate
            $estimatedMemory = $global:PSProfileCommandUsage.Count * 100  # Rough estimate
            Write-Host ("`nEstimated tracking overhead: ~{0} bytes" -f $estimatedMemory)
        }

        Set-Variable -Name 'PSProfileDiagnosticsLoaded' -Value $true -Scope Global -Force
    }
}
catch {
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        if ($debugLevel -ge 1) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.profile' -Context @{
                    fragment = 'diagnostics-profile'
                }
            }
            else {
                Write-Error "Diagnostics fragment failed: $($_.Exception.Message)"
            }
        }
        if ($debugLevel -ge 2) {
            Write-Verbose "[diagnostics.profile] Fragment load error: $($_.Exception.Message)"
        }
        if ($debugLevel -ge 3) {
            Write-Host "  [diagnostics.profile] Fragment error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
    else {
        # Always log errors even if debug is off
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.profile' -Context @{
                fragment = 'diagnostics-profile'
            }
        }
        else {
            Write-Error "Diagnostics fragment failed: $($_.Exception.Message)"
        }
    }
}


