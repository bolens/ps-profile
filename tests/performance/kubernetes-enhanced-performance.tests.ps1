# ===============================================
# kubernetes-enhanced-performance.tests.ps1
# Performance tests for kubernetes-enhanced.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'kubernetes-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under 500ms' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            $sw.Stop()
            
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }
            
            # All loads should be fast (idempotency check) - allow up to 500ms for module loading overhead
            $times | ForEach-Object { $_ | Should -BeLessThan 500 }
        }
    }
    
    Context 'Function Registration Performance' {
        It 'Registers all functions quickly' {
            # Ensure fragment is loaded first
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Functions should already be registered, but we can verify they exist
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
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
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
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Describe-KubeResource executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Describe-KubeResource -ResourceType 'pods' -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It 'Apply-KubeManifests executes quickly when tools not available' {
            Mock-CommandAvailabilityPester -CommandName 'kubectl' -Available $false
            Mock Test-Path -MockWith { return $true }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Apply-KubeManifests -Path 'manifests/' -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            # Load fragment first time
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            
            # Measure second load (should be fast due to idempotency)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'kubernetes-enhanced.ps1')
            $sw.Stop()
            
            # Idempotency check should be fast (< 500ms) - allow for module loading overhead
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
    }
}

