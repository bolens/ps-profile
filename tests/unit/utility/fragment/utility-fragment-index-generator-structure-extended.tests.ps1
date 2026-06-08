<#
tests/unit/utility-fragment-index-generator-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/FragmentIndexGenerator.psm1'
}
Describe 'scripts/utils/docs/modules/FragmentIndexGenerator.psm1 structure extended scenarios' {
    It 'Documents fragment documentation index generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Fragment documentation index generation utilities'
        $c | Should -Match 'FragmentIndexGenerator.psm1'
    }
    It 'Defines Write-FragmentIndex helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-FragmentIndex'
        $c | Should -Match 'FragmentsPath'
        $c | Should -Match 'ProfilePath'
    }
    It 'Exports fragment index generator' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function Write-FragmentIndex'
        $c | Should -Match 'fragment README'
    }
}
