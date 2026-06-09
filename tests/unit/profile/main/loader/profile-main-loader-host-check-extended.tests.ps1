# ===============================================
# profile-main-loader-host-check-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 host checks
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

Describe 'Microsoft.PowerShell_profile.ps1 non-interactive host check extended scenarios' {
    It 'Bypasses non-interactive host exit when PS_PROFILE_TEST_MODE is set' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) { 'HOST_BYPASS_OK' }
"@

        $result | Should -Match 'HOST_BYPASS_OK'
    }

    It 'Logs host check progress to the profile load log' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Before host check' -Quiet) { 'HOST_LOG_BEFORE_OK' }
"@

        $result | Should -Match 'HOST_LOG_BEFORE_OK'
    }

    It 'Records host check passed in the profile load log' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Host check passed' -Quiet) { 'HOST_LOG_PASSED_OK' }
"@

        $result | Should -Match 'HOST_LOG_PASSED_OK'
    }
}
