# ===============================================
# profile-main-loader-fragment-config-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 fragment configuration
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
    $script:ProfileFragmentConfigModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileFragmentConfig.psm1'
    $script:FragmentErrorHandlingModule = Join-Path $script:TestRepoRoot 'scripts/lib/fragment/FragmentErrorHandling.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 fragment configuration extended scenarios' {
    It 'Profile and fragment configuration modules exist at expected paths' {
        Test-Path -LiteralPath $script:ProfileFragmentConfigModule | Should -Be $true
        Test-Path -LiteralPath $script:FragmentErrorHandlingModule | Should -Be $true
    }

    It 'Initialize-FragmentConfiguration is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Initialize-FragmentConfiguration -ErrorAction SilentlyContinue) { 'FRAGMENT_CONFIG_CMD_OK' }
"@

        $result | Should -Match 'FRAGMENT_CONFIG_CMD_OK'
    }

    It 'Profile load reaches fragment loader initialization after configuration' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Calling Initialize-FragmentLoading' -Quiet) { 'FRAGMENT_CONFIG_LOAD_OK' }
"@

        $result | Should -Match 'FRAGMENT_CONFIG_LOAD_OK'
    }
}
