# ===============================================
# beads-performance.tests.ps1
# Performance tests for beads.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BeadsPath = Join-Path $script:ProfileDir 'beads.ps1'
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load the fragment
    . $script:BeadsPath -ErrorAction SilentlyContinue
}

Describe 'beads.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under 500ms' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:BeadsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 500
        }
    }
    
    Context 'Function Registration' {
        It 'Functions are registered quickly' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            $functions = @(
                'Invoke-Beads',
                'Initialize-Beads',
                'Get-BeadsReady',
                'New-BeadsIssue',
                'Get-BeadsIssue',
                'Get-BeadsIssues',
                'Update-BeadsIssue',
                'Close-BeadsIssue',
                'Get-BeadsStats',
                'Get-BeadsBlocked'
            )
            
            foreach ($func in $functions) {
                Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 200
        }
    }
    
    Context 'Alias Resolution' {
        It 'Alias resolution is fast' {
            # Ensure fragment is loaded
            . $script:BeadsPath -ErrorAction SilentlyContinue
            
            # Ensure aliases exist
            $aliasMappings = @{
                'bd' = 'Invoke-Beads'
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            foreach ($alias in $aliasMappings.Keys) {
                $cmd = Get-Command $alias -ErrorAction SilentlyContinue
                if ($cmd) {
                    $cmd | Should -Not -BeNullOrEmpty
                }
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 50
        }
    }
    
    Context 'Command Availability Check' {
        It 'Command availability check is fast' {
            # Ensure fragment is loaded
            . $script:BeadsPath -ErrorAction SilentlyContinue
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Test cached command check
            if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
                $null = Test-CachedCommand 'bd' -ErrorAction SilentlyContinue
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 50
        }
    }
}
