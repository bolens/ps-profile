<#
tests/unit/utility-run-markdownlint.tests.ps1

.SYNOPSIS
    Behavioral smoke test for run-markdownlint.ps1.
#>

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
    $script:RunMarkdownlintScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-markdownlint.ps1'
    $script:MarkdownlintAvailable = [bool](Get-Command markdownlint -ErrorAction SilentlyContinue)
    $script:NpxAvailable = [bool](Get-Command npx -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'run-markdownlint.ps1 execution' {
    It 'Runs markdownlint or npx fallback without interactive prompts' {
        if (-not $script:MarkdownlintAvailable -and -not $script:NpxAvailable) {
            Set-ItResult -Skipped -Because 'markdownlint and npx are not available'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:RunMarkdownlintScript

        $result.ExitCode | Should -BeIn @(0, 1, 2)
        $result.Output | Should -Match 'markdownlint'
    }

    It 'Reports the configured MARKDOWNLINT_VERSION in output' {
        if (-not $script:MarkdownlintAvailable -and -not $script:NpxAvailable) {
            Set-ItResult -Skipped -Because 'markdownlint and npx are not available'
            return
        }

        $customVersion = '0.35.0'
        $result = Invoke-TestScriptFile -ScriptPath $script:RunMarkdownlintScript -EnvironmentVariables @{
            MARKDOWNLINT_VERSION = $customVersion
        }

        $result.ExitCode | Should -BeIn @(0, 1, 2)
        $result.Output | Should -Match "version: $customVersion"
    }
}
