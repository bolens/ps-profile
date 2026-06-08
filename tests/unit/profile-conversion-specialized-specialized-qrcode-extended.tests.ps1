<#
tests/unit/profile-conversion-specialized-specialized-qrcode-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/specialized/specialized-qrcode.ps1'
}
Describe 'profile.d/conversion-modules/specialized/specialized-qrcode.ps1 extended scenarios' {
    It 'Documents QR Code conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'QR Code conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-SpecializedQrCode'
    }
    It 'Defines text and JSON to QR Code conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertTo-QrCodeFromText'
        $c | Should -Match '_ConvertTo-QrCodeFromJson'
    }
    It 'Registers text-to-qrcode and qrcode-to-text entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'text-to-qrcode'
        $c | Should -Match 'ConvertFrom-QrCodeToText'
        $c | Should -Match 'qrcode-to-text'
    }
}
