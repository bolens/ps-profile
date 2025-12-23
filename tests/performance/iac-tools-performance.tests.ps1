# ===============================================
# iac-tools-performance.tests.ps1
# Performance tests for iac-tools.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'iac-tools.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under 500ms' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'iac-tools.ps1')
            $sw.Stop()
            
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'iac-tools.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }
            
            # All loads should be fast (idempotency check) - allow up to 600ms for module loading overhead
            $times | ForEach-Object { $_ | Should -BeLessThan 600 }
        }
    }
    
    Context 'Function Registration Performance' {
        It 'Registers all functions quickly' {
            # Ensure fragment is loaded first
            . (Join-Path $script:ProfileDir 'iac-tools.ps1')
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Functions should already be registered, but we can verify they exist
            $functions = @(
                'Invoke-Terragrunt',
                'Invoke-OpenTofu',
                'Plan-Infrastructure',
                'Apply-Infrastructure',
                'Get-TerraformState',
                'Invoke-Pulumi'
            )
            
            foreach ($func in $functions) {
                Get-Command -Name $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            # Load fragment first time
            . (Join-Path $script:ProfileDir 'iac-tools.ps1')
            
            # Measure second load (should be fast due to idempotency)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'iac-tools.ps1')
            $sw.Stop()
            
            # Idempotency check should be fast (< 600ms) - allow for module loading overhead
            $sw.ElapsedMilliseconds | Should -BeLessThan 600
        }
    }
}

