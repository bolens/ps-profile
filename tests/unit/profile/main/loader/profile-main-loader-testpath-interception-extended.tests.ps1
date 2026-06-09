# ===============================================
# profile-main-loader-testpath-interception-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 Test-Path interception
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
    $script:InterceptScript = Join-Path $script:TestRepoRoot 'scripts/utils/debug/intercept-testpath.ps1'
}

Describe 'Microsoft.PowerShell_profile.ps1 Test-Path interception extended scenarios' {
    It 'Records the expected intercept script path in the load log when enabled' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $escapedIntercept = $script:InterceptScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG_TESTPATH = '1'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Intercept script path: $escapedIntercept' -Quiet) { 'INTERCEPT_PATH_LOG_OK' }
"@

        $result | Should -Match 'INTERCEPT_PATH_LOG_OK'
    }

    It 'Logs Test-Path interception as enabled when debug flag is set' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$env:PS_PROFILE_DEBUG_TESTPATH = '1'
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Test-Path interception enabled' -Quiet) { 'INTERCEPT_ENABLED_LOG_OK' }
"@

        $result | Should -Match 'INTERCEPT_ENABLED_LOG_OK'
    }

    It 'Skips interception when debug flags are not set' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
Remove-Item Env:\PS_PROFILE_DEBUG_TESTPATH -ErrorAction SilentlyContinue
Remove-Item Env:\PS_PROFILE_DEBUG_TESTPATH_TRACE -ErrorAction SilentlyContinue
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Test-Path interception not enabled' -Quiet) { 'INTERCEPT_DISABLED_LOG_OK' }
"@

        $result | Should -Match 'INTERCEPT_DISABLED_LOG_OK'
    }
}
