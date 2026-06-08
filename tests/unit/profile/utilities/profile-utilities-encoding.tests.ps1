# ===============================================
# profile-utilities-encoding.tests.ps1
# Behavioral unit tests for URL encoding utilities
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

Describe 'utilities-encoding.ps1 - URL encoding' {
    It 'ConvertTo-UrlEncoded encodes spaces and reserved characters' {
        ConvertTo-UrlEncoded -text 'hello world&foo=bar' | Should -Be 'hello%20world%26foo%3Dbar'
    }

    It 'ConvertFrom-UrlEncoded decodes percent-encoded sequences' {
        ConvertFrom-UrlEncoded -text 'hello%20world%26foo%3Dbar' | Should -Be 'hello world&foo=bar'
    }

    It 'Round-trips Unicode text through encode and decode' {
        $original = 'café ☕'
        $encoded = ConvertTo-UrlEncoded -text $original
        $decoded = ConvertFrom-UrlEncoded -text $encoded

        $decoded | Should -Be $original
        $encoded | Should -Match '%'
    }

    It 'Handles empty strings without error' {
        ConvertTo-UrlEncoded -text '' | Should -Be ''
        ConvertFrom-UrlEncoded -text '' | Should -Be ''
    }

    It 'Registers url-encode and url-decode aliases' {
        (Get-Command url-encode -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-UrlEncoded'
        (Get-Command url-decode -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-UrlEncoded'
    }
}
