<#
tests/unit/utility-git-commit-msg.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/git/hooks/commit-msg.ps1.
#>

function global:New-CommitMsgHookFixture {
    $repo = New-TestTempDirectory -Prefix 'CommitMsgHookRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $hooksDir = Join-Path $repo '.git' 'hooks'
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:CommitMsgHookScript -Destination (Join-Path $hooksDir 'commit-msg.ps1') -Force

    return [pscustomobject]@{
        RepoRoot = $repo
        HookPath = Join-Path $hooksDir 'commit-msg.ps1'
    }
}

function global:Invoke-CommitMsgHook {
    param(
        [string]$HookPath,
        [string]$Message
    )

    $msgFile = New-TestTempFile -Prefix 'CommitMsg' -Extension '.txt' -Content $Message
    & pwsh -NoProfile -File $HookPath -CommitMsgFile $msgFile 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CommitMsgHookScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks' 'commit-msg.ps1'
    $ConfirmPreference = 'None'
}

Describe 'commit-msg.ps1 execution' {
    It 'Accepts a valid Conventional Commit subject' {
        $fixture = New-CommitMsgHookFixture
        try {
            Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "feat(cli): add hook test`n" | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepoRoot) {
                Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Rejects an invalid commit subject' {
        $fixture = New-CommitMsgHookFixture
        try {
            Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "bad commit message`n" | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepoRoot) {
                Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Allows merge commit subjects' {
        $fixture = New-CommitMsgHookFixture
        try {
            Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "Merge branch 'main' into feature`n" | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepoRoot) {
                Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the commit message file is missing' {
        $fixture = New-CommitMsgHookFixture
        try {
            & pwsh -NoProfile -File $fixture.HookPath -CommitMsgFile (Join-Path $fixture.RepoRoot 'missing.txt') 2>&1 | Out-Null
            $LASTEXITCODE | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepoRoot) {
                Remove-Item -LiteralPath $fixture.RepoRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
