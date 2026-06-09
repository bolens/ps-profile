# ===============================================
# profile-main-loader-fragments-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 fragment loading
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
    $script:FragmentConfigModule = Join-Path $script:TestRepoRoot 'scripts/lib/fragment/FragmentConfig.psm1'
    $script:FragmentLoadingModule = Join-Path $script:TestRepoRoot 'scripts/lib/fragment/FragmentLoading.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 fragment loading extended scenarios' {
    It 'Fragment configuration and loading modules exist at expected paths' {
        Test-Path -LiteralPath $script:FragmentConfigModule | Should -Be $true
        Test-Path -LiteralPath $script:FragmentLoadingModule | Should -Be $true
    }

    It 'Profile load imports the fragment loader module successfully' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Fragment loader module imported successfully' -Quiet) { 'LOADER_IMPORT_OK' }
"@

        $result | Should -Match 'LOADER_IMPORT_OK'
    }

    It 'Registers bootstrap helpers after modular fragments are loaded' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) { 'BOOTSTRAP_FRAGMENT_OK' }
"@

        $result | Should -Match 'BOOTSTRAP_FRAGMENT_OK'
    }
}
