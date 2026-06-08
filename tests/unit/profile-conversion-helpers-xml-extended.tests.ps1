<#
tests/unit/profile-conversion-helpers-xml-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/helpers/helpers-xml.ps1'
}
Describe 'profile.d/conversion-modules/helpers/helpers-xml.ps1 extended scenarios' {
    It 'Documents XML conversion helpers for JSON interoperability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'XML conversion helper utilities'
        $c | Should -Match 'XML ↔ JSON conversion helpers'
    }
    It 'Defines Convert-XmlToJsonObject with attribute and child handling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-XmlToJsonObject'
        $c | Should -Match 'System.Xml.XmlElement'
        $c | Should -Match '#text'
    }
    It 'Defines Convert-JsonToXml with Sanitize-XmlName helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-JsonToXml'
        $c | Should -Match 'Sanitize-XmlName'
        $c | Should -Match 'Add-ToXml'
    }
}
