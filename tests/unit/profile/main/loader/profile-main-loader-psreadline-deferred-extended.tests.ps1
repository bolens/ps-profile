# ===============================================
# profile-main-loader-psreadline-deferred-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 deferred PSReadLine loading
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
    $script:PSReadLineFragment = Join-Path $script:TestRepoRoot 'profile.d/psreadline.ps1'

    # Capture read-only observations from one eager startup in a fresh child process.
    $escapedProfile = $script:ProfileScript.Replace("'", "''")
    $script:StartupObservations = Invoke-TestPwshScript -ScriptContent @"
`$log = Join-Path ([System.IO.Path]::GetTempPath()) 'powershell-profile-load.log'
. '$escapedProfile'
if (-not (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue)) { 'PSREADLINE_DEFERRED_OK' }
if (Select-String -Path `$log -Pattern 'Initialize-FragmentLoading completed' -Quiet) { 'PSREADLINE_DEFERRED_LOAD_OK' }
"@
}

Describe 'Microsoft.PowerShell_profile.ps1 deferred PSReadLine loading extended scenarios' {
    It 'psreadline fragment exists for deferred PSReadLine configuration' {
        Test-Path -LiteralPath $script:PSReadLineFragment | Should -Be $true
    }

    It 'Does not eagerly import PSReadLine during main profile startup' {
        $result = $script:StartupObservations

        $result | Should -Match 'PSREADLINE_DEFERRED_OK'
    }

    It 'Profile load completes before optional PSReadLine enablement' {
        $result = $script:StartupObservations

        $result | Should -Match 'PSREADLINE_DEFERRED_LOAD_OK'
    }
}
