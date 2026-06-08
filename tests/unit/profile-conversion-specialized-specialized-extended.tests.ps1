<#
tests/unit/profile-conversion-specialized-specialized-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/specialized/specialized.ps1'
}
Describe 'profile.d/conversion-modules/specialized/specialized.ps1 extended scenarios' {
    It 'Documents specialized format conversion utilities loader' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Specialized format conversion utilities'
        $c | Should -Match 'QR Code, JWT, Barcode'
    }
    It 'Dot-sources qrcode jwt and barcode sub-modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'specialized-qrcode.ps1'
        $c | Should -Match 'specialized-jwt.ps1'
        $c | Should -Match 'specialized-barcode.ps1'
    }
    It 'Defines Initialize-FileConversion-Specialized delegating to sub-modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Specialized'
        $c | Should -Match 'Initialize-FileConversion-SpecializedQrCode'
        $c | Should -Match 'Initialize-FileConversion-SpecializedBarcode'
    }
}
