<#
tests/unit/profile-conversion-data-digest-digest-checksum-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/digest/digest-checksum.ps1'
}
Describe 'profile.d/conversion-modules/data/digest/digest-checksum.ps1 extended scenarios' {
    It 'Documents Checksum calculation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Checksum calculation utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-DigestChecksum with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DigestChecksum'
        $c | Should -Match 'Get-Crc32'
    }
    It 'Registers crc32 and adler32 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'crc32'
        $c | Should -Match 'adler32'
    }
}
