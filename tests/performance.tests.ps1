Describe 'Profile Performance Regression Tests' {
    BeforeAll {
        $script:ProfilePath = Join-Path $PSScriptRoot '..\Microsoft.PowerShell_profile.ps1'
        $script:ProfileDir = Join-Path $PSScriptRoot '..\profile.d'
        
        # Baseline performance metrics (in milliseconds)
        # These are approximate targets - actual values depend on system
        $script:MaxLoadTimeMs = 5000  # 5 seconds max load time
        $script:MaxFragmentTimeMs = 500  # 500ms max per fragment
    }
    
    Context 'Profile Load Performance' {
        It 'profile loads within acceptable time limit' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                . $script:ProfilePath
            }
            finally {
                $sw.Stop()
            }
            
            $loadTimeMs = $sw.ElapsedMilliseconds
            
            # Profile should load within reasonable time
            $loadTimeMs | Should -BeLessThan $script:MaxLoadTimeMs
            
            Write-Verbose "Profile loaded in $loadTimeMs ms" -Verbose
        }
        
        It 'profile load time is consistent across multiple loads' {
            $loadTimes = @()
            
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    . $script:ProfilePath
                }
                finally {
                    $sw.Stop()
                    $loadTimes += $sw.ElapsedMilliseconds
                }
            }
            
            # Calculate variance
            $avgTime = ($loadTimes | Measure-Object -Average).Average
            $maxDeviation = ($loadTimes | ForEach-Object { [Math]::Abs($_ - $avgTime) } | Measure-Object -Maximum).Maximum
            $deviationPercent = ($maxDeviation / $avgTime) * 100
            
            # Load times should be relatively consistent (within 50% variance)
            $deviationPercent | Should -BeLessThan 50
            
            Write-Verbose "Average load time: $avgTime ms, Max deviation: $maxDeviation ms ($([Math]::Round($deviationPercent, 2))%)" -Verbose
        }
        
        It 'fragments load within acceptable time per fragment' {
            if (-not $env:PS_PROFILE_DEBUG) {
                $env:PS_PROFILE_DEBUG = '3'  # Enable performance profiling
            }
            
            # Load profile with performance tracking
            . $script:ProfilePath
            
            # Check if performance data was collected
            if ($global:PSProfileFragmentTimes) {
                $slowFragments = $global:PSProfileFragmentTimes | Where-Object { $_.Duration -gt $script:MaxFragmentTimeMs }
                
                if ($slowFragments) {
                    Write-Warning "Slow fragments detected:"
                    $slowFragments | ForEach-Object {
                        Write-Warning "  $($_.Fragment): $([Math]::Round($_.Duration, 2)) ms"
                    }
                }
                
                # Most fragments should load quickly
                $slowCount = ($slowFragments | Measure-Object).Count
                $totalCount = ($global:PSProfileFragmentTimes | Measure-Object).Count
                $slowPercent = if ($totalCount -gt 0) { ($slowCount / $totalCount) * 100 } else { 0 }
                
                # Less than 20% of fragments should be slow
                $slowPercent | Should -BeLessThan 20
            }
            
            # Cleanup
            $env:PS_PROFILE_DEBUG = $null
            $global:PSProfileFragmentTimes = $null
        }
    }
    
    Context 'Fragment Count Impact' {
        It 'load time scales reasonably with fragment count' {
            $fragments = Get-ChildItem -Path $script:ProfileDir -Filter '*.ps1' -File
            $fragmentCount = ($fragments | Measure-Object).Count
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                . $script:ProfilePath
            }
            finally {
                $sw.Stop()
            }
            
            $loadTimeMs = $sw.ElapsedMilliseconds
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
            # Test sequential loading
            $env:PS_PROFILE_BATCH_LOAD = $null
            $sw1 = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                . $script:ProfilePath
            }
            finally {
                $sw1.Stop()
            }
            
            # Test batch loading
            $env:PS_PROFILE_BATCH_LOAD = '1'
            $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                . $script:ProfilePath
            }
            finally {
                $sw2.Stop()
            }
            
            $sequentialTime = $sw1.ElapsedMilliseconds
            $batchTime = $sw2.ElapsedMilliseconds
            
            # Batch loading should not be significantly slower (within 20%)
            $timeDifference = [Math]::Abs($batchTime - $sequentialTime)
            $timeDifferencePercent = ($timeDifference / $sequentialTime) * 100
            
            $timeDifferencePercent | Should -BeLessThan 20
            
            Write-Verbose "Sequential: $sequentialTime ms, Batch: $batchTime ms" -Verbose
            
            # Cleanup
            $env:PS_PROFILE_BATCH_LOAD = $null
        }
    }
}

