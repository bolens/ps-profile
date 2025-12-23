# ===============================================
# git-enhanced-performance.tests.ps1
# Performance tests for git-enhanced.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'git.ps1')
}

Describe 'git-enhanced.ps1 - Performance Tests' {
    Context 'Fragment Load Time' {
        It 'Loads fragment in under 500ms' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
            $sw.Stop()
            
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
        
        It 'Loads fragment consistently across multiple loads' {
            $times = @()
            for ($i = 0; $i -lt 3; $i++) {
                # Clear fragment loaded state
                if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
                    # Fragment loading is idempotent, so we test the idempotency check
                }
                
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
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
                'New-GitChangelog',
                'Invoke-GitTower',
                'Invoke-GitKraken',
                'Invoke-GitButler',
                'Invoke-Jujutsu',
                'New-GitWorktree',
                'Sync-GitRepos',
                'Clean-GitBranches',
                'Get-GitStats',
                'Format-GitCommit',
                'Get-GitLargeFiles'
            )
            
            foreach ($func in $functions) {
                Get-Command -Name $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Format-GitCommit Performance' {
        It 'Formats commit messages quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt 100; $i++) {
                $null = Format-GitCommit -Type 'feat' -Description "Test commit $i"
            }
            
            $sw.Stop()
            # 100 commits should format in under 100ms
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }
    }
    
    Context 'Idempotency Check Overhead' {
        It 'Idempotency check has minimal overhead' {
            # Load fragment first time
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
            
            # Measure second load (should be fast due to idempotency)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
            $sw.Stop()
            
            # Idempotency check should be very fast (< 50ms)
            $sw.ElapsedMilliseconds | Should -BeLessThan 50
        }
    }
}

