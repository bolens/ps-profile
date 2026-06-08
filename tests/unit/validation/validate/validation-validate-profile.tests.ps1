<#
tests/unit/validation-validate-profile.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-profile.ps1 orchestration with stubbed checks.
#>

function global:New-ValidateProfileTestRepository {
    param(
        [int]$SecurityExitCode = 0,
        [int]$LintExitCode = 0,
        [int]$SpellcheckExitCode = 0,
        [int]$CommentHelpExitCode = 0,
        [int]$IdempotencyExitCode = 0,
        [int]$DuplicateExitCode = 0
    )

    $repo = New-TestTempDirectory -Prefix 'ValidateProfileRepo'
    $scriptsDir = Join-Path $repo 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $scriptsDir 'lib') -Recurse -Force

    $checksDir = Join-Path $scriptsDir 'checks'
    New-Item -ItemType Directory -Path $checksDir -Force | Out-Null
    Copy-Item -LiteralPath $script:ValidateProfileScript -Destination (Join-Path $checksDir 'validate-profile.ps1') -Force

  @(
        @{ Relative = 'utils/security/run-security-scan.ps1'; ExitCode = $SecurityExitCode }
        @{ Relative = 'utils/code-quality/run-lint.ps1'; ExitCode = $LintExitCode }
        @{ Relative = 'utils/code-quality/spellcheck.ps1'; ExitCode = $SpellcheckExitCode }
        @{ Relative = 'checks/check-comment-help.ps1'; ExitCode = $CommentHelpExitCode }
        @{ Relative = 'checks/check-idempotency.ps1'; ExitCode = $IdempotencyExitCode }
        @{ Relative = 'utils/metrics/find-duplicate-functions.ps1'; ExitCode = $DuplicateExitCode }
    ) | ForEach-Object {
        $target = Join-Path $scriptsDir $_.Relative
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Set-Content -LiteralPath $target -Value "exit $($_.ExitCode)" -NoNewline
    }

    New-Item -ItemType Directory -Path (Join-Path $repo 'profile.d') -Force | Out-Null

    Push-Location $repo
    try {
        git init -q | Out-Null
        git config user.email 'fixture@example.com'
        git config user.name 'Fixture'
    }
    finally {
        Pop-Location
    }

    return $repo
}

function global:Invoke-ValidateProfileScript {
    param([string]$RepositoryRoot)

    $scriptPath = Join-Path $RepositoryRoot 'scripts' 'checks' 'validate-profile.ps1'
    Push-Location $RepositoryRoot
    try {
        $output = & pwsh -NoProfile -File $scriptPath 2>&1 | Out-String
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = $output
        }
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
    $script:ValidateProfileScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'validate-profile.ps1'
    $ConfirmPreference = 'None'
}

Describe 'validate-profile.ps1 execution' {
    It 'Passes when all stubbed validation checks succeed' {
        $repo = New-ValidateProfileTestRepository
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the security scan stub returns a non-zero exit code' {
        $repo = New-ValidateProfileTestRepository -SecurityExitCode 1
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'security scan failed|Running security scan'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the lint stub returns a non-zero exit code' {
        $repo = New-ValidateProfileTestRepository -LintExitCode 1
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'lint failed|Running lint'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the spellcheck stub returns a non-zero exit code' {
        $repo = New-ValidateProfileTestRepository -SpellcheckExitCode 1
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'spellcheck failed|Running spellcheck'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the idempotency stub returns a non-zero exit code' {
        $repo = New-ValidateProfileTestRepository -IdempotencyExitCode 1
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'idempotency failed|Running idempotency'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the comment-help stub returns a non-zero exit code' {
        $repo = New-ValidateProfileTestRepository -CommentHelpExitCode 1
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'comment-based help check failed|Running comment-based help check'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the duplicate-functions stub returns a non-zero exit code' {
        $repo = New-ValidateProfileTestRepository -DuplicateExitCode 1
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'duplicate functions failed|Running duplicate functions'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Reports the full validation success message when all stubbed checks pass' {
        $repo = New-ValidateProfileTestRepository
        try {
            $result = Invoke-ValidateProfileScript -RepositoryRoot $repo
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Validation: security \+ lint \+ spellcheck \+ comment help \+ idempotency \+ duplicate functions passed'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
