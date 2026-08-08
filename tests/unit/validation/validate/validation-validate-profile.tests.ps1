<#
tests/unit/validation/validate/validation-validate-profile.tests.ps1

.SYNOPSIS
    Behavioral tests for validate-profile.ps1 orchestration.
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
    $script:ValidateProfileScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'validate-profile.ps1'

    function global:Invoke-ValidationFixture {
        param(
            [switch]$NoProfile,
            [string]$File
        )

        $checkName = switch -Regex ($File) {
            'run-security-scan' { 'security' }
            'run-lint' { 'lint' }
            'spellcheck' { 'spellcheck' }
            'run-markdownlint' { 'markdownlint' }
            'check-comment-help' { 'comment-help' }
            'check-idempotency' { 'idempotency' }
            'find-duplicate-functions' { 'duplicates' }
        }
        Write-Output "$checkName fixture invoked"
        $global:LASTEXITCODE = if ($env:PS_PROFILE_FAIL_CHECK -eq $checkName) { 4 } else { 0 }
    }
}

Describe 'validate-profile.ps1 execution' {
    BeforeEach {
        $script:FixtureRoot = New-TestTempDirectory -Prefix 'ValidateProfile'
        $script:PreviousFailCheck = $env:PS_PROFILE_FAIL_CHECK
        $script:PreviousRequireMarkdownlint = $env:PS_PROFILE_REQUIRE_MARKDOWNLINT
        Remove-Item Env:PS_PROFILE_FAIL_CHECK -ErrorAction SilentlyContinue
        $env:PS_PROFILE_REQUIRE_MARKDOWNLINT = '1'
    }

    AfterEach {
        if ($null -eq $script:PreviousFailCheck) {
            Remove-Item Env:PS_PROFILE_FAIL_CHECK -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_FAIL_CHECK = $script:PreviousFailCheck
        }

        if ($null -eq $script:PreviousRequireMarkdownlint) {
            Remove-Item Env:PS_PROFILE_REQUIRE_MARKDOWNLINT -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_REQUIRE_MARKDOWNLINT = $script:PreviousRequireMarkdownlint
        }
    }

    It 'runs every validation check when markdownlint is required' {
        $output = & $script:ValidateProfileScript `
            -RepositoryRoot $script:FixtureRoot `
            -PowerShellExecutable 'Invoke-ValidationFixture' 2>&1 | Out-String

        $output | Should -Match 'Running markdownlint'
        $output | Should -Match 'security \+ lint \+ spellcheck \+ markdownlint'
    }

    It 'supports explicitly skipping optional markdownlint' {
        $output = & $script:ValidateProfileScript `
            -RepositoryRoot $script:FixtureRoot `
            -PowerShellExecutable 'Invoke-ValidationFixture' `
            -SkipMarkdownlint 2>&1 | Out-String

        $output | Should -Not -Match 'Running markdownlint'
        $output | Should -Match 'security \+ lint \+ spellcheck \+ comment help'
    }

    It 'uses detected repository and PowerShell defaults' {
        $global:ValidateProfileFixtureRoot = $script:FixtureRoot
        try {
            Mock Get-RepoRoot { $global:ValidateProfileFixtureRoot }
            Mock Get-PowerShellExecutable { 'Invoke-ValidationFixture' }

            $output = & $script:ValidateProfileScript 2>&1 | Out-String

            $output | Should -Match 'security \+ lint \+ spellcheck \+ markdownlint'
            Should -Invoke Get-RepoRoot -Times 1 -Exactly
            Should -Invoke Get-PowerShellExecutable -Times 1 -Exactly
        }
        finally {
            Remove-Variable -Name ValidateProfileFixtureRoot -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'stops and identifies a failed required check' {
        $env:PS_PROFILE_FAIL_CHECK = 'lint'

        {
            & $script:ValidateProfileScript `
                -RepositoryRoot $script:FixtureRoot `
                -PowerShellExecutable 'Invoke-ValidationFixture'
        } | Should -Throw '*lint failed with exit code 4*'
    }

    It 'identifies a failed optional markdownlint check when enabled' {
        $env:PS_PROFILE_FAIL_CHECK = 'markdownlint'

        {
            & $script:ValidateProfileScript `
                -RepositoryRoot $script:FixtureRoot `
                -PowerShellExecutable 'Invoke-ValidationFixture'
        } | Should -Throw '*markdownlint failed with exit code 4*'
    }
}
