<#
tests/unit/profile-conversion-document-rst-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-rst.ps1'
}
Describe 'profile.d/conversion-modules/document/document-rst.ps1 extended scenarios' {
    It 'Documents reStructuredText document conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'RST \(reStructuredText\) document format conversion utilities'
        $c | Should -Match 'reStructuredText'
    }
    It 'Defines Initialize-FileConversion-DocumentRst with pandoc rst conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentRst'
        $c | Should -Match '_ConvertFrom-RstToMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers rst-to-markdown and rst-to-html aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'rst-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'rst-to-html'"
    }
}
