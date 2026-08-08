<#
tests/unit/utility/install/utility-install-githooks.tests.ps1

.SYNOPSIS
    Behavioral tests for scripts/git/install-githooks.ps1.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:InstallHooksScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'install-githooks.ps1'
}

Describe 'install-githooks.ps1 execution' {
    BeforeEach {
        $script:RepositoryRoot = New-TestTempDirectory -Prefix 'InstallHooksRepo'
        $script:SourceHooks = Join-Path $script:RepositoryRoot 'scripts' 'git' 'hooks'
        $script:TargetHooks = Join-Path $script:RepositoryRoot '.git' 'hooks'
        $null = New-Item -ItemType Directory -Path $script:SourceHooks -Force
        $null = New-Item -ItemType Directory -Path $script:TargetHooks -Force
        Set-Content -LiteralPath (Join-Path $script:SourceHooks 'commit-msg.ps1') -Value '# commit hook' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:SourceHooks 'pre-push.ps1') -Value '# push hook' -Encoding UTF8
    }

    It 'reports a dry run without writing hook wrappers' {
        { & $script:InstallHooksScript -RepositoryRoot $script:RepositoryRoot -DryRun } | Should -Not -Throw

        Test-Path -LiteralPath (Join-Path $script:TargetHooks 'commit-msg') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:TargetHooks 'pre-push') | Should -BeFalse
    }

    It 'installs portable wrappers for each source hook' {
        { & $script:InstallHooksScript -RepositoryRoot $script:RepositoryRoot } | Should -Not -Throw

        $commitMsgHook = Join-Path $script:TargetHooks 'commit-msg'
        $prePushHook = Join-Path $script:TargetHooks 'pre-push'
        Test-Path -LiteralPath $commitMsgHook | Should -BeTrue
        Test-Path -LiteralPath $prePushHook | Should -BeTrue
        Get-Content -LiteralPath $commitMsgHook -Raw | Should -Match 'commit-msg\.ps1'
        Get-Content -LiteralPath $prePushHook -Raw | Should -Match 'scripts.git.hooks.pre-push\.ps1'
    }

    It 'reinstalls hook wrappers idempotently' {
        & $script:InstallHooksScript -RepositoryRoot $script:RepositoryRoot
        { & $script:InstallHooksScript -RepositoryRoot $script:RepositoryRoot } | Should -Not -Throw

        @(Get-ChildItem -LiteralPath $script:TargetHooks -File).Count | Should -Be 2
    }

    It 'fails when the requested hook directory does not exist' {
        {
            & $script:InstallHooksScript -RepositoryRoot $script:RepositoryRoot -GitDir '.git-missing'
        } | Should -Throw
    }
}
