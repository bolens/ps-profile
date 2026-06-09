# ===============================================
# profile-main-loader-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 core loader behavior
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

Describe 'Microsoft.PowerShell_profile.ps1 extended scenarios' {
    It 'Loads profile.d when executed with PS_PROFILE_REPO_ROOT' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Test-Path (Join-Path `$env:PS_PROFILE_REPO_ROOT 'profile.d')) { 'PROFILE_DIR_OK' }
"@

        $result | Should -Match 'PROFILE_DIR_OK'
    }

    It 'Writes profile execution started to the load log' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Profile execution started' -Quiet) { 'LOG_OK' }
"@

        $result | Should -Match 'LOG_OK'
    }

    It 'Loads bootstrap helpers from profile.d after profile execution' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) { 'BOOTSTRAP_OK' }
"@

        $result | Should -Match 'BOOTSTRAP_OK'
    }
}
