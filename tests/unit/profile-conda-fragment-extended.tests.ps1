<#
tests/unit/profile-conda-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conda.ps1'
}
Describe 'profile.d/conda.ps1 extended scenarios' {
    It 'Declares standard tier guarded by conda availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand conda'
    }
    It 'Defines Update-CondaPackages wrapping conda update --all' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Update-CondaPackages'
        $c | Should -Match 'conda update --all'
    }
    It 'Provides Test-CondaOutdated and conda-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-CondaOutdated'
        $c | Should -Match "Set-AgentModeAlias -Name 'conda-update'"
    }
}
