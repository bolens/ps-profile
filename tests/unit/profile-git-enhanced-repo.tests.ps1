# ===============================================
# profile-git-enhanced-repo.tests.ps1
# Unit tests for Git repository management functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
    
    # Create temporary test directory
    $script:TestDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_.FullName }
}

AfterAll {
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'git-enhanced.ps1 - New-GitWorktree' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('GIT', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when git is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'git' } -MockWith { return $null }
            
            $result = New-GitWorktree -Path 'test' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Not a Git repository' {
        It 'Returns error when not in a Git repository' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $false }
            
            { New-GitWorktree -Path 'test' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Calls git worktree add with path' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = New-GitWorktree -Path 'test-worktree' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'worktree'
            $script:capturedArgs | Should -Contain 'add'
            $script:capturedArgs | Should -Contain 'test-worktree'
        }
        
        It 'Calls git worktree add with branch' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = New-GitWorktree -Path 'test-worktree' -Branch 'feature-branch' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'feature-branch'
        }
        
        It 'Calls git worktree add with create branch flag' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = New-GitWorktree -Path 'test-worktree' -Branch 'new-branch' -CreateBranch -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-b'
            $script:capturedArgs | Should -Contain 'new-branch'
        }
    }
}

Describe 'git-enhanced.ps1 - Sync-GitRepos' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns empty hashtable when git is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $false
            
            $result = Sync-GitRepos -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
        }
    }
    
    Context 'Tool available' {
        It 'Syncs single repository' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Already up to date.'
            }
            
            $result = Sync-GitRepos -RepositoryPaths @('C:\Repo1') -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [hashtable]
            $result['C:\Repo1'].Success | Should -Be $true
        }
        
        It 'Handles sync failure' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: failed to sync'
            }
            
            $result = Sync-GitRepos -RepositoryPaths @('C:\Repo1') -ErrorAction SilentlyContinue
            
            $result['C:\Repo1'].Success | Should -Be $false
        }
        
        It 'Skips non-Git repositories' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $false }
            
            $result = Sync-GitRepos -RepositoryPaths @('C:\NotARepo') -ErrorAction SilentlyContinue
            
            $result['C:\NotARepo'].Success | Should -Be $false
            $result['C:\NotARepo'].Error | Should -Be 'Not a Git repository'
        }
    }
}

Describe 'git-enhanced.ps1 - Clean-GitBranches' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns empty array when git is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $false
            
            $result = Clean-GitBranches -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [array]
            $result.Count | Should -Be 0
        }
    }
    
    Context 'Not a Git repository' {
        It 'Returns error when not in a Git repository' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq '.git' } -MockWith { return $false }
            
            { Clean-GitBranches -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Lists merged branches' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq '.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-parse') {
                    return 'main'
                }
                elseif ($Arguments -contains 'branch' -and $Arguments -contains '--merged') {
                    return @('  main', '  feature-1', '  feature-2', '* current')
                }
                elseif ($Arguments -contains 'branch' -and $Arguments -contains '-d') {
                    $global:LASTEXITCODE = 0
                    return $null
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Clean-GitBranches -TargetBranch 'main' -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [array]
        }
        
        It 'Respects exclude branches' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq '.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-parse') {
                    return 'main'
                }
                elseif ($Arguments -contains 'branch' -and $Arguments -contains '--merged') {
                    return @('  main', '  develop', '  feature-1')
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Clean-GitBranches -TargetBranch 'main' -ExcludeBranches @('main', 'develop', 'feature-1') -ErrorAction SilentlyContinue
            
            $result.Count | Should -Be 0
        }
        
        It 'Supports dry run' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq '.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-parse') {
                    return 'main'
                }
                elseif ($Arguments -contains 'branch' -and $Arguments -contains '--merged') {
                    return @('  main', '  feature-1')
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-Host { }
            
            $result = Clean-GitBranches -TargetBranch 'main' -DryRun -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Host -Times 1
        }
    }
}

Describe 'git-enhanced.ps1 - Get-GitStats' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when git is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $false
            
            $result = Get-GitStats -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Not a Git repository' {
        It 'Returns error when not in a Git repository' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $false }
            
            { Get-GitStats -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Gets repository statistics' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-list' -and $Arguments -contains '--count') {
                    return '100'
                }
                elseif ($Arguments -contains 'shortlog') {
                    return @('Author 1', 'Author 2')
                }
                elseif ($Arguments -contains 'ls-files' -and $Arguments -notcontains '-z') {
                    return @('file1.txt', 'file2.txt')
                }
                elseif ($Arguments -contains 'ls-files' -and $Arguments -contains '-z') {
                    return @('file1.txt', 'file2.txt')
                }
                elseif ($Arguments -contains 'branch' -and $Arguments -contains '-a') {
                    return @('  main', '  feature-1')
                }
                elseif ($Arguments -contains 'tag') {
                    return @('v1.0.0', 'v1.1.0')
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Get-Content -MockWith { return @('line1', 'line2', 'line3') }
            Mock Measure-Object -MockWith { 
                return [PSCustomObject]@{ Lines = 3 }
            }
            
            $result = Get-GitStats -ErrorAction SilentlyContinue
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveMember 'TotalCommits'
            $result | Should -HaveMember 'Contributors'
        }
        
        It 'Gets statistics with date filters' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-list' -and $Arguments -contains '--count') {
                    return '50'
                }
                elseif ($Arguments -contains 'shortlog') {
                    return @('Author 1')
                }
                elseif ($Arguments -contains 'ls-files') {
                    return @('file1.txt')
                }
                elseif ($Arguments -contains 'branch' -and $Arguments -contains '-a') {
                    return @('  main')
                }
                elseif ($Arguments -contains 'tag') {
                    return @('v1.0.0')
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Get-Content -MockWith { return @('line1') }
            Mock Measure-Object -MockWith { 
                return [PSCustomObject]@{ Lines = 1 }
            }
            
            $result = Get-GitStats -Since '2024-01-01' -Until '2024-12-31' -ErrorAction SilentlyContinue
            
            $result.Since | Should -Be '2024-01-01'
            $result.Until | Should -Be '2024-12-31'
        }
    }
}

Describe 'git-enhanced.ps1 - Get-GitLargeFiles' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('git', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns empty array when git is not available' {
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $false
            
            $result = Get-GitLargeFiles -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [array]
            $result.Count | Should -Be 0
        }
    }
    
    Context 'Not a Git repository' {
        It 'Returns error when not in a Git repository' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $false }
            
            { Get-GitLargeFiles -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Finds large files in repository' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-list' -and $Arguments -contains '--objects') {
                    return @('commit1', 'tree1', 'blob1')
                }
                elseif ($Arguments -contains 'cat-file' -and $Arguments -contains '--batch-check') {
                    return @('blob abc123 2097152 largefile.bin', 'blob def456 512 smallfile.txt')
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Get-GitLargeFiles -MinSize 1048576 -ErrorAction SilentlyContinue
            
            $result | Should -BeOfType [array]
            if ($result.Count -gt 0) {
                $result[0] | Should -HaveMember 'Size'
                $result[0] | Should -HaveMember 'Path'
            }
        }
        
        It 'Respects minimum size parameter' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-list' -and $Arguments -contains '--objects') {
                    return @('blob1', 'blob2')
                }
                elseif ($Arguments -contains 'cat-file' -and $Arguments -contains '--batch-check') {
                    return @('blob abc123 5242880 largefile.bin', 'blob def456 512 smallfile.txt')
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Get-GitLargeFiles -MinSize 1048576 -ErrorAction SilentlyContinue
            
            # Should only return files >= 1MB
            if ($result.Count -gt 0) {
                $result | Where-Object { $_.Size -lt 1048576 } | Should -BeNullOrEmpty
            }
        }
        
        It 'Respects limit parameter' {
            Setup-AvailableCommandMock -CommandName 'git'
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.git' } -MockWith { return $true }
            
            Mock -CommandName 'git' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                if ($Arguments -contains 'rev-list' -and $Arguments -contains '--objects') {
                    return @('blob1', 'blob2', 'blob3', 'blob4', 'blob5')
                }
                elseif ($Arguments -contains 'cat-file' -and $Arguments -contains '--batch-check') {
                    return @(
                        'blob abc123 2097152 file1.bin',
                        'blob def456 2097152 file2.bin',
                        'blob ghi789 2097152 file3.bin',
                        'blob jkl012 2097152 file4.bin',
                        'blob mno345 2097152 file5.bin'
                    )
                }
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Get-GitLargeFiles -Limit 3 -ErrorAction SilentlyContinue
            
            $result.Count | Should -BeLessOrEqual 3
        }
    }
}

