<#
tests/unit/utility-debug-run-tests-with-interception.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-tests-with-interception.ps1.
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
    $script:RunTestsWithInterceptionScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'run-tests-with-interception.ps1'
    $script:MinimalTestFile = Join-Path $script:TestRepoRoot 'tests' 'unit' 'utility-parameters.tests.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-tests-with-interception.ps1 execution' {
    It 'Runs a unit test file with Test-Path interception enabled' {
        if (-not (Test-Path -LiteralPath $script:MinimalTestFile)) {
            Set-ItResult -Skipped -Because 'minimal unit test file is not available'
            return
        }

        Push-Location $script:TestRepoRoot
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:RunTestsWithInterceptionScript -ArgumentList @(
                '-TestFile', $script:MinimalTestFile
            )

            $result.Output | Should -Match 'Running tests with Test-Path interception'
            $result.Output | Should -Match 'Test-Path interception enabled|=== Test Results ==='
            $result.ExitCode | Should -BeIn @(0, 1)
        }
        finally {
            Pop-Location
        }
    }
}
