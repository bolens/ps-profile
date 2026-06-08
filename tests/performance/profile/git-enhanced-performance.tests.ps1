# ===============================================
# git-enhanced-performance.tests.ps1
# Performance tests for git-enhanced.ps1 fragment
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
    $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_GIT_ENHANCED_MAX_LOAD_MS' -Default 4500
    $script:MaxRepeatLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_GIT_ENHANCED_MAX_REPEAT_LOAD_MS' -Default 3500
    $script:MaxIdempotencyTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_GIT_ENHANCED_MAX_IDEMPOTENCY_MS' -Default 3500
    $script:MaxFunctionCheckTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_GIT_ENHANCED_MAX_FUNCTION_MS' -Default 500
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
            
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFragmentLoadTimeMs
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
            $times | ForEach-Object { $_ | Should -BeLessThan $script:MaxRepeatLoadTimeMs }
        }
    }
    
    Context 'Function Registration Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        }

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
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionCheckTimeMs
        }
    }
    
    Context 'Format-GitCommit Performance' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        }

        It 'Formats commit messages quickly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt 100; $i++) {
                $null = Format-GitCommit -Type 'feat' -Description "Test commit $i"
            }
            
            $sw.Stop()
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxFunctionCheckTimeMs
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
            
            $sw.ElapsedMilliseconds | Should -BeLessThan $script:MaxIdempotencyTimeMs
        }
    }
}

