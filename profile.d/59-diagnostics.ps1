<#
# 59-diagnostics.ps1

Small diagnostics helpers that are only verbose when `PS_PROFILE_DEBUG` is
set. Useful to surface environment and tool status without polluting normal
interactive startup.
#>

# Register diagnostics helpers
try {
    if ($null -ne (Get-Variable -Name 'DiagnosticsLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    if ($env:PS_PROFILE_DEBUG) {
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
            $startupTime = [DateTime]::Now - $global:PSProfileStartTime
            Write-Host "-- Profile startup time --"
            Write-Host ("Total startup time: {0:N2} seconds" -f $startupTime.TotalSeconds)

            # Show fragment load times if available
            if ($global:PSProfileFragmentTimes -and $global:PSProfileFragmentTimes.Count -gt 0) {
                Write-Host "Fragment load times (slowest first):"
                $global:PSProfileFragmentTimes | Sort-Object -Property Duration -Descending | Select-Object -First 10 | ForEach-Object {
                    Write-Host ("  {0}: {1:N2}ms" -f $_.Fragment, $_.Duration)
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
                    Test    = { Get-Module PSReadLine -ErrorAction SilentlyContinue }
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

        Set-Variable -Name 'DiagnosticsLoaded' -Value $true -Scope Global -Force
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Diagnostics fragment failed: $($_.Exception.Message)" }
}
