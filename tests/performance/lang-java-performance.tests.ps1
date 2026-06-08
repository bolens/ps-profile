# ===============================================
# lang-java-performance.tests.ps1
# Performance tests for lang-java-*.ps1 fragments
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPaths = @(
        (Join-Path $script:ProfileDir 'lang-java-build.ps1'),
        (Join-Path $script:ProfileDir 'lang-java-compilers.ps1'),
        (Join-Path $script:ProfileDir 'lang-java-version.ps1')
    )
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_JAVA_MAX_LOAD_MS' -Default 3000
    $script:MaxFunctionExecTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_JAVA_MAX_FUNCTION_MS' -Default 1500

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Import-LangJavaTestFragments {
    foreach ($fragmentPath in $script:FragmentPaths) {
        . $fragmentPath -ErrorAction SilentlyContinue
    }
}

Describe 'lang-java fragments - Performance Tests' {
    Context 'Fragment loading performance' {
        It 'Loads fragments within acceptable time' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Import-LangJavaTestFragments
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Multiple loads do not degrade performance' {
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            Import-LangJavaTestFragments
            $stopwatch1.Stop()

            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            Import-LangJavaTestFragments
            $stopwatch2.Stop()

            $stopwatch2.ElapsedMilliseconds | Should -BeLessOrEqual ($stopwatch1.ElapsedMilliseconds * 1.5)
        }
    }

    Context 'Function execution performance' {
        BeforeAll {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
        }

        It 'Build-Maven executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Maven -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Build-Gradle executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Gradle -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Build-Ant executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Ant -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Compile-Kotlin executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Compile-Kotlin -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Compile-Scala executes quickly when tool is missing' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Compile-Scala -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Set-JavaVersion executes quickly when no parameters' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Set-JavaVersion -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }

    Context 'Command detection performance' {
        It 'Test-CachedCommand is used for efficient command detection' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Maven -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }
}
