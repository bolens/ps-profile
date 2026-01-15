# ===============================================
# terminal-enhanced-performance.tests.ps1
# Performance tests for terminal-enhanced.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'terminal-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in less than 500ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan 500
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()
            
            for ($i = 0; $i -lt 5; $i++) {
                # Clear fragment loaded state
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'terminal-enhanced' -Loaded $false
                }
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
                $stopwatch.Stop()
                
                $loadTimes += $stopwatch.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan 500
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        }
        
        It 'Get-TerminalInfo executes quickly' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Get-TerminalInfo
            $stopwatch.Stop()
            
            $executionTime = $stopwatch.ElapsedMilliseconds
            $executionTime | Should -BeLessThan 100
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Second load has minimal overhead' {
            # First load
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
            $stopwatch1.Stop()
            
            # Second load (should be idempotent)
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
            $stopwatch2.Stop()
            
            $firstLoad = $stopwatch1.ElapsedMilliseconds
            $secondLoad = $stopwatch2.ElapsedMilliseconds
            
            # Second load should be faster (idempotent check)
            $secondLoad | Should -BeLessThan $firstLoad
        }
    }
}

