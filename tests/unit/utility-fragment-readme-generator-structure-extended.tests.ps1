<#
tests/unit/utility-fragment-readme-generator-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/FragmentReadmeGenerator.psm1'
}
Describe 'scripts/utils/docs/modules/FragmentReadmeGenerator.psm1 structure extended scenarios' {
    It 'Documents fragment README markdown generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Fragment README markdown generation utilities'
        $c | Should -Match 'FragmentReadmeGenerator.psm1'
    }
    It 'Defines New-FragmentReadmeContent builder' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-FragmentReadmeContent'
        $c | Should -Match 'EnableHelpers'
        $c | Should -Match 'Purpose'
    }
    It 'Exports fragment readme generator' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function New-FragmentReadmeContent'
        $c | Should -Match 'dependencies'
    }
}
