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
    }
}
