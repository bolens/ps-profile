<#
tests/unit/utility-check-missing-packages.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-missing-packages.ps1 orchestration smoke test.
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
    $script:CheckMissingPackagesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'dependencies' 'check-missing-packages.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-missing-packages.ps1 execution' {
    It 'Runs package checks against the repository manifests without interactive prompts' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckMissingPackagesScript

        $result.Output | Should -Match 'npm|python|package|Checking'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }
}
