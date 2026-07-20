<#
tests/unit/utility-pre-push.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/git/hooks/pre-push.ps1 orchestration.
#>

function global:New-PrePushTestRepository {
    param(
        [int]$ValidateExitCode = 0,
        [int]$ChangedShardsExitCode = 0,
        [switch]$OmitValidateScript,
        [switch]$OmitChangedShardsScript
    )

    $repo = New-TestTempDirectory -Prefix 'PrePushRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    if (-not $OmitValidateScript) {
        $checksDir = Join-Path $scriptsDir 'checks'
        New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $checksDir 'validate-profile.ps1') -Value "exit $ValidateExitCode" -NoNewline
    }

    if (-not $OmitChangedShardsScript) {
        $cqDir = Join-Path $scriptsDir 'utils' 'code-quality'
        New-Item -ItemType Directory -Path $cqDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $cqDir 'run-pester-changed-shards.ps1') -Value "exit $ChangedShardsExitCode" -NoNewline
    }

    $hooksDir = Join-Path $scriptsDir 'git' 'hooks'
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:PrePushHookScript -Destination (Join-Path $hooksDir 'pre-push.ps1') -Force

    Push-Location $repo
    try {
        & git init -q 2>$null
    }
    finally {
        Pop-Location
    }

    return $repo
}

function global:Invoke-PrePushHook {
    param(
        [string]$RepositoryRoot,
        [hashtable]$Environment = @{}
    )

    $hookPath = Join-Path $RepositoryRoot 'scripts' 'git' 'hooks' 'pre-push.ps1'
    $envAssignments = foreach ($key in $Environment.Keys) {
        "`$env:$key = '$($Environment[$key] -replace "'", "''")'"
    }
    $envBlock = if ($envAssignments) { ($envAssignments -join '; ') + '; ' } else { '' }

    $output = & pwsh -NoProfile -Command @"
$envBlock
& '$($hookPath -replace "'", "''")'
exit `$LASTEXITCODE
"@ 2>&1 | Out-String

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
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
    $script:PrePushHookScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'hooks' 'pre-push.ps1'
    $ConfirmPreference = 'None'
}

Describe 'pre-push.ps1 execution' {
    It 'Passes quickly by default without running validate or shard tests' {
        $repo = New-PrePushTestRepository -ValidateExitCode 1 -ChangedShardsExitCode 1
        $result = Invoke-PrePushHook -RepositoryRoot $repo
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'skipping validate-profile'
        $result.Output | Should -Match 'skipping changed-shard tests'
        $result.Output | Should -Match 'pre-push: all checks passed'
    }

    It 'Runs validate-profile when PS_PROFILE_PUSH_VALIDATE=1' {
        $repo = New-PrePushTestRepository -ValidateExitCode 0 -ChangedShardsExitCode 1
        $result = Invoke-PrePushHook -RepositoryRoot $repo -Environment @{
            PS_PROFILE_PUSH_VALIDATE = '1'
        }
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'running validate-profile'
        $result.Output | Should -Match 'skipping changed-shard tests'
    }

    It 'Fails when opt-in validate-profile returns non-zero' {
        $repo = New-PrePushTestRepository -ValidateExitCode 1
        $result = Invoke-PrePushHook -RepositoryRoot $repo -Environment @{
            PS_PROFILE_PUSH_VALIDATE = '1'
        }
        $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'validate-profile failed|pre-push: validate-profile failed'
    }

    It 'Fails when validate-profile.ps1 is missing and validate is opted in' {
        $repo = New-PrePushTestRepository -OmitValidateScript
        $result = Invoke-PrePushHook -RepositoryRoot $repo -Environment @{
            PS_PROFILE_PUSH_VALIDATE = '1'
        }
        $result.ExitCode | Should -BeIn @(1, 2, 3)
        $result.Output | Should -Match 'validate-profile|not found|failed'
    }

    It 'Runs changed-shard tests when PS_PROFILE_PUSH_TESTS=1' {
        $repo = New-PrePushTestRepository -ValidateExitCode 1 -ChangedShardsExitCode 0
        $result = Invoke-PrePushHook -RepositoryRoot $repo -Environment @{
            PS_PROFILE_PUSH_TESTS = '1'
        }
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'running Pester CI shards'
        $result.Output | Should -Match 'skipping validate-profile'
    }

    It 'Fails when opt-in changed-shard runner returns non-zero' {
        $repo = New-PrePushTestRepository -ValidateExitCode 0 -ChangedShardsExitCode 1
        $result = Invoke-PrePushHook -RepositoryRoot $repo -Environment @{
            PS_PROFILE_PUSH_TESTS = '1'
        }
        $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'changed-shard Pester run failed'
    }

    It 'Skips opt-in tests when PS_PROFILE_SKIP_PUSH_TESTS=1' {
        $repo = New-PrePushTestRepository -ValidateExitCode 0 -ChangedShardsExitCode 1
        $result = Invoke-PrePushHook -RepositoryRoot $repo -Environment @{
            PS_PROFILE_PUSH_TESTS      = '1'
            PS_PROFILE_SKIP_PUSH_TESTS = '1'
        }
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'skipping changed-shard tests'
    }
}
