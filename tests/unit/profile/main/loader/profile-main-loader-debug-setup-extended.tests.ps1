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

    # Capture read-only observations from one eager startup in a fresh child process.
    $escapedProfile = $script:ProfileScript.Replace("'", "''")
    $script:StartupObservations = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '1'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
Remove-Item -LiteralPath `$log -Force -ErrorAction SilentlyContinue
. '$escapedProfile'
if (Select-String -Path `$log -Pattern "Debug check: PS_PROFILE_DEBUG='1'" -Quiet) { 'DEBUG_CHECK_LOG_OK' }
if (`$VerbosePreference -eq 'Continue') { 'VERBOSE_PREF_OK' }
"@
}

Describe 'Microsoft.PowerShell_profile.ps1 debug setup extended scenarios' {
    It 'Parses PS_PROFILE_DEBUG and records debug check in the load log' {
        $result = $script:StartupObservations

        $result | Should -Match 'DEBUG_CHECK_LOG_OK'
    }

    It 'Logs parsed debug level when PS_PROFILE_DEBUG is numeric' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '2'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
Remove-Item -LiteralPath `$log -Force -ErrorAction SilentlyContinue
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Debug parsed: level=2' -Quiet) { 'DEBUG_LEVEL_LOG_OK' }
"@

        $result | Should -Match 'DEBUG_LEVEL_LOG_OK'
    }

    It 'Enables verbose preference when debug level is at least 1' {
        $result = $script:StartupObservations

        $result | Should -Match 'VERBOSE_PREF_OK'
    }
}
