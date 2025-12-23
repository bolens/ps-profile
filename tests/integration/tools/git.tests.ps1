Describe 'Git Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
                throw "Get-TestPath returned null or empty value for BootstrapPath"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
            
            $gitPath = Join-Path $script:ProfileDir 'git.ps1'
            if ($null -eq $gitPath -or [string]::IsNullOrWhiteSpace($gitPath)) {
                throw "GitPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $gitPath)) {
                throw "Git fragment not found at: $gitPath"
            }
            . $gitPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize git tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
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
            # Mock git as available for consistent test behavior
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $true
            
            $testDir = Join-Path $TestDrive 'git_test'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            Push-Location $testDir
            try {
                # Mock git init to avoid actual git operations
                Mock -CommandName 'git' -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains 'init') {
                        $global:LASTEXITCODE = 0
                        return
                    }
                    # For other git commands, return empty output
                    $global:LASTEXITCODE = 0
                    return ''
                }
                
                git init --quiet 2>&1 | Out-Null
                { gs --short } | Should -Not -Throw
                { gl --oneline -5 } | Should -Not -Throw
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
            # Mock git as available for consistent test behavior
            Mock-CommandAvailabilityPester -CommandName 'git' -Available $true
            
            $emptyRepoDir = Join-Path $TestDrive 'empty_git'
            New-Item -ItemType Directory -Path $emptyRepoDir -Force | Out-Null

            Push-Location $emptyRepoDir
            try {
                # Mock git init and git log to simulate empty repo
                Mock -CommandName 'git' -MockWith {
                    param([string[]]$ArgumentList)
                    if ($ArgumentList -contains 'init') {
                        $global:LASTEXITCODE = 0
                        return
                    }
                    if ($ArgumentList -contains 'log') {
                        $global:LASTEXITCODE = 0
                        return ''  # Empty log = no commits
                    }
                    $global:LASTEXITCODE = 0
                    return ''
                }
                
                git init --quiet 2>&1 | Out-Null
                $result = Test-GitRepositoryHasCommits
                $result | Should -Be $false
            }
            finally {
                Pop-Location
            }
        }
    }
}

