<#
tests/unit/profile-history-enhanced-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/history-enhanced.ps1'
}
Describe 'profile.d/history-enhanced.ps1 extended scenarios' {
    It 'Declares optional tier with bootstrap and env dependencies' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Loads utilities-history-enhanced module from utilities-modules/history' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'utilities-modules'
        $c | Should -Match 'utilities-history-enhanced\.ps1'
    }
    It 'Uses Write-ProfileError for module load failures when debug is enabled' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-ProfileError'
        $c | Should -Match 'history-enhanced'
    }
}
