# ===============================================
# re-tools-performance.tests.ps1
# Performance tests for re-tools.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 're-tools.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 're-tools.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }
            
            # All loads should be fast (idempotency check) - allow up to 500ms for module loading overhead
            $times | ForEach-Object { $_ | Should -BeLessThan 500 }
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            # Load once
            . (Join-Path $script:ProfileDir 're-tools.ps1')
            
            # Measure second load (should be fast due to idempotency)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 're-tools.ps1')
            $sw.Stop()
            
            # Idempotency check should be fast (< 500ms) - allow for module loading overhead
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 're-tools.ps1')
        }
        
        It 'Functions are registered quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $functions = @('Decompile-Java', 'Decompile-DotNet', 'Analyze-PE', 'Extract-AndroidApk', 'Dump-IL2CPP')
            foreach ($func in $functions) {
                Get-Command -Name $func -ErrorAction SilentlyContinue | Out-Null
            }
            $sw.Stop()
            
            # Function lookup should be very fast (< 100ms)
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
}

