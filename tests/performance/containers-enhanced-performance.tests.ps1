# ===============================================
# containers-enhanced-performance.tests.ps1
# Performance tests for containers-enhanced.ps1
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_CONTAINERS_ENHANCED_MAX_LOAD_MS' -Default 2000
    $script:MaxFunctionExecTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_CONTAINERS_ENHANCED_MAX_FUNCTION_MS' -Default 2000
    $script:MaxEngineLookupTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_CONTAINERS_ENHANCED_MAX_ENGINE_LOOKUP_MS' -Default 100
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'containers-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in less than 1000ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()
            
            for ($i = 0; $i -lt 5; $i++) {
                # Clear fragment loaded state
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'containers-enhanced' -Loaded $false
                }
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
                $stopwatch.Stop()
                
                $loadTimes += $stopwatch.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
        }

        BeforeEach {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Mark-TestCommandsUnavailable -CommandNames @('docker', 'podman')
        }
        
        It 'Clean-Containers executes quickly when tools not available' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Clean-Containers -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
        
        It 'Export-ContainerLogs executes quickly when tools not available' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Export-ContainerLogs -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
        
        It 'Get-ContainerStats executes quickly when tools not available' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Get-ContainerStats -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
        
        It 'Health-CheckContainers executes quickly when tools not available' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Health-CheckContainers -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }
    
    Context 'Command Cache Performance' {
        It 'Test-CachedCommand is fast on repeated calls' {
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'podman' -Available $false

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt 100; $i++) {
                $null = Test-CachedCommand 'docker'
            }
            $stopwatch.Stop()

            $avgTime = $stopwatch.ElapsedMilliseconds / 100
            $avgTime | Should -BeLessThan $script:MaxEngineLookupTimeMs
        }
    }
}
