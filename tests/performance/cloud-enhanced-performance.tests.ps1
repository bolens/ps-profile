# ===============================================
# cloud-enhanced-performance.tests.ps1
# Performance tests for cloud-enhanced.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    Initialize-FragmentPerformanceThresholds -Prefix 'CLOUD_ENHANCED'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'cloud-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under threshold' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }

            $times | ForEach-Object { $_ | Should -BeLessThan $script:MaxRepeatLoadTimeMs }
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
        }

        It 'Registers all functions quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            $functions = @(
                'Set-AzureSubscription',
                'Set-GcpProject',
                'Get-DopplerSecrets',
                'Deploy-Heroku',
                'Deploy-Vercel',
                'Deploy-Netlify'
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
            . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
