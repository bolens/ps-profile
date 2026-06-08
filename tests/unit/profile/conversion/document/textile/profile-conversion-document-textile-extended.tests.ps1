<#
tests/unit/profile-conversion-document-textile-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-textile.ps1'
}
Describe 'profile.d/conversion-modules/document/document-textile.ps1 extended scenarios' {
    It 'Documents Textile document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Textile document format conversion utilities'
        $c | Should -Match 'Requires pandoc for conversions'
    }
    It 'Defines Initialize-FileConversion-DocumentTextile with textile format' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentTextile'
        $c | Should -Match '-f textile'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers textile-to-markdown and textile-to-html aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'textile-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'textile-to-html'"
    }
}
