# ===============================================
# profile-main-loader-noprofile-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 NoProfile detection
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
}

Describe 'Microsoft.PowerShell_profile.ps1 NoProfile detection extended scenarios' {
    It 'Continues profile load in test mode when PSCommandPath would otherwise exit early' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) { 'NOPROFILE_BYPASS_OK' }
"@

        $result | Should -Match 'NOPROFILE_BYPASS_OK'
    }

    It 'Logs PSCommandPath check progress to the profile load log' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'PSCommandPath check passed' -Quiet) { 'NOPROFILE_LOG_OK' }
"@

        $result | Should -Match 'NOPROFILE_LOG_OK'
    }

    It 'Records profile execution start before NoProfile detection' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Profile execution started' -Quiet) { 'START_LOG_OK' }
"@

        $result | Should -Match 'START_LOG_OK'
    }
}
