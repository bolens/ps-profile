<#
tests/unit/profile-julia-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/julia.ps1'
}
Describe 'profile.d/julia.ps1 extended scenarios' {
    It 'Declares standard tier guarded by julia availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand julia'
    }
    It 'Defines Update-JuliaPackages using Pkg.update via julia -e' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Update-JuliaPackages'
        $c | Should -Match 'Pkg.update'
    }
    It 'Registers julia-update and julia-add aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'julia-update'"
        $c | Should -Match "Set-AgentModeAlias -Name 'julia-add'"
    }
}
