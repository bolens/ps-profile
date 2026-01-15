# ===============================================
# modern-cli-enhanced-performance.tests.ps1
# Performance tests for modern-cli.ps1 enhanced functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'modern-cli.ps1 - Enhanced Functions Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in less than 1000ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'modern-cli.ps1')
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan 1000
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()
            
            for ($i = 0; $i -lt 5; $i++) {
                # Clear fragment loaded state
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'modern-cli' -Loaded $false
                }
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'modern-cli.ps1')
                $stopwatch.Stop()
                
                $loadTimes += $stopwatch.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan 1000
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'modern-cli.ps1')
        }
        
        It 'Find-WithFd executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'fd' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Find-WithFd -Pattern "test" -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Grep-WithRipgrep executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'rg' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Grep-WithRipgrep -Pattern "test" -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Navigate-WithZoxide executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'zoxide' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Navigate-WithZoxide -Query "test" -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'View-WithBat executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'bat' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            View-WithBat -Path "test.txt" -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Command Cache Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'modern-cli.ps1')
        }
        
        It 'Test-CachedCommand is fast on repeated calls' {
            Mock-CommandAvailabilityPester -CommandName 'fd' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt 100; $i++) {
                $null = Test-CachedCommand 'fd' -ErrorAction SilentlyContinue
            }
            $stopwatch.Stop()
            
            $avgTime = $stopwatch.ElapsedMilliseconds / 100
            $avgTime | Should -BeLessThan 10
        }
    }
}
