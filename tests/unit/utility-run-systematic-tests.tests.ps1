<#
tests/unit/utility-run-systematic-tests.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-systematic-tests.ps1 category validation.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SystematicTestsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'test-verification' 'run-systematic-tests.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-systematic-tests.ps1 execution' {
    It 'Fails fast with available category names when an unknown category is requested' {
        $result = Invoke-TestScriptFile -ScriptPath $script:SystematicTestsScript -ArgumentList @(
            '-Category', 'DefinitelyMissingCategory'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Category ''DefinitelyMissingCategory'' not found'
        $result.Output | Should -Match 'Bootstrap|Performance|Unit'
    }
}
