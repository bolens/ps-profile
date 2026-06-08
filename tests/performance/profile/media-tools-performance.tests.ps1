# ===============================================
# media-tools-performance.tests.ps1
# Performance tests for media-tools.ps1 fragment
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
    Initialize-FragmentPerformanceThresholds -Prefix 'MEDIA_TOOLS'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'media-tools.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under threshold' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'media-tools.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }

            $times | ForEach-Object { $_ | Should -BeLessThan $script:MaxRepeatLoadTimeMs }
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
        }

        It 'Registers all functions quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            $functions = @(
                'Convert-Video',
                'Extract-Audio',
                'Tag-Audio',
                'Rip-CD',
                'Get-MediaInfo',
                'Merge-MKV'
            )

            foreach ($func in $functions) {
                Get-Command -Name $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            . (Join-Path $script:ProfileDir 'media-tools.ps1')

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
