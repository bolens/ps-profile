<#
tests/unit/test-runner-output-path-utils-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/OutputPathUtils.psm1'
}
Describe 'scripts/utils/code-quality/modules/OutputPathUtils.psm1 structure extended scenarios' {
    It 'Documents output path conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Output path conversion utilities'
        $c | Should -Match 'OutputPathUtils.psm1'
    }
    It 'Defines Initialize-OutputUtils and path conversion' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-OutputUtils'
        $c | Should -Match 'ConvertTo-RepoRelativePath'
        $c | Should -Match 'RepoRootPattern'
    }
    It 'Exports output path helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-RepoRootPattern'
        $c | Should -Match 'Export-ModuleMember'
    }
}
