# ===============================================
# kubernetes-enhanced-performance.tests.ps1
# Performance tests for kubernetes-enhanced.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    Initialize-FragmentPerformanceThresholds -Prefix 'KUBERNETES_ENHANCED'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under threshold' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }

            $times | ForEach-Object { $_ | Should -BeLessThan $script:MaxRepeatLoadTimeMs }
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
        }

        It 'Registers all functions quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            $functions = @(
                'Set-KubeContext',
                'Set-KubeNamespace',
                'Tail-KubeLogs',
                'Get-KubeResources',
                'Start-Minikube',
                'Start-K9s',
                'Exec-KubePod',
                'PortForward-KubeService',
                'Describe-KubeResource',
                'Apply-KubeManifests'
            )

            foreach ($func in $functions) {
                Get-Command -Name $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }

    Context 'Function Execution Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
        }

        It 'Exec-KubePod executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Exec-KubePod -Pod 'test-pod' -Command 'ls' -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Describe-KubeResource executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Describe-KubeResource -ResourceType 'pods' -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }

        It 'Apply-KubeManifests executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            Mock Test-Path -MockWith { return $true }

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Apply-KubeManifests -Path 'manifests/' -ErrorAction SilentlyContinue
            $stopwatch.Stop()

            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionExecTimeMs
        }
    }

    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            $sw.Stop()

            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}
