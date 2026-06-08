<#
tests/unit/profile-conversion-data-digest-digest-hash-format-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/digest/digest-hash-format.ps1'
}
Describe 'profile.d/conversion-modules/data/digest/digest-hash-format.ps1 extended scenarios' {
    It 'Documents Hash format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Hash format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-DigestHashFormat with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DigestHashFormat'
        $c | Should -Match 'ConvertFrom-HashHexToBase64'
    }
    It 'Registers hash-hex-to-base64 and hash-base64-to-hex entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'hash-hex-to-base64'
        $c | Should -Match 'hash-base64-to-hex'
    }
}
