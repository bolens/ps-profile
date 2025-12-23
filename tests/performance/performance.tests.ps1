
. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

$script:ProfilePath = $null
$script:ProfileDir = $null

Describe 'Profile Performance Regression Tests' {
    BeforeAll {
        try {
            $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1' -StartPath $PSScriptRoot -EnsureExists
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            
            if (-not (Test-Path $script:ProfilePath)) {
                throw "Profile file not found at: $script:ProfilePath"
            }
            if (-not (Test-Path $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }

            # Baseline performance metrics (in milliseconds)
            # These are based on the current baseline with a 3x safety margin for CI/test environments
            # Baseline: FullStartupMean ~2437ms, slowest fragment ~353ms (env.ps1)
            # Use 3x multiplier to account for system variance and CI environments
            $baselineFile = Join-Path $PSScriptRoot '..\scripts\data\performance-baseline.json'
            $defaultLoadTime = 7500  # ~3x baseline (2437ms * 3 = 7311ms, rounded to 7500ms)
            $defaultFragmentTime = 1200  # ~3x slowest fragment (353ms * 3 = 1059ms, rounded to 1200ms)
            
            # Allow override via environment variables, but use baseline-based defaults
            if (Test-Path -LiteralPath $baselineFile) {
                try {
                    $baseline = Get-Content -LiteralPath $baselineFile -Raw | ConvertFrom-Json
                    if ($baseline.FullStartupMean -gt 0) {
                        $defaultLoadTime = [Math]::Round($baseline.FullStartupMean * 3)
                    }
                    if ($baseline.Fragments -and $baseline.Fragments.Count -gt 0) {
                        $maxFragment = ($baseline.Fragments | Measure-Object -Property MeanMs -Maximum).Maximum
                        if ($maxFragment -gt 0) {
                            $defaultFragmentTime = [Math]::Round($maxFragment * 3)
                        }
                    }
                }
                catch {
                    # If baseline parsing fails, use hardcoded defaults
                    Write-Verbose "Failed to parse baseline file, using hardcoded defaults: $_" -Verbose
                }
            }
            
            $script:MaxLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_LOAD_MS' -Default $defaultLoadTime
            $script:MaxFragmentTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_FRAGMENT_MS' -Default $defaultFragmentTime
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize performance tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }

        function script:Invoke-ProfileLoad {
            [CmdletBinding()]
            param(
                [ValidateSet('Inherit', 'Sequential', 'Batch')]
                [string]$BatchMode = 'Inherit',

                [switch]$CollectFragmentTimes,

                [int]$TimeoutSeconds = 60
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

                # Set environment to minimal to speed up loading for tests
                $originalEnv = $env:PS_PROFILE_ENVIRONMENT
                if (-not $CollectFragmentTimes) {
                    # Use minimal environment for faster test execution
                    $env:PS_PROFILE_ENVIRONMENT = 'minimal'
                }
                
                # Use runspace for profile load with timeout (similar to fragment loading approach)
                $runspacePool = $null
                $powershell = $null
                $handle = $null
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                try {
                    # Create runspace pool (single runspace for profile load)
                    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
                    $runspacePool.Open()
                    
                    # Scriptblock to load profile in isolated runspace
                    $scriptBlock = {
                        param(
                            [string]$ProfilePath,
                            [string]$BatchModeValue,
                            [string]$EnvironmentValue,
                            [bool]$CollectFragmentTimesValue
                        )
                        
                        try {
                            # Set environment variables in runspace
                            if ($BatchModeValue -eq 'Sequential') {
                                Remove-Item -Path Env:PS_PROFILE_BATCH_LOAD -ErrorAction SilentlyContinue
                            }
                            elseif ($BatchModeValue -eq 'Batch') {
                                $env:PS_PROFILE_BATCH_LOAD = '1'
                            }
                            
                            if ($CollectFragmentTimesValue) {
                                $env:PS_PROFILE_DEBUG = '3'
                            }
                            
                            if ($EnvironmentValue) {
                                $env:PS_PROFILE_ENVIRONMENT = $EnvironmentValue
                            }
                            
                            # Load profile
                            $null = . $ProfilePath
                            
                            # Collect fragment times if requested
                            $fragmentTimes = $null
                            if ($CollectFragmentTimesValue -and $global:PSProfileFragmentTimes) {
                                $fragmentTimes = @($global:PSProfileFragmentTimes | ForEach-Object { $_ })
                            }
                            
                            return @{
                                Success       = $true
                                FragmentTimes = $fragmentTimes
                            }
                        }
                        catch {
                            return @{
                                Success = $false
                                Error   = $_.Exception.Message
                            }
                        }
                    }
                    
                    # Start profile load in runspace
                    $powershell = [PowerShell]::Create()
                    $powershell.RunspacePool = $runspacePool
                    $null = $powershell.AddScript($scriptBlock)
                    $null = $powershell.AddArgument($script:ProfilePath)
                    $null = $powershell.AddArgument($BatchMode)
                    $null = $powershell.AddArgument($env:PS_PROFILE_ENVIRONMENT)
                    $null = $powershell.AddArgument($CollectFragmentTimes)
                    $handle = $powershell.BeginInvoke()
                    
                    # Wait for completion with timeout (polling approach, STA-compatible)
                    $pollIntervalMs = 100
                    $timeoutMs = $TimeoutSeconds * 1000
                    $startTime = Get-Date
                    $completed = $false
                    
                    while (-not $completed) {
                        if ($handle.IsCompleted) {
                            $completed = $true
                            break
                        }
                        
                        $elapsed = ((Get-Date) - $startTime).TotalMilliseconds
                        if ($elapsed -ge $timeoutMs) {
                            # Timeout - stop the runspace
                            if ($powershell) {
                                $powershell.Stop()
                            }
                            throw "Profile load timed out after $TimeoutSeconds seconds"
                        }
                        
                        Start-Sleep -Milliseconds $pollIntervalMs
                    }
                    
                    # Get result
                    $result = $powershell.EndInvoke($handle)
                    $stopwatch.Stop()
                    
                    if (-not $result.Success) {
                        throw "Profile load failed: $($result.Error)"
                    }
                    
                    $fragmentTimes = $result.FragmentTimes
                }
                finally {
                    $stopwatch.Stop()
                    
                    # Cleanup runspace
                    if ($handle) {
                        try {
                            $null = $powershell.EndInvoke($handle)
                        }
                        catch {
                            # Ignore errors during cleanup
                        }
                    }
                    if ($powershell) {
                        $powershell.Dispose()
                    }
                    if ($runspacePool) {
                        $runspacePool.Close()
                        $runspacePool.Dispose()
                    }
                    
                    # Restore original environment
                    if ($null -eq $originalEnv) {
                        Remove-Item -Path Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                    }
                    else {
                        $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                    }
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
            try {
                # Use minimal environment for faster test execution
                $originalEnv = $env:PS_PROFILE_ENVIRONMENT
                $env:PS_PROFILE_ENVIRONMENT = 'minimal'
                
                try {
                    $result = Measure-ProfileLoads -Count 1 -BatchMode Sequential -WarmUp
                }
                finally {
                    if ($null -eq $originalEnv) {
                        Remove-Item -Path Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                    }
                    else {
                        $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                    }
                }
                $loadTimeMs = [Math]::Round($result[0].DurationMs, 0)

                # Profile should load within reasonable time
                $loadTimeMs | Should -BeLessThan $script:MaxLoadTimeMs -Because "Profile should load within $script:MaxLoadTimeMs ms"

                Write-Verbose "Profile loaded in $loadTimeMs ms" -Verbose
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Test     = 'profile loads within acceptable time limit'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Profile load performance test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'profile load time is consistent across multiple loads' {
            try {
                $results = Measure-ProfileLoads -Count 3 -BatchMode Sequential -WarmUp
                $loadTimes = $results | ForEach-Object { $_.DurationMs }

                # Calculate variance
                $avgTime = ($loadTimes | Measure-Object -Average).Average
                $maxDeviation = ($loadTimes | ForEach-Object { [Math]::Abs($_ - $avgTime) } | Measure-Object -Maximum).Maximum
                $deviationPercent = ($maxDeviation / $avgTime) * 100

                # Load times should be relatively consistent (within 75% variance to account for system load variations)
                $deviationPercent | Should -BeLessThan 75 -Because "Load times should be consistent (within 75% variance)"

                Write-Verbose "Average load time: $avgTime ms, Max deviation: $maxDeviation ms ($([Math]::Round($deviationPercent, 2))%)" -Verbose
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Test     = 'profile load time is consistent across multiple loads'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Profile load consistency test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'fragments load within acceptable time per fragment' {
            # Note: This test loads full profile to collect fragment times
            # It may be slow, so we don't use minimal environment here
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
            # Use minimal environment for faster test execution
            $originalEnv = $env:PS_PROFILE_ENVIRONMENT
            $env:PS_PROFILE_ENVIRONMENT = 'minimal'
            
            try {
                $fragments = Get-ChildItem -Path $script:ProfileDir -Filter '*.ps1' -File
                $fragmentCount = ($fragments | Measure-Object).Count

                $result = Measure-ProfileLoads -Count 1 -BatchMode Sequential -WarmUp
            }
            finally {
                if ($null -eq $originalEnv) {
                    Remove-Item -Path Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                }
            }
            $loadTimeMs = $result[0].DurationMs
            $timePerFragment = if ($fragmentCount -gt 0) { $loadTimeMs / $fragmentCount } else { 0 }

            # Should average less than 200ms per fragment
            $timePerFragment | Should -BeLessThan 200

            Write-Verbose "Loaded $fragmentCount fragments in $loadTimeMs ms ($([Math]::Round($timePerFragment, 2)) ms per fragment)" -Verbose
        }
    }

    Context 'Memory Usage' {
        It 'profile does not cause excessive memory growth' {
            try {
                $before = [System.GC]::GetTotalMemory($false)

                # Use minimal environment for faster test execution
                $originalEnv = $env:PS_PROFILE_ENVIRONMENT
                $env:PS_PROFILE_ENVIRONMENT = 'minimal'
                
                try {
                    . $script:ProfilePath
                }
                finally {
                    if ($null -eq $originalEnv) {
                        Remove-Item -Path Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                    }
                    else {
                        $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                    }
                }

                $after = [System.GC]::GetTotalMemory($false)
                $memoryIncrease = $after - $before
                $memoryIncreaseMB = $memoryIncrease / 1MB

                # Profile should not use more than 50MB
                $memoryIncreaseMB | Should -BeLessThan 50 -Because "Profile should not use more than 50MB of memory"

                Write-Verbose "Memory increase: $([Math]::Round($memoryIncreaseMB, 2)) MB" -Verbose
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Test     = 'profile does not cause excessive memory growth'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Memory usage test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }

    Context 'Batch Loading Performance' {
        It 'batch loading mode performs similarly to sequential' {
            # Use minimal environment for faster test execution
            $originalEnv = $env:PS_PROFILE_ENVIRONMENT
            $env:PS_PROFILE_ENVIRONMENT = 'minimal'
            
            try {
                $sequentialResult = Measure-ProfileLoads -Count 1 -BatchMode Sequential -WarmUp
                $batchResult = Measure-ProfileLoads -Count 1 -BatchMode Batch -WarmUp
            }
            finally {
                if ($null -eq $originalEnv) {
                    Remove-Item -Path Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                }
            }

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

