<#
tests/unit/utility-doc-index-generator-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocIndexGenerator.psm1'
}
Describe 'scripts/utils/docs/modules/DocIndexGenerator.psm1 structure extended scenarios' {
    It 'Documents documentation index generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Documentation index generation utilities'
        $c | Should -Match 'DocIndexGenerator.psm1'
    }
    It 'Defines Write-DocumentationIndex for README index' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-DocumentationIndex'
        $c | Should -Match 'groups functions and aliases'
        $c | Should -Match 'DocsPath'
    }
    It 'Exports index generation function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function Write-DocumentationIndex'
        $c | Should -Match 'Aliases'
    }
}
