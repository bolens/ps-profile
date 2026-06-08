<#
tests/unit/profile-conversion-document-office-odt-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-odt.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-odt.ps1 extended scenarios' {
    It 'Documents ODT OpenDocument text conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ODT \(OpenDocument Text\) format conversion utilities'
        $c | Should -Match 'LibreOffice and OpenOffice'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeOdt with pandoc odt conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeOdt'
        $c | Should -Match '_ConvertFrom-OdtToMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers odt-to-markdown and odt-to-pdf aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'odt-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'odt-to-pdf'"
    }
}
