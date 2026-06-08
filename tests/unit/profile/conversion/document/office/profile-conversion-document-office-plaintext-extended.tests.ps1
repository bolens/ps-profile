<#
tests/unit/profile-conversion-document-office-plaintext-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-plaintext.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-plaintext.ps1 extended scenarios' {
    It 'Documents plain text format conversion with encoding support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Plain Text format conversion utilities'
        $c | Should -Match 'encoding detection and conversion'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficePlaintext with text conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficePlaintext'
        $c | Should -Match '_ConvertFrom-PlainTextToMarkdown'
        $c | Should -Match 'Ensure-FileConversion-Documents'
    }
    It 'Registers txt-to-markdown and text-to-html aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'txt-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'text-to-html'"
    }
}
