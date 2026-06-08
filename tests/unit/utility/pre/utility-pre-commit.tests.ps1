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
    $output = & pwsh -NoProfile -File $scriptPath 2>&1 | Out-String
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
            Invoke-PreCommitScript -RepositoryRoot $repo | Select-Object -ExpandProperty ExitCode | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Announces formatting before validation in hook output' {
        if (-not $script:GitAvailable) {
            Set-ItResult -Skipped -Because 'git is not installed'
            return
        }
        $repo = New-PreCommitTestRepository -FormatExitCode 0 -ValidateExitCode 0
        try {
            $result = Invoke-PreCommitScript -RepositoryRoot $repo
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Running code formatting'
            $result.Output | Should -Match 'Running profile validation|Running validation'
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
            $result = Invoke-PreCommitScript -RepositoryRoot $repo
            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'formatting failed|Code formatting failed'
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
            $result = Invoke-PreCommitScript -RepositoryRoot $repo
            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'validation failed|Validation checks failed'
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
            $result = Invoke-PreCommitScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'validate-profile|not found|Setup'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
