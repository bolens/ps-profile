<#
tests/unit/utility-install-pre-commit-hook.tests.ps1

.SYNOPSIS
    Behavioral unit tests for install-pre-commit-hook.ps1.
#>

function global:Invoke-InstallHookInProcess {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,

        [switch]$Windows,

        [switch]$Restore,

        [switch]$Prune,

        [switch]$Force,

        [int]$KeepCount = 10,

        [switch]$UseDefaultActions
    )

    $platformTest = { $Windows.IsPresent }.GetNewClosure()
    $arguments = @{
        RepoRoot  = $RepoRoot
        Restore   = $Restore
        Prune     = $Prune
        Force     = $Force
        KeepCount = $KeepCount
        PassThru  = $true
    }
    if (-not $UseDefaultActions) {
        $arguments.PlatformTestAction = $platformTest
        $arguments.CommandTestAction = { param($CommandName) $false }
        $arguments.PowerShellExecutableAction = { 'pwsh' }
    }
    $records = @(& $script:InstallHookScript @arguments *>&1)
    $exitResult = $records | Where-Object { $_.PSObject.Properties.Name -contains 'ExitCode' } | Select-Object -Last 1
    $output = @($records | Where-Object { $_ -ne $exitResult }) | Out-String -Width 4096
    if ($exitResult.Message) { $output = "$output$($exitResult.Message)" }

    [PSCustomObject]@{
        ExitCode = $exitResult.ExitCode
        Output   = $output
    }
}

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
        $result = Invoke-InstallHookInProcess -RepoRoot $repo

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'No Git worktree found'
    }

    It 'Installs a pre-commit hook that invokes scripts/git/pre-commit.ps1' {
        $fixture = New-TestGitRepositoryWithHook
        $result = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Installed pre-commit hook'
        Test-Path -LiteralPath $fixture.HookPath | Should -BeTrue
        Get-Content -LiteralPath $fixture.HookPath -Raw | Should -Match 'pre-commit\.ps1'
    }

    It 'Does not create git-hooks backups when no pre-commit hook exists yet' {
        $fixture = New-TestGitRepositoryWithHook
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'file' 'FileBackup.psm1') -DisableNameChecking -ErrorAction Stop

        $result = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot

        $result.ExitCode | Should -Be 0
        @(Get-FileBackups -RepoRoot $fixture.RepoRoot -Category 'git-hooks').Count | Should -Be 0
    }

    It 'Reinstalls the pre-commit hook idempotently when run a second time' {
        $fixture = New-TestGitRepositoryWithHook
        $first = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot
        $second = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot

        $first.ExitCode | Should -Be 0
        $second.ExitCode | Should -Be 0
        Test-Path -LiteralPath $fixture.HookPath | Should -BeTrue
        Get-Content -LiteralPath $fixture.HookPath -Raw | Should -Match 'pre-commit\.ps1'
    }

    It 'Writes a PowerShell hook for Windows repositories' {
        $fixture = New-TestGitRepositoryWithHook
        $result = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot -Windows

        $result.ExitCode | Should -Be 0
        Get-Content -LiteralPath $fixture.HookPath -Raw | Should -Match '#!/usr/bin/env pwsh'
    }

    It 'Uses default local probes for an isolated repository hook' {
        $fixture = New-TestGitRepositoryWithHook
        $result = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot -UseDefaultActions

        $result.ExitCode | Should -Be 0
        Test-Path -LiteralPath $fixture.HookPath | Should -BeTrue
    }

    It 'Prunes and restores hook backups in the isolated repository' {
        $fixture = New-TestGitRepositoryWithHook
        Set-Content -LiteralPath $fixture.HookPath -Value '# original hook' -Encoding UTF8
        (Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot).ExitCode | Should -Be 0

        $prune = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot -Prune -KeepCount 10
        $restore = Invoke-InstallHookInProcess -RepoRoot $fixture.RepoRoot -Restore -Force

        $prune.ExitCode | Should -Be 0
        $prune.Output | Should -Match 'Pruned'
        $restore.ExitCode | Should -Be 0
        $restore.Output | Should -Match 'Restored pre-commit hook'
    }
}
