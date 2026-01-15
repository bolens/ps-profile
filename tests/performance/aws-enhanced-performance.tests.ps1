# ===============================================
# aws-enhanced-performance.tests.ps1
# Performance tests for aws.ps1 enhanced functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'aws.ps1 - Enhanced Functions Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in less than 1000ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'aws.ps1')
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan 1000
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()
            
            for ($i = 0; $i -lt 5; $i++) {
                # Clear fragment loaded state
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'aws' -Loaded $false
                }
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'aws.ps1')
                $stopwatch.Stop()
                
                $loadTimes += $stopwatch.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan 1000
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'aws.ps1')
        }
        
        It 'Get-AwsCredentials executes quickly when aws not available' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'aws' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Get-AwsCredentials -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $executionTime = $stopwatch.ElapsedMilliseconds
            # Allow up to 1000ms for file I/O operations in test environment
            $executionTime | Should -BeLessThan 1000
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Second load has minimal overhead' {
            # First load
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'aws.ps1')
            $stopwatch1.Stop()
            
            # Second load (should be idempotent)
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'aws.ps1')
            $stopwatch2.Stop()
            
            $firstLoad = $stopwatch1.ElapsedMilliseconds
            $secondLoad = $stopwatch2.ElapsedMilliseconds
            
            # Second load should be faster (idempotent check)
            $secondLoad | Should -BeLessThan $firstLoad
        }
    }
}

