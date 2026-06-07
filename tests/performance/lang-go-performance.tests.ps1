# ===============================================
# lang-go-performance.tests.ps1
# Performance tests for lang-go.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPath = Join-Path $script:ProfileDir 'lang-go.ps1'
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_GO_MAX_LOAD_MS' -Default 2000
    $script:MaxFunctionExecTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_GO_MAX_FUNCTION_MS' -Default 500

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

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
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
        BeforeAll {
            . $script:FragmentPath -ErrorAction SilentlyContinue
        }

        It 'Release-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Release-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Invoke-Mage executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Invoke-Mage -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Lint-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Lint-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Build-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Test-GoProject executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Test-GoProject -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
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

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }
}

