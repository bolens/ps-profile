# ===============================================
# profile-main-loader-discovery-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 fragment discovery
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
    $script:DiscoveryModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileFragmentDiscovery.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 fragment discovery extended scenarios' {
    It 'ProfileFragmentDiscovery module exists at the expected repository path' {
        Test-Path -LiteralPath $script:DiscoveryModule | Should -Be $true
    }

    It 'Profile load reaches fragment loading via Initialize-FragmentLoading' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Initialize-FragmentLoading completed' -Quiet) { 'DISCOVERY_LOAD_OK' }
"@

        $result | Should -Match 'DISCOVERY_LOAD_OK'
    }

    It 'Loads profile fragments from profile.d after discovery completes' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) { 'FRAGMENTS_READY_OK' }
"@

        $result | Should -Match 'FRAGMENTS_READY_OK'
    }
}
