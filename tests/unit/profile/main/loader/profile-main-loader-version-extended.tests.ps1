# ===============================================
# profile-main-loader-version-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 version initialization
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
    $script:VersionModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileVersion.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 profile version extended scenarios' {
    It 'ProfileVersion module exists at the expected repository path' {
        Test-Path -LiteralPath $script:VersionModule | Should -Be $true
    }

    It 'Initialize-ProfileVersion is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Initialize-ProfileVersion -ErrorAction SilentlyContinue) { 'VERSION_CMD_OK' }
"@

        $result | Should -Match 'VERSION_CMD_OK'
    }

    It 'Profile load logs ProfileVersion initialization progress' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Loading ProfileVersion module' -Quiet) { 'VERSION_LOG_OK' }
"@

        $result | Should -Match 'VERSION_LOG_OK'
    }
}
