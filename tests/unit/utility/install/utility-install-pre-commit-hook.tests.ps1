<#
tests/unit/utility-install-pre-commit-hook.tests.ps1

.SYNOPSIS
    Behavioral unit tests for install-pre-commit-hook.ps1.
#>

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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:InstallHookScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'install-pre-commit-hook.ps1'
    $ConfirmPreference = 'None'
}

Describe 'install-pre-commit-hook.ps1 execution' {
    It 'Fails when the repository root does not contain a .git directory' {
        $repo = New-TestTempDirectory -Prefix 'InstallHookNoGit'
        try {
            $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $repo)

            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'No \.git directory found'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Installs a pre-commit hook that invokes scripts/git/pre-commit.ps1' {
        $fixture = New-TestGitRepositoryWithHook
        try {
            $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $fixture.RepoRoot)

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Installed pre-commit hook'
            Test-Path -LiteralPath $fixture.HookPath | Should -BeTrue
            Get-Content -LiteralPath $fixture.HookPath -Raw | Should -Match 'pre-commit\.ps1'
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepoRoot) {
                Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Does not create git-hooks backups when no pre-commit hook exists yet' {
        $fixture = New-TestGitRepositoryWithHook
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop

        try {
            $result = Invoke-BackupTestScript -ScriptPath $script:InstallHookScript -ArgumentList @('-RepoRoot', $fixture.RepoRoot)

            $result.ExitCode | Should -Be 0
            @(Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks').Count | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepoRoot) {
                Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
