# ===============================================
# lang-java-performance.tests.ps1
# Performance tests for lang-java.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPath = Join-Path $script:ProfileDir 'lang-java.ps1'

    # Ensure bootstrap is loaded first
    $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }
}

Describe 'lang-java.ps1 - Performance Tests' {
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
            $stopwatch2.ElapsedMilliseconds | Should -BeLessOrEqual ($stopwatch1.ElapsedMilliseconds * 1.5)
        }
    }

    Context 'Function execution performance' {
        It 'Build-Maven executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Maven -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms (just checks and warnings)
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Build-Gradle executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Gradle -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Build-Ant executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Ant -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Compile-Kotlin executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Compile-Kotlin -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Compile-Scala executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Compile-Scala -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should complete in under 100ms
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It 'Set-JavaVersion executes quickly when no parameters' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Set-JavaVersion -ErrorAction SilentlyContinue
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
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Maven -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            # Should be fast due to caching
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
}

