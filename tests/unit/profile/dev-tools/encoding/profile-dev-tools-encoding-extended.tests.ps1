<#
tests/unit/profile-dev-tools-encoding-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/encoding/encoding.ps1'
}
Describe 'profile.d/dev-tools-modules/encoding/encoding.ps1 extended scenarios' {
    It 'Documents URL and HTML encoding utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'URL and HTML encoding utilities'
        $c | Should -Match 'System.Web.HttpUtility'
    }
    It 'Defines ConvertTo-UrlEncoded and ConvertFrom-HtmlEncoded helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertTo-UrlEncoded'
        $c | Should -Match 'ConvertFrom-HtmlEncoded'
        $c | Should -Match 'Initialize-DevTools-Encoding'
    }
    It 'Registers url-encode, url-decode, html-encode, and html-decode aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'url-encode'"
        $c | Should -Match "Set-AgentModeAlias -Name 'html-decode'"
    }
}
