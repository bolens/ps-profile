<#
tests/unit/utility-doc-generator-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/docs/modules/DocGenerator.psm1'
}
Describe 'scripts/utils/docs/modules/DocGenerator.psm1 structure extended scenarios' {
    It 'Documents markdown documentation generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Markdown documentation generation utilities'
        $c | Should -Match 'DocGenerator.psm1'
    }
    It 'Defines function and alias documentation writers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-FunctionDocumentation'
        $c | Should -Match 'Write-AliasDocumentation'
        $c | Should -Match 'Get-RelativePath'
    }
    It 'Provides documentation debug helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-DocsDebugEnabled'
        $c | Should -Match 'Write-DocsDebugMessage'
        $c | Should -Match 'Export-ModuleMember'
    }
}
