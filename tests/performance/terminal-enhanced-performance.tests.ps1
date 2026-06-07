# ===============================================
# terminal-enhanced-performance.tests.ps1
# Performance tests for terminal-enhanced.ps1 module
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    Initialize-FragmentPerformanceThresholds -Prefix 'TERMINAL_ENHANCED'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'terminal-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under threshold' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()

            for ($i = 0; $i -lt 5; $i++) {
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'terminal-enhanced' -Loaded $false
                }

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
                $stopwatch.Stop()

                $loadTimes += $stopwatch.ElapsedMilliseconds
            }

            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        }

        It 'Get-TerminalInfo executes quickly' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Get-TerminalInfo
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Second load has minimal overhead' {
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
