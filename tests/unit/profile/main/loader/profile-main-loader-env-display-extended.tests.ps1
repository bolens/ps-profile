# ===============================================
# profile-main-loader-env-display-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 env display bootstrap
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
    $script:ProfileEnvDisplayModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileEnvDisplay.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 profile env display extended scenarios' {
    It 'ProfileEnvDisplay module exists at the expected repository path' {
        Test-Path -LiteralPath $script:ProfileEnvDisplayModule | Should -Be $true
    }

    It 'Show-ProfileEnvVariables is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Show-ProfileEnvVariables -ErrorAction SilentlyContinue) { 'ENV_DISPLAY_CMD_OK' }
"@

        $result | Should -Match 'ENV_DISPLAY_CMD_OK'
    }

    It 'Profile load completes when PS_PROFILE_DEBUG enables env display' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '1'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Profile execution started' -Quiet) { 'ENV_DISPLAY_LOAD_OK' }
"@

        $result | Should -Match 'ENV_DISPLAY_LOAD_OK'
    }
}
