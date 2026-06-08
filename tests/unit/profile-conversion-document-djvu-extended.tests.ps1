<#
tests/unit/profile-conversion-document-djvu-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-djvu.ps1'
}
Describe 'profile.d/conversion-modules/document/document-djvu.ps1 extended scenarios' {
    It 'Documents DjVu document conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'DjVu document format conversion utilities'
        $c | Should -Match 'djvulibre'
    }
    It 'Defines Initialize-FileConversion-DocumentDjvu with ImageMagick and ddjvu fallbacks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentDjvu'
        $c | Should -Match "Test-CachedCommand 'magick'"
        $c | Should -Match "Test-CachedCommand 'ddjvu'"
    }
    It 'Registers djvu-to-pdf and djvu-to-text aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'djvu-to-pdf'"
        $c | Should -Match "Set-AgentModeAlias -Name 'djvu-to-text'"
    }
}
