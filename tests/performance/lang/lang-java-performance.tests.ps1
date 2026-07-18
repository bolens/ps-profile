# ===============================================
# lang-java-performance.tests.ps1
# Performance tests for lang-java-*.ps1 fragments
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
    $script:FragmentPaths = @(
        (Join-Path $script:ProfileDir 'lang-java-build.ps1'),
        (Join-Path $script:ProfileDir 'lang-java-compilers.ps1'),
        (Join-Path $script:ProfileDir 'lang-java-version.ps1')
    )
    Initialize-FragmentPerformanceThresholds -Prefix 'LANG_JAVA' -LoadMs 8000 -FunctionMs 5000

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

        BeforeEach {
            # Tests assert the missing-tool fast path; keep real installs from being invoked.
            Mark-TestCommandsUnavailable -CommandNames @(
                'mvn', 'gradle', 'ant', 'kotlinc', 'scalac', 'java',
                'scoop', 'choco', 'brew', 'apt', 'apt-get', 'dnf', 'yum', 'pacman', 'zypper', 'winget'
            )
            Set-Item -Path 'Function:\global:Invoke-MissingToolWarning' -Value {
                param(
                    [string]$ToolName,
                    [string]$ToolType = 'generic',
                    [string]$DefaultInstallCommand,
                    [string]$Tool,
                    [string]$InstallPackageName,
                    [string]$AdditionalHint
                )
            } -Force -ErrorAction SilentlyContinue
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

            Mark-TestCommandsUnavailable -CommandNames @(
                'mvn', 'gradle', 'ant', 'kotlinc', 'scalac', 'java',
                'scoop', 'choco', 'brew', 'apt', 'apt-get', 'dnf', 'yum', 'pacman', 'zypper', 'winget'
            )
            Set-Item -Path 'Function:\global:Invoke-MissingToolWarning' -Value {
                param(
                    [string]$ToolName,
                    [string]$ToolType = 'generic',
                    [string]$DefaultInstallCommand,
                    [string]$Tool,
                    [string]$InstallPackageName,
                    [string]$AdditionalHint
                )
            } -Force -ErrorAction SilentlyContinue

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $null = Build-Maven -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }
}
