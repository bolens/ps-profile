<#
tests/unit/validation/check/validation-check-idempotency.tests.ps1

.SYNOPSIS
    Behavioral tests for check-idempotency.ps1 using isolated fragments.
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
    $script:CheckIdempotencyScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-idempotency.ps1'

    function global:Invoke-IdempotencyFixture {
        param(
            [switch]$NoProfile,
            [string]$File
        )

        $global:IdempotencyRunnerContent = Get-Content -LiteralPath $File -Raw
        if ($env:PS_PROFILE_FAIL_IDEMPOTENCY -eq 'empty') {
            $global:LASTEXITCODE = 5
            return
        }
        if ($env:PS_PROFILE_FAIL_IDEMPOTENCY -eq 'output') {
            Write-Output 'fixture runner failure'
            $global:LASTEXITCODE = 6
            return
        }
        $global:LASTEXITCODE = 0
    }
}

Describe 'check-idempotency.ps1 execution' {
    BeforeEach {
        $script:FixtureRoot = New-TestTempDirectory -Prefix 'Idempotency'
        $script:PreviousFailure = $env:PS_PROFILE_FAIL_IDEMPOTENCY
        Remove-Item Env:PS_PROFILE_FAIL_IDEMPOTENCY -ErrorAction SilentlyContinue
        $global:IdempotencyRunnerContent = $null
    }

    AfterEach {
        if ($null -eq $script:PreviousFailure) {
            Remove-Item Env:PS_PROFILE_FAIL_IDEMPOTENCY -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_FAIL_IDEMPOTENCY = $script:PreviousFailure
        }
    }

    It 'loads priority fragments first and repeats the same portable order' {
        foreach ($name in @('zeta.ps1', 'env.ps1', 'alpha.ps1', 'bootstrap.ps1')) {
            Set-Content -LiteralPath (Join-Path $script:FixtureRoot $name) -Value "'$name'" -Encoding UTF8
        }

        $output = & $script:CheckIdempotencyScript `
            -ProfilePath $script:FixtureRoot `
            -PowerShellExecutable 'Invoke-IdempotencyFixture' 2>&1 | Out-String

        $output | Should -Match 'all profile.d fragments loaded twice'
        ([regex]::Matches($global:IdempotencyRunnerContent, [regex]::Escape('bootstrap.ps1'))).Count | Should -Be 2
        ([regex]::Matches($global:IdempotencyRunnerContent, [regex]::Escape('env.ps1'))).Count | Should -Be 2
        $global:IdempotencyRunnerContent.IndexOf('bootstrap.ps1') |
            Should -BeLessThan $global:IdempotencyRunnerContent.IndexOf('alpha.ps1')
    }

    It 'escapes apostrophes in fragment paths for the generated PowerShell script' {
        $quotedDirectory = Join-Path $script:FixtureRoot "profile's"
        $null = New-Item -ItemType Directory -Path $quotedDirectory -Force
        Set-Content -LiteralPath (Join-Path $quotedDirectory 'alpha.ps1') -Value "'alpha'" -Encoding UTF8

        $null = & $script:CheckIdempotencyScript `
            -ProfilePath $quotedDirectory `
            -PowerShellExecutable 'Invoke-IdempotencyFixture'

        $global:IdempotencyRunnerContent | Should -Match "profile''s"
    }

    It 'reports runner output and a nonzero exit code' {
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'alpha.ps1') -Value "'alpha'" -Encoding UTF8
        $env:PS_PROFILE_FAIL_IDEMPOTENCY = 'output'

        {
            & $script:CheckIdempotencyScript `
                -ProfilePath $script:FixtureRoot `
                -PowerShellExecutable 'Invoke-IdempotencyFixture'
        } | Should -Throw '*failed (exit code 6)*'
    }

    It 'handles a failed runner that produces no output' {
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'alpha.ps1') -Value "'alpha'" -Encoding UTF8
        $env:PS_PROFILE_FAIL_IDEMPOTENCY = 'empty'

        {
            & $script:CheckIdempotencyScript `
                -ProfilePath $script:FixtureRoot `
                -PowerShellExecutable 'Invoke-IdempotencyFixture'
        } | Should -Throw '*failed (exit code 5)*'
    }

    It 'rejects an empty fragment directory' {
        {
            & $script:CheckIdempotencyScript `
                -ProfilePath $script:FixtureRoot `
                -PowerShellExecutable 'Invoke-IdempotencyFixture'
        } | Should -Throw '*No fragments found*'
    }

    It 'rejects a missing fragment directory' {
        $missingPath = Join-Path $script:FixtureRoot 'missing'

        {
            & $script:CheckIdempotencyScript `
                -ProfilePath $missingPath `
                -PowerShellExecutable 'Invoke-IdempotencyFixture'
        } | Should -Throw '*Profile fragment directory not found*'
    }
}
