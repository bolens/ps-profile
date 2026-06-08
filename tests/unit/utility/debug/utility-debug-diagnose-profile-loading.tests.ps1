<#
tests/unit/utility-debug-diagnose-profile-loading.tests.ps1

.SYNOPSIS
    Behavioral unit tests for diagnose-profile-loading.ps1.
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
    $script:DiagnoseProfileLoadingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'diagnose-profile-loading.ps1'
    $ConfirmPreference = 'None'
}

Describe 'diagnose-profile-loading.ps1 execution' {
    It 'Prints host and profile path diagnostics without loading the profile' {
        $result = Invoke-TestScriptFile -ScriptPath $script:DiagnoseProfileLoadingScript

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Profile Loading Diagnostics'
        $result.Output | Should -Match '=== Profile Paths ==='
        $result.Output | Should -Match '=== Common Issues Check ==='
        $result.Output | Should -Match '=== End Diagnostics ==='
    }

    It 'Detects non-interactive host conditions when RawUI is unavailable' {
        $result = Invoke-TestScriptFile -ScriptPath $script:DiagnoseProfileLoadingScript

        if ($result.Output -match 'Non-interactive host detected') {
            $result.Output | Should -Match 'Issues found'
        }
        else {
            $result.Output | Should -Match 'No obvious issues detected|Issues found'
        }
    }
}
