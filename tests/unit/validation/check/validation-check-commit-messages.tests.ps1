<#
tests/unit/validation-check-commit-messages.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-commit-messages.ps1 with isolated git repositories.
#>

function global:New-CommitMessagesTestRepository {
    $repo = New-TestTempDirectory -Prefix 'CommitMessagesRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:CommitMessagesScript -Destination (Join-Path $checksDir 'check-commit-messages.ps1') -Force

    Push-Location $repo
    try {
    & git init -q 2>$null
    & git config user.email 'test@example.com' 2>$null
    & git config user.name 'Test User' 2>$null
    & git commit --allow-empty -m 'feat(init): seed repository' -q 2>$null
    }
    finally {
        Pop-Location
    }

    return $repo
}

function global:Invoke-CommitMessagesCheck {
    param(
        [string]$RepositoryRoot,
        [string]$Base = 'HEAD~1'
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'checks' 'check-commit-messages.ps1'
    Push-Location $RepositoryRoot
    try {
    $output = & pwsh -NoProfile -File $scriptPath -Base $Base 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
    }
    finally {
        Pop-Location
    }
}

function global:Add-TestCommit {
    param(
        [string]$RepositoryRoot,
        [string]$Subject
    )

    Push-Location $RepositoryRoot
    try {
    & git commit --allow-empty -m $Subject -q 2>$null
    }
    finally {
        Pop-Location
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
    $script:CommitMessagesScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-commit-messages.ps1'
    $script:GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'check-commit-messages.ps1 execution' {
    It 'Passes when new commits use Conventional Commits subjects' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommitMessagesTestRepository
        Add-TestCommit -RepositoryRoot $repo -Subject 'feat(test): add validated commit'
        Invoke-CommitMessagesCheck -RepositoryRoot $repo | Select-Object -ExpandProperty ExitCode | Should -Be 0
    }

    It 'Fails when a commit subject does not follow Conventional Commits' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommitMessagesTestRepository
        Add-TestCommit -RepositoryRoot $repo -Subject 'bad commit subject'
        Invoke-CommitMessagesCheck -RepositoryRoot $repo | Select-Object -ExpandProperty ExitCode | Should -BeIn @(1, 2)
    }

    It 'Passes when a revert commit subject is excluded from validation' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }

        $repo = New-CommitMessagesTestRepository
        Add-TestCommit -RepositoryRoot $repo -Subject 'Revert "feat(test): experimental change"'
        $result = Invoke-CommitMessagesCheck -RepositoryRoot $repo
                $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Checking commits against base'
    }
}
