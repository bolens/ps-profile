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

    # Mirror real layout: scripts/git/hooks/commit-msg.ps1
    $hooksDir = Join-Path $scriptsDir 'git' 'hooks'
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:CommitMsgHookScript -Destination (Join-Path $hooksDir 'commit-msg.ps1') -Force

    Push-Location $repo
    try { & git init -q 2>$null } finally { Pop-Location }

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
    $raw = & pwsh -NoProfile -File $HookPath -CommitMsgFile $msgFile 2>&1
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($raw | Out-String)
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
    $script:CommitMsgHookScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks' 'commit-msg.ps1'
    $ConfirmPreference = 'None'
}

Describe 'commit-msg.ps1 execution' {
    It 'Accepts a valid Conventional Commit subject' {
        $fixture = New-CommitMsgHookFixture
        (Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "feat(cli): add hook test`n").ExitCode | Should -Be 0
    }

    It 'Rejects an invalid commit subject' {
        $fixture = New-CommitMsgHookFixture
        (Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "bad commit message`n").ExitCode | Should -BeIn @(1, 2)
    }

    It 'Allows merge commit subjects' {
        $fixture = New-CommitMsgHookFixture
        (Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "Merge branch 'main' into feature`n").ExitCode | Should -Be 0
    }

    It 'Accepts revert commits with a Conventional Commit subject' {
        $fixture = New-CommitMsgHookFixture
        (Invoke-CommitMsgHook -HookPath $fixture.HookPath -Message "revert: feat(cli): roll back hook test`n").ExitCode | Should -Be 0
    }

    It 'Fails when the commit message file is missing' {
        $fixture = New-CommitMsgHookFixture
        $raw = & pwsh -NoProfile -File $fixture.HookPath -CommitMsgFile (Join-Path $fixture.RepoRoot 'missing.txt') 2>&1
        $LASTEXITCODE | Should -BeIn @(1, 2)
        ($raw | Out-String) | Should -Match 'not provided or not found|commit-msg'
    }
}
