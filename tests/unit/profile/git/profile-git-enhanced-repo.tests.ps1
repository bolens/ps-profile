# ===============================================
# profile-git-enhanced-repo.tests.ps1
# Unit tests for Git repository management functions
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'git-enhanced.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'GitEnhancedRepo'
    $script:GitRepo = Join-Path $script:TestRoot 'repo'
    $script:NonGitRepo = Join-Path $script:TestRoot 'not-a-repo'
    $script:WorktreePath = Join-Path $script:TestRoot 'worktree'

    New-Item -ItemType Directory -Path $script:GitRepo -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:GitRepo '.git') -Force | Out-Null
    New-Item -ItemType Directory -Path $script:NonGitRepo -Force | Out-Null
    Set-Content -Path (Join-Path $script:GitRepo 'file1.txt') -Value "line1`nline2`nline3" -Encoding utf8
    Set-Content -Path (Join-Path $script:GitRepo 'file2.txt') -Value "line1`nline2" -Encoding utf8
}

Describe 'git-enhanced.ps1 - New-GitWorktree' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'git'
    }

    Context 'Tool not available' {
        It 'Returns null when git is not available' {
            $result = New-GitWorktree -Path 'test' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Not a Git repository' {
        It 'Returns null when not in a Git repository' {
            Setup-CapturingCommandMock -CommandName 'git'

            $result = New-GitWorktree -Path 'test' -RepositoryPath $script:NonGitRepo -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'Tool available' {
        It 'Calls git worktree add with path' {
            Setup-CapturingCommandMock -CommandName 'git' -ExitCode 0

            New-GitWorktree -Path 'test-worktree' -RepositoryPath $script:GitRepo -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'worktree'
            $args | Should -Contain 'add'
            $args | Should -Contain 'test-worktree'
        }

        It 'Calls git worktree add with branch' {
            Setup-CapturingCommandMock -CommandName 'git' -ExitCode 0

            New-GitWorktree -Path 'test-worktree' -Branch 'feature-branch' -RepositoryPath $script:GitRepo -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'feature-branch'
        }

        It 'Calls git worktree add with create branch flag' {
            Setup-CapturingCommandMock -CommandName 'git' -ExitCode 0

            New-GitWorktree -Path 'test-worktree' -Branch 'new-branch' -CreateBranch -RepositoryPath $script:GitRepo -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-b'
            $args | Should -Contain 'new-branch'
        }
    }
}

Describe 'git-enhanced.ps1 - Sync-GitRepos' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'git'
    }

    Context 'Tool not available' {
        It 'Returns empty hashtable when git is not available' {
            $result = Sync-GitRepos -ErrorAction SilentlyContinue

            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
        }
    }

    Context 'Tool available' {
        It 'Syncs single repository' {
            Setup-CapturingCommandMock -CommandName 'git' -ExitCode 0 -Output 'Already up to date.'

            $result = Sync-GitRepos -RepositoryPaths @($script:GitRepo) -ErrorAction SilentlyContinue

            $result | Should -BeOfType [hashtable]
            $result[$script:GitRepo].Success | Should -Be $true
        }

        It 'Handles sync failure' {
            Setup-CapturingCommandMock -CommandName 'git' -ExitCode 1 -Output 'Error: failed to sync'

            $result = Sync-GitRepos -RepositoryPaths @($script:GitRepo) -ErrorAction SilentlyContinue

            $result[$script:GitRepo].Success | Should -Be $false
        }

        It 'Skips non-Git repositories' {
            Setup-CapturingCommandMock -CommandName 'git'

            $result = Sync-GitRepos -RepositoryPaths @($script:NonGitRepo) -ErrorAction SilentlyContinue

            $result[$script:NonGitRepo].Success | Should -Be $false
            $result[$script:NonGitRepo].Error | Should -Be 'Not a Git repository'
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }
}

Describe 'git-enhanced.ps1 - Clean-GitBranches' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'git'
    }

    Context 'Tool not available' {
        It 'Returns empty array when git is not available' {
            $result = Clean-GitBranches -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Not a Git repository' {
        It 'Returns empty array when not in a Git repository' {
            Setup-CapturingCommandMock -CommandName 'git'

            Push-Location $script:NonGitRepo
            try {
                $result = Clean-GitBranches -ErrorAction SilentlyContinue
                @($result).Count | Should -Be 0
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Tool available' {
        BeforeEach {
            Push-Location $script:GitRepo
        }

        AfterEach {
            Pop-Location
        }

        It 'Lists merged branches' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains 'rev-parse') {
                    return 'main'
                }
                if ($flatArgs -contains '--merged') {
                    return @('  main', '  feature-1', '  feature-2', '* current')
                }
                if ($flatArgs -contains '-d') {
                    return $null
                }
                return $null
            }

            $result = Clean-GitBranches -TargetBranch 'main' -Confirm:$false -ErrorAction SilentlyContinue

            @($result).Count | Should -BeGreaterThan 0
        }

        It 'Respects exclude branches' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains 'rev-parse') {
                    return 'main'
                }
                if ($flatArgs -contains '--merged') {
                    return @('  main', '  develop', '  feature-1')
                }
                return $null
            }

            $result = Clean-GitBranches -TargetBranch 'main' -ExcludeBranches @('main', 'develop', 'feature-1') -ErrorAction SilentlyContinue

            @($result).Count | Should -Be 0
        }

        It 'Supports dry run' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains 'rev-parse') {
                    return 'main'
                }
                if ($flatArgs -contains '--merged') {
                    return @('  main', '  feature-1')
                }
                return $null
            }

            $result = Clean-GitBranches -TargetBranch 'main' -DryRun -ErrorAction SilentlyContinue

            $result | Should -Contain 'feature-1'
        }
    }
}

Describe 'git-enhanced.ps1 - Get-GitStats' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'git'
    }

    Context 'Tool not available' {
        It 'Returns null when git is not available' {
            $result = Get-GitStats -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Not a Git repository' {
        It 'Returns null when not in a Git repository' {
            Setup-CapturingCommandMock -CommandName 'git'

            $result = Get-GitStats -RepositoryPath $script:NonGitRepo -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'Tool available' {
        It 'Gets repository statistics' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains 'rev-list' -and $flatArgs -contains '--count') {
                    return '100'
                }
                if ($flatArgs -contains 'shortlog') {
                    return @('Author 1', 'Author 2')
                }
                if ($flatArgs -contains 'ls-files' -and $flatArgs -notcontains '-z') {
                    return @('file1.txt', 'file2.txt')
                }
                if ($flatArgs -contains 'ls-files' -and $flatArgs -contains '-z') {
                    return @('file1.txt', 'file2.txt')
                }
                if ($flatArgs -contains 'branch' -and $flatArgs -contains '-a') {
                    return @('  main', '  feature-1')
                }
                if ($flatArgs -contains 'tag') {
                    return @('v1.0.0', 'v1.1.0')
                }
                return $null
            }

            $result = Get-GitStats -RepositoryPath $script:GitRepo -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'TotalCommits'
            $result.PSObject.Properties.Name | Should -Contain 'Contributors'
            $result.TotalCommits | Should -Be 100
        }

        It 'Gets statistics with date filters' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains 'rev-list' -and $flatArgs -contains '--count') {
                    return '50'
                }
                if ($flatArgs -contains 'shortlog') {
                    return @('Author 1')
                }
                if ($flatArgs -contains 'ls-files') {
                    return @('file1.txt')
                }
                if ($flatArgs -contains 'branch' -and $flatArgs -contains '-a') {
                    return @('  main')
                }
                if ($flatArgs -contains 'tag') {
                    return @('v1.0.0')
                }
                return $null
            }

            $result = Get-GitStats -RepositoryPath $script:GitRepo -Since '2024-01-01' -Until '2024-12-31' -ErrorAction SilentlyContinue

            $result.Since | Should -Be '2024-01-01'
            $result.Until | Should -Be '2024-12-31'
            $result.TotalCommits | Should -Be 50
        }
    }
}

Describe 'git-enhanced.ps1 - Get-GitLargeFiles' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'git'
    }

    Context 'Tool not available' {
        It 'Returns empty array when git is not available' {
            $result = Get-GitLargeFiles -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Not a Git repository' {
        It 'Returns empty array when not in a Git repository' {
            Setup-CapturingCommandMock -CommandName 'git'

            $result = Get-GitLargeFiles -RepositoryPath $script:NonGitRepo -ErrorAction SilentlyContinue

            @($result).Count | Should -Be 0
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }
    }

    Context 'Tool available' {
        It 'Finds large files in repository' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains '--objects') {
                    return @('commit1', 'tree1', 'blob1')
                }
                if (@($flatArgs | Where-Object { $_ -like '*batch-check*' }).Count -gt 0) {
                    return @('blob abc123 2097152 largefile.bin', 'blob def456 512 smallfile.txt')
                }
                return $null
            }

            $result = Get-GitLargeFiles -RepositoryPath $script:GitRepo -MinSize 1048576 -ErrorAction SilentlyContinue

            @($result).Count | Should -BeGreaterThan 0
            $result[0].PSObject.Properties.Name | Should -Contain 'Size'
            $result[0].PSObject.Properties.Name | Should -Contain 'Path'
        }

        It 'Respects minimum size parameter' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains '--objects') {
                    return @('blob1', 'blob2')
                }
                if (@($flatArgs | Where-Object { $_ -like '*batch-check*' }).Count -gt 0) {
                    return @('blob abc123 5242880 largefile.bin', 'blob def456 512 smallfile.txt')
                }
                return $null
            }

            $result = Get-GitLargeFiles -RepositoryPath $script:GitRepo -MinSize 1048576 -ErrorAction SilentlyContinue

            if (@($result).Count -gt 0) {
                @($result | Where-Object { $_.Size -lt 1048576 }).Count | Should -Be 0
            }
        }

        It 'Respects limit parameter' {
            Setup-CapturingCommandMock -CommandName 'git' -OnInvoke {
                $flatArgs = @($args)
                if ($flatArgs -contains '--objects') {
                    return @('blob1', 'blob2', 'blob3', 'blob4', 'blob5')
                }
                if (@($flatArgs | Where-Object { $_ -like '*batch-check*' }).Count -gt 0) {
                    return @(
                        'blob abc123 2097152 file1.bin',
                        'blob def456 2097152 file2.bin',
                        'blob ghi789 2097152 file3.bin',
                        'blob jkl012 2097152 file4.bin',
                        'blob mno345 2097152 file5.bin'
                    )
                }
                return $null
            }

            $result = Get-GitLargeFiles -RepositoryPath $script:GitRepo -Limit 3 -ErrorAction SilentlyContinue

            @($result).Count | Should -BeLessOrEqual 3
        }
    }
}
