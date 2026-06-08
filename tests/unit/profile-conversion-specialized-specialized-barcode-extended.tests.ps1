<#
tests/unit/profile-conversion-specialized-specialized-barcode-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/specialized/specialized-barcode.ps1'
}
Describe 'profile.d/conversion-modules/specialized/specialized-barcode.ps1 extended scenarios' {
    It 'Documents barcode conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Barcode conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-SpecializedBarcode'
    }
    It 'Defines text and JSON to barcode conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertTo-BarcodeFromText'
        $c | Should -Match '_ConvertTo-BarcodeFromJson'
    }
    It 'Registers text-to-barcode and barcode-to-text entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'text-to-barcode'
        $c | Should -Match 'ConvertFrom-BarcodeToText'
        $c | Should -Match 'barcode-to-text'
    }
}
