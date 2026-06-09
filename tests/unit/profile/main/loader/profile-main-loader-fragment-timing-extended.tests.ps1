# ===============================================
# profile-main-loader-fragment-timing-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 fragment timing bootstrap
# ===============================================

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
    $script:ProfileFragmentTimingModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileFragmentTiming.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 fragment timing extended scenarios' {
    It 'ProfileFragmentTiming module exists at the expected repository path' {
        Test-Path -LiteralPath $script:ProfileFragmentTimingModule | Should -Be $true
    }

    It 'Initialize-FragmentTiming is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Initialize-FragmentTiming -ErrorAction SilentlyContinue) { 'FRAGMENT_TIMING_CMD_OK' }
"@

        $result | Should -Match 'FRAGMENT_TIMING_CMD_OK'
    }

    It 'Initializes fragment timing tracking when debug mode is enabled' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '2'
. '$escapedProfile'
if (Get-Variable -Name PSProfileFragmentTimes -Scope Global -ErrorAction SilentlyContinue) { 'FRAGMENT_TIMING_INIT_OK' }
"@

        $result | Should -Match 'FRAGMENT_TIMING_INIT_OK'
    }
}
