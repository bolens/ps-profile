# ===============================================
# mobile-dev-performance.tests.ps1
# Performance tests for mobile-dev.ps1 module
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
    Initialize-FragmentPerformanceThresholds -Prefix 'MOBILE_DEV'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'mobile-dev.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under threshold' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Loads fragment consistently across multiple loads' {
            $loadTimes = @()

            for ($i = 0; $i -lt 5; $i++) {
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $null = Set-FragmentLoaded -FragmentName 'mobile-dev' -Loaded $false
                }

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
                $stopwatch.Stop()

                $loadTimes += $stopwatch.ElapsedMilliseconds
            }

            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Second load has minimal overhead' {
            . (Join-Path $script:ProfileDir 'mobile-dev.ps1')

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
