<#
tests/unit/utility-verify-cache-load.tests.ps1

.SYNOPSIS
    Behavioral smoke test for verify-cache-load.ps1.
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
    $script:VerifyCacheLoadScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'verify-cache-load.ps1'
    $ConfirmPreference = 'None'
}

Describe 'verify-cache-load.ps1 execution' {
    It 'Loads the profile and reports fragment cache status' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'profile cache verification is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:VerifyCacheLoadScript

        $result.Output | Should -Match 'Fragment Cache Verification'
        $result.Output | Should -Match 'Profile loaded in|Profile load failed'
        if ($result.Output -match 'Profile loaded in') {
            $result.Output | Should -Match 'Cache Status'
        }
        else {
            $result.ExitCode | Should -Not -Be 0
        }
    }
}
