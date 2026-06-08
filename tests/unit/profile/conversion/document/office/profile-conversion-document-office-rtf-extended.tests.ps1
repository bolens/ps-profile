<#
tests/unit/profile-conversion-document-office-rtf-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-rtf.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-rtf.ps1 extended scenarios' {
    It 'Documents RTF document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'RTF \(Rich Text Format\) conversion utilities'
        $c | Should -Match 'Requires pandoc for conversions'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeRtf with rtf conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeRtf'
        $c | Should -Match '_ConvertFrom-RtfToMarkdown'
        $c | Should -Match 'Ensure-FileConversion-Documents'
    }
    It 'Registers rtf-to-markdown and rtf-to-html aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'rtf-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'rtf-to-html'"
    }
}
