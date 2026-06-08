<#
tests/unit/utility-validate-fragment-dependencies.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-fragment-dependencies.ps1 smoke execution.
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
    $script:ValidateDepsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'validate-fragment-dependencies.ps1'
    $ConfirmPreference = 'None'
}

Describe 'validate-fragment-dependencies.ps1 execution' {
    It 'Validates fragment dependencies against the repository profile.d directory' {
        $result = Invoke-TestScriptFile -ScriptPath $script:ValidateDepsScript

        $result.ExitCode | Should -BeIn @(0, 1)
        $result.Output | Should -Match 'Validating dependencies|fragment'
    }
}
