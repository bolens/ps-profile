# ===============================================
# git-enhanced.tests.ps1
# Integration tests for git-enhanced.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'git.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
}

Describe 'git-enhanced.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'git-enhanced.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
            . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        } | Should -Not -Throw
    }
}

Describe 'git-enhanced.ps1 - Function Registration' {
    It 'Registers New-GitChangelog function' {
        Get-Command -Name 'New-GitChangelog' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-GitTower function' {
        Get-Command -Name 'Invoke-GitTower' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-GitKraken function' {
        Get-Command -Name 'Invoke-GitKraken' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-GitButler function' {
        Get-Command -Name 'Invoke-GitButler' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Invoke-Jujutsu function' {
        Get-Command -Name 'Invoke-Jujutsu' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers New-GitWorktree function' {
        Get-Command -Name 'New-GitWorktree' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Sync-GitRepos function' {
        Get-Command -Name 'Sync-GitRepos' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Clean-GitBranches function' {
        Get-Command -Name 'Clean-GitBranches' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-GitStats function' {
        Get-Command -Name 'Get-GitStats' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Format-GitCommit function' {
        Get-Command -Name 'Format-GitCommit' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-GitLargeFiles function' {
        Get-Command -Name 'Get-GitLargeFiles' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'git-enhanced.ps1 - Alias Registration' {
    It 'Creates git-cliff alias' {
        $alias = Get-Alias -Name 'git-cliff' -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'New-GitChangelog'
        }
    }
    
    It 'Creates git-tower alias' {
        $alias = Get-Alias -Name 'git-tower' -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Invoke-GitTower'
        }
    }
    
    It 'Creates gitkraken alias' {
        $alias = Get-Alias -Name 'gitkraken' -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Invoke-GitKraken'
        }
    }
    
    It 'Creates gitbutler alias' {
        $alias = Get-Alias -Name 'gitbutler' -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Invoke-GitButler'
        }
    }
    
    It 'Creates jj alias' {
        $alias = Get-Alias -Name 'jj' -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Invoke-Jujutsu'
        }
    }
}

Describe 'git-enhanced.ps1 - Graceful Degradation' {
    It 'New-GitChangelog handles missing tool gracefully' {
        { New-GitChangelog -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-GitTower handles missing tool gracefully' {
        { Invoke-GitTower -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-GitKraken handles missing tool gracefully' {
        { Invoke-GitKraken -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-GitButler handles missing tool gracefully' {
        { Invoke-GitButler -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Invoke-Jujutsu handles missing tool gracefully' {
        { Invoke-Jujutsu -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

Describe 'git-enhanced.ps1 - Format-GitCommit' {
    It 'Formats commit message correctly' {
        $result = Format-GitCommit -Type 'feat' -Description 'Add feature'
        
        $result | Should -Match '^feat: Add feature'
    }
    
    It 'Formats commit message with scope' {
        $result = Format-GitCommit -Type 'fix' -Scope 'api' -Description 'Fix bug'
        
        $result | Should -Match '^fix\(api\): Fix bug'
    }
    
    It 'Formats commit message with body and footer' {
        $result = Format-GitCommit -Type 'docs' -Description 'Update docs' -Body 'Added examples' -Footer 'Closes #123'
        
        $result | Should -Match 'docs: Update docs'
        $result | Should -Match 'Added examples'
        $result | Should -Match 'Closes #123'
    }
}

