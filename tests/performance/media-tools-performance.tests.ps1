# ===============================================
# media-tools-performance.tests.ps1
# Performance tests for media-tools.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
}

Describe 'media-tools.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under 500ms' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            $sw.Stop()
            
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'media-tools.ps1')
                $sw.Stop()
                $times += $sw.ElapsedMilliseconds
            }
            
            # All loads should be fast (idempotency check)
            $times | ForEach-Object { $_ | Should -BeLessThan 100 }
        }
    }
    
    Context 'Function Registration Performance' {
        It 'Registers all functions quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Functions should already be registered, but we can verify they exist
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
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            # Load fragment first time
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            
            # Measure second load (should be fast due to idempotency)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            $sw.Stop()
            
            # Idempotency check should be very fast (< 50ms)
            $sw.ElapsedMilliseconds | Should -BeLessThan 50
        }
    }
}

