<#
tests/unit/profile-files-hexdump-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-modules/inspection/files-hexdump.ps1'
}
Describe 'profile.d/files-modules/inspection/files-hexdump.ps1 extended scenarios' {
    It 'Documents hex dump utilities for binary file inspection' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'File hex dump utility functions'
        $c | Should -Match 'hexadecimal representation of files'
    }
    It 'Defines Initialize-FileUtilities-HexDump using Format-Hex' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileUtilities-HexDump'
        $c | Should -Match 'Get-HexDump'
        $c | Should -Match 'Format-Hex'
    }
    It 'Registers hex-dump alias targeting Get-HexDump' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'hex-dump'"
        $c | Should -Match "Target 'Get-HexDump'"
    }
}
