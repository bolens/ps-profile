<#
tests/unit/utility-doc-cleanup-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocCleanup.psm1'
}
Describe 'scripts/utils/docs/modules/DocCleanup.psm1 structure extended scenarios' {
    It 'Documents documentation cleanup utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Documentation cleanup utilities'
        $c | Should -Match 'DocCleanup.psm1'
    }
    It 'Defines Remove-StaleDocumentation helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Remove-StaleDocumentation'
        $c | Should -Match 'DocumentedCommandNames'
        $c | Should -Match 'stale documentation'
    }
    It 'Exports cleanup function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function Remove-StaleDocumentation'
        $c | Should -Match 'DocsPath'
    }
}
