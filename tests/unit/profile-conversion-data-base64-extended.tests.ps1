<#
tests/unit/profile-conversion-data-base64-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/base64/base64.ps1'
}
Describe 'profile.d/conversion-modules/data/base64/base64.ps1 extended scenarios' {
    It 'Documents Base64 format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base64 format conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreBasic'
    }
    It 'Defines Initialize-FileConversion-CoreBasicBase64 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreBasicBase64'
        $c | Should -Match '_ConvertTo-Base64'
    }
    It 'Registers to-base64 and from-base64 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'to-base64'
        $c | Should -Match 'from-base64'
    }
}
