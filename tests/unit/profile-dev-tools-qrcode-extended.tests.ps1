<#
tests/unit/profile-dev-tools-qrcode-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/format/qrcode/qrcode.ps1'
}
Describe 'profile.d/dev-tools-modules/format/qrcode/qrcode.ps1 extended scenarios' {
    It 'Documents QR code generation utilities requiring Node.js' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'QR code generation utilities'
        $c | Should -Match 'qrcode package'
    }
    It 'Defines Initialize-DevTools-QrCode and New-QrCode with error correction' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-QrCode'
        $c | Should -Match 'New-QrCode'
        $c | Should -Match 'ErrorCorrectionLevel'
    }
    It 'Registers qrcode alias targeting New-QrCode' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode'"
        $c | Should -Match "Target 'New-QrCode'"
    }
}
