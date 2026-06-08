<#
tests/unit/utility-run-test-verification.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-test-verification.ps1 Phase6 documentation flow.
#>

function global:Invoke-RunTestVerificationScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:RunTestVerificationScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunTestVerificationScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'test-verification' 'run-test-verification.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-test-verification.ps1 execution' {
    It 'Runs Phase6 documentation without enum load errors' {
        $result = Invoke-RunTestVerificationScript -ArgumentList @('-Phase', 'Phase6', '-GenerateReport')

        $result.Output | Should -Not -Match 'Unable to find type \[TestPhase\]'
        $result.Output | Should -Match 'Phase 6'
        $result.ExitCode | Should -Be 0
    }
}
