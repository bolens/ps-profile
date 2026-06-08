<#
tests/unit/profile-dev-tools-qrcode-communication-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1'
}
Describe 'profile.d/dev-tools-modules/format/qrcode/qrcode-communication.ps1 extended scenarios' {
    It 'Documents communication QR code payload generators' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-QrCode-Communication'
        $c | Should -Match 'URL, SMS, email, and phone'
    }
    It 'Defines New-QrCodeUrl, New-QrCodeSms, and New-QrCodeEmail helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-QrCodeUrl'
        $c | Should -Match 'New-QrCodeSms'
        $c | Should -Match 'New-QrCodeEmail'
    }
    It 'Registers qrcode-url, qrcode-sms, and qrcode-phone aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-url'"
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-sms'"
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-phone'"
    }
}
