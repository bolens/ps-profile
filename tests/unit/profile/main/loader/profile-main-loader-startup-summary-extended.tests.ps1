# ===============================================
# profile-main-loader-startup-summary-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 startup summary display
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

Describe 'Microsoft.PowerShell_profile.ps1 startup summary extended scenarios' {
    It 'Show-BatchLoadingSummary is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Show-BatchLoadingSummary -ErrorAction SilentlyContinue) { 'BATCH_SUMMARY_CMD_OK' }
"@

        $result | Should -Match 'BATCH_SUMMARY_CMD_OK'
    }

    It 'Show-MissingToolWarningsTable is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Show-MissingToolWarningsTable -ErrorAction SilentlyContinue) { 'MISSING_TOOLS_CMD_OK' }
"@

        $result | Should -Match 'MISSING_TOOLS_CMD_OK'
    }

    It 'Profile load reaches fragment initialization before summary display' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (Select-String -Path `$log -Pattern 'Initialize-FragmentLoading completed' -Quiet) { 'STARTUP_SUMMARY_LOAD_OK' }
"@

        $result | Should -Match 'STARTUP_SUMMARY_LOAD_OK'
    }
}
