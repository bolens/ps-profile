# ===============================================
# game-emulators-performance.tests.ps1
# Performance tests for game-emulators.ps1 module
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    Initialize-FragmentPerformanceThresholds -Prefix 'GAME_EMULATORS' -FunctionMs 12000
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'game-emulators.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in less than 500ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()
            
            for ($i = 0; $i -lt 5; $i++) {
                # Clear fragment loaded state
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'game-emulators' -Loaded $false
                }
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'game-emulators.ps1')
                $stopwatch.Stop()
                
                $loadTimes += $stopwatch.ElapsedMilliseconds
            }
            
            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
        }
        
        It 'Get-EmulatorList executes quickly' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Get-EmulatorList
            $stopwatch.Stop()
            
            $executionTime = $stopwatch.ElapsedMilliseconds
            $executionTime | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Second load has minimal overhead' {
            # First load
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
            $stopwatch1.Stop()
            
            # Second load (should be idempotent)
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'game-emulators.ps1')
            $stopwatch2.Stop()
            
            $secondLoad = $stopwatch2.ElapsedMilliseconds
            $secondLoad | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}

