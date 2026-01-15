# ===============================================
# containers-enhanced-performance.tests.ps1
# Performance tests for containers-enhanced.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'containers-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in less than 1000ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan 1000
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
            $avgLoadTime | Should -BeLessThan 1000
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
        }
        
        It 'Clean-Containers executes quickly when tools not available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Clean-Containers -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Export-ContainerLogs executes quickly when tools not available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Export-ContainerLogs -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Get-ContainerStats executes quickly when tools not available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Get-ContainerStats -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Health-CheckContainers executes quickly when tools not available' {
            Mock Get-ContainerEnginePreference -MockWith {
                return @{
                    Engine          = $null
                    Available       = $false
                    DockerAvailable = $false
                    PodmanAvailable = $false
                }
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Health-CheckContainers -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Command Cache Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
        }
        
        It 'Get-ContainerEnginePreference is fast on repeated calls' {
            Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt 100; $i++) {
                $null = Get-ContainerEnginePreference -ErrorAction SilentlyContinue
            }
            $stopwatch.Stop()
            
            $avgTime = $stopwatch.ElapsedMilliseconds / 100
            $avgTime | Should -BeLessThan 10
        }
    }
}
