<#
tests/unit/profile-dev-tools-qrcode-formats-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/format/qrcode/qrcode-formats.ps1'
}
Describe 'profile.d/dev-tools-modules/format/qrcode/qrcode-formats.ps1 extended scenarios' {
    It 'Documents QR code output format variants' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-QrCode-Formats'
        $c | Should -Match 'Initialize-DevTools-QrCode'
    }
    It 'Defines New-QrCodeSvg, New-QrCodeTerminal, and New-QrCodeDataUri' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-QrCodeSvg'
        $c | Should -Match 'New-QrCodeTerminal'
        $c | Should -Match 'New-QrCodeDataUri'
    }
    It 'Registers qrcode-svg, qrcode-term, and qrcode-uri aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-svg'"
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-term'"
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-uri'"
    }
}
