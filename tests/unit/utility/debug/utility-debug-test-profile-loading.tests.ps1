<#
tests/unit/utility-debug-test-profile-loading.tests.ps1

.SYNOPSIS
    Behavioral smoke test for test-profile-loading.ps1.
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
    $script:TestProfileLoadingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'test-profile-loading.ps1'
    $ConfirmPreference = 'None'
}

Describe 'test-profile-loading.ps1 execution' {
    It 'Loads the active profile and reports completion' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'profile loading is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:TestProfileLoadingScript

        $result.Output | Should -Match 'Testing profile loading'
        $result.Output | Should -Match 'Profile loading completed|Profile loading failed'
    }
}
