<#
tests/unit/profile-conversion-document-ebook-mobi-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-ebook-mobi.ps1'
}
Describe 'profile.d/conversion-modules/document/document-ebook-mobi.ps1 extended scenarios' {
    It 'Documents MOBI and AZW e-book conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'MOBI/AZW'
        $c | Should -Match 'Calibre \(ebook-convert\) or pandoc'
    }
    It 'Defines Initialize-FileConversion-DocumentEbookMobi with ebook-convert fallback' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentEbookMobi'
        $c | Should -Match "Test-CachedCommand 'ebook-convert'"
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers mobi-to-epub and epub-to-mobi aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'mobi-to-epub'"
        $c | Should -Match "Set-AgentModeAlias -Name 'epub-to-mobi'"
    }
}
