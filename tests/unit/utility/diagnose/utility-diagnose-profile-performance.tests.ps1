<#
tests/unit/utility-diagnose-profile-performance.tests.ps1

.SYNOPSIS
    Behavioral unit tests for diagnose-profile-performance.ps1 smoke execution.
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
    $script:DiagnoseProfilePerfScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'performance' 'diagnose-profile-performance.ps1'
    $ConfirmPreference = 'None'
}

Describe 'diagnose-profile-performance.ps1 execution' {
    It 'Runs profile performance diagnostics and prints recommendations' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'profile load diagnostics are too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:DiagnoseProfilePerfScript

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Profile Performance Diagnostics|Optimization Recommendations'
    }
}
