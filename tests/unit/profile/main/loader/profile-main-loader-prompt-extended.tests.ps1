<#
tests/unit/profile-main-loader-prompt-extended.tests.ps1
#>
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
Describe 'Microsoft.PowerShell_profile.ps1 prompt initialization extended scenarios' {
    It 'Documents enhanced features prompt initialization section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'INITIALIZE ENHANCED FEATURES'
        $c | Should -Match 'ProfilePrompt.psm1'
        $c | Should -Match 'Starship'
    }
    It 'Calls Initialize-ProfilePrompt after fragments load' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Initialize-ProfilePrompt'
        $c | Should -Match 'after all fragments load'
    }
    It 'Uses structured error handling for prompt load failures' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Write-StructuredError'
        $c | Should -Match 'profile.load-prompt-module'
        $c | Should -Match 'profile.prompt'
    }
}
