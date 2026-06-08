<#
tests/unit/profile-main-loader-fallback-loading-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 fallback fragment loading extended scenarios' {
    It 'Uses ProfileFragmentLoader when available' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'ProfileFragmentLoader.psm1'
        $c | Should -Match 'Initialize-FragmentLoading'
        $c | Should -Match 'Fragment loader module imported'
    }
    It 'Sets fragment context during dot-sourcing' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'CurrentFragmentContext'
        $c | Should -Match 'ProfileFragmentRoot'
        $c | Should -Match 'fragmentBaseName'
    }
    It 'Provides sequential fallback loading with batch debug output' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Fallback: use simple sequential loading'
        $c | Should -Match 'fallbackBatchSize'
        $c | Should -Match 'Loaded .* fragments successfully'
    }
}
