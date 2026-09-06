# ===============================================
# profile-main-loader-startup-logging-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 startup logging
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
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Profile execution started' -Quiet) { 'STARTUP_LOG_OK' }
if (Select-String -Path `$log -Pattern 'Before .env load' -Quiet) { 'ENV_LOAD_LOG_OK' }
"@
}

Describe 'Microsoft.PowerShell_profile.ps1 startup logging extended scenarios' {
    It 'Writes profile execution started to the load log on startup' {
        $result = $script:StartupObservations

        $result | Should -Match 'STARTUP_LOG_OK'
    }

    It 'Logs profile startup metadata when debug is enabled' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG = '1'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Profile startup' -Quiet) { 'STARTUP_META_LOG_OK' }
"@

        $result | Should -Match 'STARTUP_META_LOG_OK'
    }

    It 'Logs environment file loading before debug checks' {
        $result = $script:StartupObservations

        $result | Should -Match 'ENV_LOAD_LOG_OK'
    }
}
