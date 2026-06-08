<#
tests/unit/profile-main-loader-fragments-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 fragment loading extended scenarios' {
    It 'Loads profile fragments from profile.d in dependency order' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'LOAD MODULAR PROFILE COMPONENTS'
        $c | Should -Match 'dependency-aware order'
        $c | Should -Match 'profile.d'
    }
    It 'Uses fragment configuration and loading modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FragmentConfig.psm1'
        $c | Should -Match 'FragmentLoading.psm1'
        $c | Should -Match 'Initialize-FragmentConfiguration'
    }
    It 'Supports disabled fragments and performance configuration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DisabledFragments'
        $c | Should -Match 'maxFragmentTime'
        $c | Should -Match 'parallelDependencyParsing'
    }
}
