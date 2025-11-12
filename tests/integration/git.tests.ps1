. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Git Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
        . (Join-Path $script:ProfileDir '11-git.ps1')
    }

    Context 'Git helpers' {
        It 'git shortcuts handle non-git directories' {
            $nonGitDir = Join-Path $TestDrive 'non_git'
            New-Item -ItemType Directory -Path $nonGitDir -Force | Out-Null

            Push-Location $nonGitDir
            try {
                { gs } | Should -Not -Throw
            }
            finally {
                Pop-Location
            }
        }

        It 'Ensure-GitHelper is idempotent' {
            { Ensure-GitHelper; Ensure-GitHelper; Ensure-GitHelper } | Should -Not -Throw
        }

        It 'additional git shortcuts are available' {
            $expectedCommands = @('gl', 'gd', 'gb', 'gco')
            foreach ($cmd in $expectedCommands) {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }

        It 'git shortcuts forward arguments correctly' {
            $testDir = Join-Path $TestDrive 'git_test'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                if (Get-Command git -ErrorAction SilentlyContinue) {
                    git init --quiet 2>&1 | Out-Null
                    { gs --short } | Should -Not -Throw
                    { gl --oneline -5 } | Should -Not -Throw
                }
            }
            finally {
                Pop-Location
            }
        }

        It 'Add-GitChanges function exists' {
            Get-Command Add-GitChanges -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Save-GitCommit function exists' {
            Get-Command Save-GitCommit -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Publish-GitChanges function exists' {
            Get-Command Publish-GitChanges -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-GitLog function exists' {
            Get-Command Get-GitLog -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Compare-GitChanges function exists' {
            Get-Command Compare-GitChanges -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-GitBranch function exists' {
            Get-Command Get-GitBranch -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Switch-GitBranch function exists' {
            Get-Command Switch-GitBranch -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Save-GitCommitWithMessage function exists' {
            Get-Command Save-GitCommitWithMessage -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-GitChanges function exists' {
            Get-Command Get-GitChanges -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Receive-GitChanges function exists' {
            Get-Command Receive-GitChanges -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Test-GitRepositoryContext returns false outside repo' {
            $nonGitDir = Join-Path $TestDrive 'non_git_context'
            New-Item -ItemType Directory -Path $nonGitDir -Force | Out-Null

            Push-Location $nonGitDir
            try {
                $result = Test-GitRepositoryContext
                $result | Should -Be $false
            }
            finally {
                Pop-Location
            }
        }

        It 'Test-GitRepositoryHasCommits returns false in empty repo' {
            $emptyRepoDir = Join-Path $TestDrive 'empty_git'
            New-Item -ItemType Directory -Path $emptyRepoDir -Force | Out-Null

            Push-Location $emptyRepoDir
            try {
                if (Get-Command git -ErrorAction SilentlyContinue) {
                    git init --quiet 2>&1 | Out-Null
                    $result = Test-GitRepositoryHasCommits
                    $result | Should -Be $false
                }
            }
            finally {
                Pop-Location
            }
        }
    }
}
