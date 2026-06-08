# ===============================================
# lang-rust-performance.tests.ps1
# Performance tests for lang-rust-*.ps1 fragments
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPaths = @(
        (Join-Path $script:ProfileDir 'lang-rust-tools.ps1'),
        (Join-Path $script:ProfileDir 'lang-rust-build.ps1'),
        (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')
    )
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_RUST_MAX_LOAD_MS' -Default 3000
    $script:MaxLookupTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_RUST_MAX_LOOKUP_MS' -Default 800
    $script:MaxIdempotencyTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_RUST_MAX_IDEMPOTENCY_MS' -Default 4000
    $script:MaxVarianceMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_LANG_RUST_MAX_VARIANCE_MS' -Default 800

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Import-LangRustTestFragments {
    foreach ($fragmentPath in $script:FragmentPaths) {
        . $fragmentPath -ErrorAction SilentlyContinue
    }
}

Describe 'lang-rust fragments - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Fragments load in less than threshold' {
            $loadTimes = @()
            for ($i = 0; $i -lt 5; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                Import-LangRustTestFragments
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
                Import-LangRustTestFragments
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
            Get-Command Install-RustBinary -ErrorAction SilentlyContinue | Out-Null
            Get-Command Watch-RustProject -ErrorAction SilentlyContinue | Out-Null
            Get-Command Audit-RustProject -ErrorAction SilentlyContinue | Out-Null
            Get-Command Test-RustOutdated -ErrorAction SilentlyContinue | Out-Null
            Get-Command Build-RustRelease -ErrorAction SilentlyContinue | Out-Null
            Get-Command Update-RustDependencies -ErrorAction SilentlyContinue | Out-Null
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
            Get-Alias cargo-binstall -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-watch -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-audit -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-outdated -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-build-release -ErrorAction SilentlyContinue | Out-Null
            Get-Alias cargo-update-deps -ErrorAction SilentlyContinue | Out-Null
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxLookupTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Idempotency checks add minimal overhead' {
            Import-LangRustTestFragments

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            Import-LangRustTestFragments
            Import-LangRustTestFragments
            Import-LangRustTestFragments
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
