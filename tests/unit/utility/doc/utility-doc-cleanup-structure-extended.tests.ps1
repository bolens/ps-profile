<#
tests/unit/utility-doc-cleanup-structure-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
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
