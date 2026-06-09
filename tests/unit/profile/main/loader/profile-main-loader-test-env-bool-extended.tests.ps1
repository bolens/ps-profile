# ===============================================
# profile-main-loader-test-env-bool-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 Test-EnvBool behavior
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

Describe 'Microsoft.PowerShell_profile.ps1 Test-EnvBool fallback extended scenarios' {
    It 'Test-EnvBool is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Test-EnvBool -ErrorAction SilentlyContinue) { 'ENVBOOL_CMD_OK' }
"@

        $result | Should -Match 'ENVBOOL_CMD_OK'
    }

    It 'Test-EnvBool treats true-like values as enabled' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if ((Test-EnvBool -Value 'true') -and (Test-EnvBool -Value '1')) { 'ENVBOOL_TRUE_OK' }
"@

        $result | Should -Match 'ENVBOOL_TRUE_OK'
    }

    It 'Test-EnvBool treats empty and false-like values as disabled' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if ((-not (Test-EnvBool -Value '')) -and (-not (Test-EnvBool -Value '0')) -and (-not (Test-EnvBool -Value 'false'))) { 'ENVBOOL_FALSE_OK' }
"@

        $result | Should -Match 'ENVBOOL_FALSE_OK'
    }
}
