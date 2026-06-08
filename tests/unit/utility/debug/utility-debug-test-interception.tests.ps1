<#
tests/unit/utility-debug-test-interception.tests.ps1

.SYNOPSIS
    Behavioral smoke test for test-interception.ps1.
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
    $script:TestInterceptionScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'test-interception.ps1'
    $ConfirmPreference = 'None'
}

Describe 'test-interception.ps1 execution' {
    It 'Runs test-support tests with interception loaded' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'interception smoke test is too slow for CI'
            return
        }

        Push-Location $script:TestRepoRoot
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:TestInterceptionScript

            $result.Output | Should -Match 'Running tests with interception|Test-Path interception enabled'
            $result.Output | Should -Match '=== Test Results ==='
            $result.ExitCode | Should -BeIn @(0, 1)
        }
        finally {
            Pop-Location
        }
    }
}
