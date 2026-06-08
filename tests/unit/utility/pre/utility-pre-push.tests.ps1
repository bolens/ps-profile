<#
tests/unit/utility-pre-push.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/git/hooks/pre-push.ps1 orchestration.
#>

function global:New-PrePushTestRepository {
    param(
        [int]$ValidateExitCode = 0
    )

    $repo = New-TestTempDirectory -Prefix 'PrePushRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $checksDir 'validate-profile.ps1') -Value "exit $ValidateExitCode" -NoNewline

    $hooksDir = Join-Path $repo '.git' 'hooks'
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:PrePushHookScript -Destination (Join-Path $hooksDir 'pre-push.ps1') -Force

    return $repo
}

function global:Invoke-PrePushHook {
    param(
        [string]$RepositoryRoot
    )

    $hookPath = Join-Path $RepositoryRoot '.git' 'hooks' 'pre-push.ps1'
    & pwsh -NoProfile -File $hookPath 2>&1 | Out-Null
    return $LASTEXITCODE
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
    $script:PrePushHookScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks' 'pre-push.ps1'
    $ConfirmPreference = 'None'
}

Describe 'pre-push.ps1 execution' {
    It 'Passes when validate-profile succeeds' {
        $repo = New-PrePushTestRepository -ValidateExitCode 0
        try {
            Invoke-PrePushHook -RepositoryRoot $repo | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when validate-profile returns a non-zero exit code' {
        $repo = New-PrePushTestRepository -ValidateExitCode 1
        try {
            Invoke-PrePushHook -RepositoryRoot $repo | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
