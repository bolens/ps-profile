# ===============================================
# lang-python-performance.tests.ps1
# Performance tests for lang-python-*.ps1 fragments
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPaths = @(
        (Join-Path $script:ProfileDir 'lang-python-pipx.ps1'),
        (Join-Path $script:ProfileDir 'lang-python-env.ps1'),
        (Join-Path $script:ProfileDir 'lang-python-packages.ps1')
    )
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_PYTHON_MAX_LOAD_MS' -Default 3000
    $script:MaxLookupTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_PYTHON_MAX_LOOKUP_MS' -Default 800
    $script:MaxIdempotencyTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_PYTHON_MAX_IDEMPOTENCY_MS' -Default 4000
    $script:MaxVarianceMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_PYTHON_MAX_VARIANCE_MS' -Default 800

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Import-LangPythonTestFragments {
    foreach ($fragmentPath in $script:FragmentPaths) {
        . $fragmentPath -ErrorAction SilentlyContinue
    }
}

Describe 'lang-python fragments - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Fragments load in less than threshold' {
            $loadTimes = @()
            for ($i = 0; $i -lt 5; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                Import-LangPythonTestFragments
                $sw.Stop()
                $loadTimes += $sw.ElapsedMilliseconds
            }

            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $avgLoadTime | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }
    }

    Context 'Load Time Consistency' {
        It 'Fragment load time is consistent across multiple loads' {
            $loadTimes = @()
            for ($i = 0; $i -lt 10; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                Import-LangPythonTestFragments
                $sw.Stop()
                $loadTimes += $sw.ElapsedMilliseconds
            }

            $maxLoadTime = ($loadTimes | Measure-Object -Maximum).Maximum
            $minLoadTime = ($loadTimes | Measure-Object -Minimum).Minimum
            $variance = $maxLoadTime - $minLoadTime

            $variance | Should -BeLessThan $script:MaxVarianceMs
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
        }

        It 'Function registration is fast' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-Command Install-PythonApp -ErrorAction SilentlyContinue | Out-Null
            Get-Command Invoke-Pipx -ErrorAction SilentlyContinue | Out-Null
            Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue | Out-Null
            Get-Command New-PythonVirtualEnv -ErrorAction SilentlyContinue | Out-Null
            Get-Command New-PythonProject -ErrorAction SilentlyContinue | Out-Null
            Get-Command Install-PythonPackage -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxLookupTimeMs
        }
    }

    Context 'Alias Resolution Performance' {
        BeforeAll {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
        }

        It 'Alias resolution is fast' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Get-Alias pipx-install -ErrorAction SilentlyContinue | Out-Null
            Get-Alias pipx -ErrorAction SilentlyContinue | Out-Null
            Get-Alias pyvenv -ErrorAction SilentlyContinue | Out-Null
            Get-Alias pyinstall -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxLookupTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Idempotency checks add minimal overhead' {
            Import-LangPythonTestFragments

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Import-LangPythonTestFragments
            Import-LangPythonTestFragments
            Import-LangPythonTestFragments
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
