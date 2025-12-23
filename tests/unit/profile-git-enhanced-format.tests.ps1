# ===============================================
# profile-git-enhanced-format.tests.ps1
# Unit tests for Format-GitCommit function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
}

Describe 'git-enhanced.ps1 - Format-GitCommit' {
    Context 'Basic formatting' {
        It 'Formats commit message with type and description' {
            $result = Format-GitCommit -Type 'feat' -Description 'Add new feature'
            
            $result | Should -Match '^feat: Add new feature'
        }
        
        It 'Formats commit message with scope' {
            $result = Format-GitCommit -Type 'fix' -Scope 'api' -Description 'Fix bug'
            
            $result | Should -Match '^fix\(api\): Fix bug'
        }
        
        It 'Formats commit message with body' {
            $result = Format-GitCommit -Type 'docs' -Description 'Update README' -Body 'Added installation instructions'
            
            $result | Should -Match '^docs: Update README'
            $result | Should -Match 'Added installation instructions'
        }
        
        It 'Formats commit message with footer' {
            $result = Format-GitCommit -Type 'fix' -Description 'Fix issue' -Footer 'Closes #123'
            
            $result | Should -Match '^fix: Fix issue'
            $result | Should -Match 'Closes #123'
        }
        
        It 'Formats commit message with all components' {
            $result = Format-GitCommit -Type 'feat' -Scope 'auth' -Description 'Add login' -Body 'Implemented OAuth2' -Footer 'Closes #456'
            
            $result | Should -Match '^feat\(auth\): Add login'
            $result | Should -Match 'Implemented OAuth2'
            $result | Should -Match 'Closes #456'
        }
    }
    
    Context 'Type validation' {
        It 'Accepts valid commit types' {
            $validTypes = @('feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore', 'ci', 'build', 'revert')
            
            foreach ($type in $validTypes) {
                { Format-GitCommit -Type $type -Description 'Test' } | Should -Not -Throw
            }
        }
        
        It 'Rejects invalid commit types' {
            { Format-GitCommit -Type 'invalid' -Description 'Test' } | Should -Throw
        }
    }
    
    Context 'Output format' {
        It 'Returns string output' {
            $result = Format-GitCommit -Type 'feat' -Description 'Test'
            
            $result | Should -BeOfType [string]
        }
        
        It 'Uses newlines for body and footer separation' {
            $result = Format-GitCommit -Type 'feat' -Description 'Test' -Body 'Body text' -Footer 'Footer text'
            
            $lines = $result -split "`n"
            $lines.Count | Should -BeGreaterThan 1
        }
    }
}

