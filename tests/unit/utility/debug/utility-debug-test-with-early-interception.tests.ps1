<#
tests/unit/utility-debug-test-with-early-interception.tests.ps1

.SYNOPSIS
    Behavioral smoke test for test-with-early-interception.ps1.
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
    $script:TestWithEarlyInterceptionScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'test-with-early-interception.ps1'
    $ConfirmPreference = 'None'
}

Describe 'test-with-early-interception.ps1 execution' {
    It 'Runs test-support tests with early interception tracing enabled' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'early interception smoke test is too slow for CI'
            return
        }

        Push-Location $script:TestRepoRoot
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:TestWithEarlyInterceptionScript

            $result.Output | Should -Match 'Testing with early Test-Path interception'
            $result.Output | Should -Match '=== Test Results ==='
            $result.ExitCode | Should -BeIn @(0, 1)
        }
        finally {
            Pop-Location
        }
    }
}
