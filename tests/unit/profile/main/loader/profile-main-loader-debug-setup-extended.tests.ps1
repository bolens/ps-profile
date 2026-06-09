# ===============================================
# profile-main-loader-debug-setup-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 debug setup
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

Describe 'Microsoft.PowerShell_profile.ps1 debug setup extended scenarios' {
    It 'Parses PS_PROFILE_DEBUG and records debug mode check in the load log' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '1'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Debug mode check' -Quiet) { 'DEBUG_CHECK_LOG_OK' }
"@

        $result | Should -Match 'DEBUG_CHECK_LOG_OK'
    }

    It 'Logs parsed debug level when PS_PROFILE_DEBUG is numeric' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '2'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Debug parsed: level=2' -Quiet) { 'DEBUG_LEVEL_LOG_OK' }
"@

        $result | Should -Match 'DEBUG_LEVEL_LOG_OK'
    }

    It 'Enables verbose preference when debug level is at least 1' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '1'
. '$escapedProfile'
if (`$VerbosePreference -eq 'Continue') { 'VERBOSE_PREF_OK' }
"@

        $result | Should -Match 'VERBOSE_PREF_OK'
    }
}
