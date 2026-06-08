<#
tests/unit/profile-main-loader-discovery-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 fragment discovery extended scenarios' {
    It 'Uses ProfileFragmentDiscovery for load ordering' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'ProfileFragmentDiscovery.psm1'
        $c | Should -Match 'Initialize-FragmentDiscovery'
        $c | Should -Match 'FragmentsToLoad'
    }
    It 'Supports parallel loading via environment flag' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'PS_PROFILE_PARALLEL_LOADING'
        $c | Should -Match 'Test-EnvBool'
        $c | Should -Match 'EnableParallelLoading'
    }
    It 'Falls back to alphabetical ordering when discovery fails' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Fallback: use simple alphabetical ordering'
        $c | Should -Match 'Sort-Object Name'
    }
}
