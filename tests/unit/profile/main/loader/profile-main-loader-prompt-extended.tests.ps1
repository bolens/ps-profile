# ===============================================
# profile-main-loader-prompt-extended.tests.ps1
# Execution tests for Microsoft.PowerShell_profile.ps1 prompt initialization
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
    $script:ProfilePromptModule = Join-Path $script:TestRepoRoot 'scripts/lib/profile/ProfilePrompt.psm1'
}

Describe 'Microsoft.PowerShell_profile.ps1 prompt initialization extended scenarios' {
    It 'ProfilePrompt module exists at the expected repository path' {
        Test-Path -LiteralPath $script:ProfilePromptModule | Should -Be $true
    }

    It 'Initialize-ProfilePrompt is available after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
if (Get-Command Initialize-ProfilePrompt -ErrorAction SilentlyContinue) { 'PROMPT_CMD_OK' }
"@

        $result | Should -Match 'PROMPT_CMD_OK'
    }

    It 'Initialize-ProfilePrompt runs without error after profile load' {
        $escapedProfile = $script:ProfileScript.Replace("'", "''")
        $result = Invoke-TestPwshScript -ScriptContent @"
. '$escapedProfile'
try {
    if (Get-Command Initialize-ProfilePrompt -ErrorAction SilentlyContinue) {
        Initialize-ProfilePrompt
        'PROMPT_INIT_OK'
    }
}
catch { }
"@

        $result | Should -Match 'PROMPT_INIT_OK'
    }
}
