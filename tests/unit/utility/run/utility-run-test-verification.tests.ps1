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

    It 'Fails parameter validation for an unknown verification phase' {
        $result = Invoke-RunTestVerificationScript -ArgumentList @('-Phase', 'Phase99')

        $result.Output | Should -Match 'Phase99|ValidateSet|parameter'
        $result.ExitCode | Should -Not -Be 0
    }

    It 'Fails parameter validation for an unknown verification suite' {
        $result = Invoke-RunTestVerificationScript -ArgumentList @('-Suite', 'Bogus')

        $result.Output | Should -Match 'Bogus|ValidateSet|parameter'
        $result.ExitCode | Should -Not -Be 0
    }
}
