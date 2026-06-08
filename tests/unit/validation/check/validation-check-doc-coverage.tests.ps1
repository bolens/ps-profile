<#
tests/unit/validation-check-doc-coverage.tests.ps1

.SYNOPSIS
    Behavioral smoke tests for check-doc-coverage.ps1.
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
    $script:CheckDocCoverageScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-doc-coverage.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-doc-coverage.ps1 execution' {
    It 'Emits a JSON coverage report without strict validation failures' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'documentation coverage scan is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript -ArgumentList @('-Json')

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DocumentedFunctionCount|documentation coverage report emitted as JSON'
    }

    It 'Completes in summary mode without requiring -Strict' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'documentation coverage scan is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocCoverageScript

        $result.Output | Should -Match 'Documentation coverage summary|Documented functions'
        $result.ExitCode | Should -BeIn @(0, 1)
    }
}
