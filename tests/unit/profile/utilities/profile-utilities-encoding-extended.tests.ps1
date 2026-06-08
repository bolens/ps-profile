<#
tests/unit/profile-utilities-encoding-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/data/utilities-encoding.ps1'
}
Describe 'profile.d/utilities-modules/data/utilities-encoding.ps1 extended scenarios' {
    It 'Documents encoding utilities for URL encoding and decoding' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Encoding utility functions'
        $c | Should -Match 'URL encoding/decoding'
    }
    It 'Defines ConvertTo-UrlEncoded and ConvertFrom-UrlEncoded using uri class' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertTo-UrlEncoded'
        $c | Should -Match 'ConvertFrom-UrlEncoded'
        $c | Should -Match 'EscapeDataString'
        $c | Should -Match 'UnescapeDataString'
    }
    It 'Registers url-encode and url-decode aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'url-encode'"
        $c | Should -Match "Set-AgentModeAlias -Name 'url-decode'"
    }
}
