<#
tests/unit/validation-check-doc-freshness.tests.ps1

.SYNOPSIS
    Behavioral smoke test for check-doc-freshness.ps1.
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
    $script:CheckDocFreshnessScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-doc-freshness.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-doc-freshness.ps1 execution' {
    It 'Regenerates docs incrementally and reports freshness status' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'incremental doc generation is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocFreshnessScript

        $result.Output | Should -Match 'Regenerating API docs incrementally|generate-docs'
        $result.Output | Should -Match 'API documentation is up to date|freshness check failed|out of date'
        $result.ExitCode | Should -BeIn @(0, 1)
    }
}
