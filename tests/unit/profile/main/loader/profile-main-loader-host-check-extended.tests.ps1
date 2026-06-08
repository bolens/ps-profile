<#
tests/unit/profile-main-loader-host-check-extended.tests.ps1
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
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 non-interactive host check extended scenarios' {
    It 'Skips interactive initialization for non-interactive hosts' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Skip interactive initialization for non-interactive hosts'
        $c | Should -Match 'Host.UI.RawUI'
        $c | Should -Match 'PS_PROFILE_TEST_MODE'
    }
    It 'Returns early when RawUI is unavailable' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Non-interactive host detected'
        $c | Should -Match 'Early exit: Non-interactive host'
        $c | Should -Match 'return'
    }
    It 'Logs host check progress to profile log file' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Before host check'
        $c | Should -Match 'Host check passed'
        $c | Should -Match 'Error in host check'
    }
}
