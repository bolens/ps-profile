# ===============================================
# profile-main-loader-fallback-loading-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 fallback fragment loading
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
    $script:FragmentLoaderModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfileFragmentLoader.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 fallback fragment loading extended scenarios' {
    It 'ProfileFragmentLoader module exists at the expected repository path' {
        Test-Path -LiteralPath $script:FragmentLoaderModule | Should -Be $true
    }

    It 'Profile load logs fragment loader initialization progress' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Before fragment loading section' -Quiet) { 'FALLBACK_SECTION_LOG_OK' }
"@

        $result | Should -Match 'FALLBACK_SECTION_LOG_OK'
    }

    It 'Completes fragment loading and exposes bootstrap commands afterward' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if ((Select-String -Path `$log -Pattern 'Initialize-FragmentLoading completed' -Quiet) -and (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue)) { 'FALLBACK_COMPLETE_OK' }
"@

        $result | Should -Match 'FALLBACK_COMPLETE_OK'
    }
}
