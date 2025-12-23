# ===============================================
# lang-go-performance.tests.ps1
# Performance tests for lang-go.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPath = Join-Path $script:ProfileDir 'lang-go.ps1'

    # Ensure bootstrap is loaded first
    $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }
}

Describe 'lang-go.ps1 - Performance Tests' {
    Context 'Fragment loading performance' {
        It 'Loads fragment within acceptable time' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:FragmentPath -ErrorAction Stop
            $stopwatch.Stop()

            # Fragment should load in under 1 second
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000
        }

        It 'Multiple loads do not degrade performance' {
            # First load
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:FragmentPath -ErrorAction SilentlyContinue
            $stopwatch1.Stop()

            # Second load (should be fast due to idempotency)
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:FragmentPath -ErrorAction SilentlyContinue
            $stopwatch2.Stop()

            # Second load should be faster or similar to first
            # (idempotency checks should make it fast)
            $stopwatch2.ElapsedMilliseconds | Should -BeLessOrEqual ($stopwatch1.ElapsedMilliseconds * 1.5)
        }
    }

    Context 'Function execution performance' {
        It 'Release-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Release-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms (just checks and warnings)
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Invoke-Mage executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Invoke-Mage -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Lint-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Lint-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Build-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Test-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Test-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }

    Context 'Command detection performance' {
        It 'Test-CachedCommand is used for efficient command detection' {
            # Load fragment
            . $script:FragmentPath -ErrorAction SilentlyContinue

            # Verify Test-CachedCommand is being used
            # (This is an indirect test - if the fragment loads quickly,
            # it's likely using cached command detection)
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Release-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should be fast due to caching
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
}

