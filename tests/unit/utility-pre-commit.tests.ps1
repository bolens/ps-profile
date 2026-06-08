<#
tests/unit/utility-pre-commit.tests.ps1

.SYNOPSIS
    Behavioral unit tests for scripts/git/pre-commit.ps1 orchestration.
#>

function global:New-PreCommitTestRepository {
    param(
        [int]$FormatExitCode = 0,
        [int]$ValidateExitCode = 0,
        [switch]$OmitValidateScript
    )

    $repo = New-TestTempDirectory -Prefix 'PreCommitRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    $libSource = Join-Path $script:TestRepoRoot 'scripts' 'lib'
    Copy-Item -LiteralPath $libSource -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $gitScriptDir = Join-Path $repo 'scripts' 'git'
    New-Item -ItemType Directory -Path $gitScriptDir -Force | Out-Null
    Copy-Item -LiteralPath $script:PreCommitScript -Destination (Join-Path $gitScriptDir 'pre-commit.ps1') -Force

    $formatDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
    New-Item -ItemType Directory -Path $formatDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $formatDir 'run-format.ps1') -Value "exit $FormatExitCode" -NoNewline

    if (-not $OmitValidateScript) {
        $checksDir = Join-Path $repo 'scripts' 'checks'
        New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $checksDir 'validate-profile.ps1') -Value "exit $ValidateExitCode" -NoNewline
    }

    Push-Location $repo
    try {
        & git init -q 2>$null
    }
    finally {
        Pop-Location
    }

    return $repo
}

function global:Invoke-PreCommitScript {
    param(
        [string]$RepositoryRoot
    )

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'git' 'pre-commit.ps1'
    & pwsh -NoProfile -File $scriptPath 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:PreCommitScript = Join-Path $script:TestRepoRoot 'scripts' 'git' 'pre-commit.ps1'
    $script:GitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'pre-commit.ps1 execution' {
    It 'Passes when formatting and validation both succeed' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }
        $repo = New-PreCommitTestRepository -FormatExitCode 0 -ValidateExitCode 0
        try {
            Invoke-PreCommitScript -RepositoryRoot $repo | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when formatting fails' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }
        $repo = New-PreCommitTestRepository -FormatExitCode 1 -ValidateExitCode 0
        try {
            Invoke-PreCommitScript -RepositoryRoot $repo | Should -Be 1
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when validation fails after formatting succeeds' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }
        $repo = New-PreCommitTestRepository -FormatExitCode 0 -ValidateExitCode 1
        try {
            Invoke-PreCommitScript -RepositoryRoot $repo | Should -Be 1
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Returns setup error when validate-profile.ps1 is missing' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }
        $repo = New-PreCommitTestRepository -OmitValidateScript
        try {
            Invoke-PreCommitScript -RepositoryRoot $repo | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
