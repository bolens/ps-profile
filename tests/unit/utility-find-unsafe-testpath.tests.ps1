<#
tests/unit/utility-find-unsafe-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for find-unsafe-testpath.ps1 repository scan smoke execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:FindUnsafeTestPathScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'find-unsafe-testpath.ps1'
    $ConfirmPreference = 'None'
}

Describe 'find-unsafe-testpath.ps1 execution' {
    It 'Scans repository paths and reports heuristic Test-Path findings' {
        $result = Invoke-TestScriptFile -ScriptPath $script:FindUnsafeTestPathScript

        $result.ExitCode | Should -BeIn @(0, $null)
        $result.Output | Should -Match 'unsafe Test-Path|No obviously unsafe Test-Path'
    }
}
