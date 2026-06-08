<#
tests/unit/profile-dev-tools-qrcode-specialized-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1'
}
Describe 'profile.d/dev-tools-modules/format/qrcode/qrcode-specialized.ps1 extended scenarios' {
    It 'Documents specialized QR code payload generators' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-QrCode-Specialized'
        $c | Should -Match 'WiFi, Contact, Calendar'
    }
    It 'Defines New-QrCodeWiFi, New-QrCodeContact, and New-QrCodeTotp helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-QrCodeWiFi'
        $c | Should -Match 'New-QrCodeContact'
        $c | Should -Match 'New-QrCodeTotp'
    }
    It 'Registers qrcode-wifi and qrcode-totp aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-wifi'"
        $c | Should -Match "Set-AgentModeAlias -Name 'qrcode-totp'"
        $c | Should -Match 'New-QrCodeLocation'
    }
}
