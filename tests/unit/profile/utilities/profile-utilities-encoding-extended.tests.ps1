# ===============================================
# profile-utilities-encoding-extended.tests.ps1
# Execution tests for utilities-modules/data/utilities-encoding.ps1 behavior
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

Describe 'profile.d/utilities-modules/data/utilities-encoding.ps1 extended scenarios' {
    It 'Registers URL encoding helpers through Ensure-Utilities' {
        Get-Command ConvertTo-UrlEncoded -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertFrom-UrlEncoded -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $encodeAlias = Get-Alias url-encode -ErrorAction SilentlyContinue
        if ($encodeAlias) {
            $encodeAlias.ResolvedCommandName | Should -Be 'ConvertTo-UrlEncoded'
        }
    }

    It 'ConvertTo-UrlEncoded and ConvertFrom-UrlEncoded round-trip text' {
        $encoded = ConvertTo-UrlEncoded -text 'hello world'
        $encoded | Should -Be 'hello%20world'
        ConvertFrom-UrlEncoded -text $encoded | Should -Be 'hello world'
    }

    It 'Allows repeated Ensure-Utilities calls without losing encoding helpers' {
        Ensure-Utilities
        Ensure-Utilities

        ConvertTo-UrlEncoded -text 'test value' | Should -Be 'test%20value'
    }
}
