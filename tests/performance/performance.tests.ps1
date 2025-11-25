
. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

$script:ProfilePath = $null
$script:ProfileDir = $null

Describe 'Profile Performance Regression Tests' {
    BeforeAll {
        $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists

        # Baseline performance metrics (in milliseconds)
        # These are approximate targets - actual values depend on system
        # Use a more lenient default for CI/test environments (20 seconds)
        $script:MaxLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_LOAD_MS' -Default 20000
        $script:MaxFragmentTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_FRAGMENT_MS' -Default 500

        function script:Invoke-ProfileLoad {
            [CmdletBinding()]
            param(
                [ValidateSet('Inherit', 'Sequential', 'Batch')]
                [string]$BatchMode = 'Inherit',

                [switch]$CollectFragmentTimes
            )

            if (-not (Test-Path -LiteralPath $script:ProfilePath)) {
                throw "Profile path not initialized."
            }

            $originalBatch = $env:PS_PROFILE_BATCH_LOAD
            $originalDebug = $env:PS_PROFILE_DEBUG

            try {
                switch ($BatchMode) {
                    'Sequential' { Remove-Item -Path Env:PS_PROFILE_BATCH_LOAD -ErrorAction SilentlyContinue }
                    'Batch' { $env:PS_PROFILE_BATCH_LOAD = '1' }
                }

                if ($CollectFragmentTimes) {
                    $env:PS_PROFILE_DEBUG = '3'
                }

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    . $script:ProfilePath
                }
                finally {
                    $stopwatch.Stop()
                }

                $fragmentTimes = $null
                if ($CollectFragmentTimes -and $global:PSProfileFragmentTimes) {
                    $fragmentTimes = @($global:PSProfileFragmentTimes | ForEach-Object { $_ })
                }

                return [pscustomobject]@{
                    DurationMs    = $stopwatch.Elapsed.TotalMilliseconds
                    FragmentTimes = $fragmentTimes
                }
            }
            finally {
                if ($CollectFragmentTimes) {
                    $global:PSProfileFragmentTimes = $null
                    if ($null -eq $originalDebug) {
                        Remove-Item -Path Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                    }
                    else {
                        $env:PS_PROFILE_DEBUG = $originalDebug
                    }
                }

                switch ($BatchMode) {
                    'Sequential' {
                        if ($null -ne $originalBatch) {
                            $env:PS_PROFILE_BATCH_LOAD = $originalBatch
                        }
                        else {
                            Remove-Item -Path Env:PS_PROFILE_BATCH_LOAD -ErrorAction SilentlyContinue
                        }
                    }
                    'Batch' {
                        if ($null -eq $originalBatch) {
                            Remove-Item -Path Env:PS_PROFILE_BATCH_LOAD -ErrorAction SilentlyContinue
                        }
                        else {
                            $env:PS_PROFILE_BATCH_LOAD = $originalBatch
                        }
                    }
                }
            }
        }

        function script:Measure-ProfileLoads {
            [CmdletBinding()]
            param(
                [ValidateRange(1, 20)]
                [int]$Count = 1,

                [ValidateSet('Inherit', 'Sequential', 'Batch')]
                [string]$BatchMode = 'Inherit',

                [switch]$CollectFragmentTimes,

                [switch]$WarmUp
            )

            if ($WarmUp) {
                Invoke-ProfileLoad -BatchMode $BatchMode | Out-Null
            }

            $results = @()
            for ($i = 0; $i -lt $Count; $i++) {
                $results += Invoke-ProfileLoad -BatchMode $BatchMode -CollectFragmentTimes:$CollectFragmentTimes
            }

            return $results
        }
    }

    Context 'Profile Load Performance' {
        It 'profile loads within acceptable time limit' {
            $result = Measure-ProfileLoads -Count 1 -BatchMode Sequential -WarmUp
            $loadTimeMs = [Math]::Round($result[0].DurationMs, 0)

            # Profile should load within reasonable time
            $loadTimeMs | Should -BeLessThan $script:MaxLoadTimeMs

            Write-Verbose "Profile loaded in $loadTimeMs ms" -Verbose
        }

        It 'profile load time is consistent across multiple loads' {
            $results = Measure-ProfileLoads -Count 3 -BatchMode Sequential -WarmUp
            $loadTimes = $results | ForEach-Object { $_.DurationMs }

            # Calculate variance
            $avgTime = ($loadTimes | Measure-Object -Average).Average
            $maxDeviation = ($loadTimes | ForEach-Object { [Math]::Abs($_ - $avgTime) } | Measure-Object -Maximum).Maximum
            $deviationPercent = ($maxDeviation / $avgTime) * 100

            # Load times should be relatively consistent (within 75% variance to account for system load variations)
            $deviationPercent | Should -BeLessThan 75

            Write-Verbose "Average load time: $avgTime ms, Max deviation: $maxDeviation ms ($([Math]::Round($deviationPercent, 2))%)" -Verbose
        }

        It 'fragments load within acceptable time per fragment' {
            $result = Measure-ProfileLoads -Count 1 -BatchMode Sequential -CollectFragmentTimes -WarmUp
            $fragmentData = $result[0].FragmentTimes

            if ($fragmentData) {
                $slowFragments = $fragmentData | Where-Object { $_.Duration -gt $script:MaxFragmentTimeMs }

                if ($slowFragments) {
                    Write-Warning "Slow fragments detected:"
                    $slowFragments | ForEach-Object {
                        Write-Warning "  $($_.Fragment): $([Math]::Round($_.Duration, 2)) ms"
                    }
                }

                # Most fragments should load quickly
                $slowCount = ($slowFragments | Measure-Object).Count
                $totalCount = ($fragmentData | Measure-Object).Count
                $slowPercent = if ($totalCount -gt 0) { ($slowCount / $totalCount) * 100 } else { 0 }

                # Less than 20% of fragments should be slow
                $slowPercent | Should -BeLessThan 20
            }
        }
    }

    Context 'Fragment Count Impact' {
        It 'load time scales reasonably with fragment count' {
            $fragments = Get-ChildItem -Path $script:ProfileDir -Filter '*.ps1' -File
            $fragmentCount = ($fragments | Measure-Object).Count

            $result = Measure-ProfileLoads -Count 1 -BatchMode Sequential -WarmUp
            $loadTimeMs = $result[0].DurationMs
            $timePerFragment = if ($fragmentCount -gt 0) { $loadTimeMs / $fragmentCount } else { 0 }

            # Should average less than 200ms per fragment
            $timePerFragment | Should -BeLessThan 200

            Write-Verbose "Loaded $fragmentCount fragments in $loadTimeMs ms ($([Math]::Round($timePerFragment, 2)) ms per fragment)" -Verbose
        }
    }

    Context 'Memory Usage' {
        It 'profile does not cause excessive memory growth' {
            $before = [System.GC]::GetTotalMemory($false)

            . $script:ProfilePath

            $after = [System.GC]::GetTotalMemory($false)
            $memoryIncrease = $after - $before
            $memoryIncreaseMB = $memoryIncrease / 1MB

            # Profile should not use more than 50MB
            $memoryIncreaseMB | Should -BeLessThan 50

            Write-Verbose "Memory increase: $([Math]::Round($memoryIncreaseMB, 2)) MB" -Verbose
        }
    }

    Context 'Batch Loading Performance' {
        It 'batch loading mode performs similarly to sequential' {
            $sequentialResult = Measure-ProfileLoads -Count 1 -BatchMode Sequential -WarmUp
            $batchResult = Measure-ProfileLoads -Count 1 -BatchMode Batch -WarmUp

            $sequentialTime = $sequentialResult[0].DurationMs
            $batchTime = $batchResult[0].DurationMs

            # Batch loading should not be significantly slower (within 30% to account for system variance)
            # Use the larger time as denominator to avoid division by small numbers
            $maxTime = [Math]::Max($sequentialTime, $batchTime)
            $timeDifference = [Math]::Abs($batchTime - $sequentialTime)
            $timeDifferencePercent = if ($maxTime -gt 0) { ($timeDifference / $maxTime) * 100 } else { 0 }

            $timeDifferencePercent | Should -BeLessThan 30

            Write-Verbose "Sequential: $sequentialTime ms, Batch: $batchTime ms, Difference: $([Math]::Round($timeDifferencePercent, 2))%" -Verbose
        }
    }
}

