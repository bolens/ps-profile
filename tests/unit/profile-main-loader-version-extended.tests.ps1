<#
tests/unit/profile-main-loader-version-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 profile version extended scenarios' {
    It 'Documents profile version information section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'PROFILE VERSION INFORMATION'
        $c | Should -Match 'ProfileVersion.psm1'
        $c | Should -Match 'git commit'
    }
    It 'Calls Initialize-ProfileVersion when module loads' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Initialize-ProfileVersion'
        $c | Should -Match 'Loading ProfileVersion module'
    }
    It 'Uses management Test-Path for version module existence' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'versionModuleExists'
        $c | Should -Match 'Management\\Test-Path'
    }
}
