# ===============================================
# profile-main-loader-scoop-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 Scoop integration
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
    $script:ProfileScoopModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileScoop.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 Scoop integration extended scenarios' {
    It 'ProfileScoop module exists at the expected repository path' {
        Test-Path -LiteralPath $script:ProfileScoopModule | Should -Be $true
    }

    It 'Initialize-ProfileScoop is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Initialize-ProfileScoop -ErrorAction SilentlyContinue) { 'SCOOP_CMD_OK' }
"@

        $result | Should -Match 'SCOOP_CMD_OK'
    }

    It 'Profile load completes after Scoop bootstrap section runs' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Before fragment loading section' -Quiet) { 'SCOOP_LOAD_OK' }
"@

        $result | Should -Match 'SCOOP_LOAD_OK'
    }
}
