<#
tests/unit/profile-conversion-data-digest-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/digest/digest.ps1'
}
Describe 'profile.d/conversion-modules/data/digest/digest.ps1 extended scenarios' {
    It 'Documents Hash & Digest format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Hash & Digest format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Digest with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Digest'
        $c | Should -Match 'digest-hash-format.ps1'
    }
    It 'Registers Initialize-FileConversion-DigestHashFormat and Initialize-FileConversion-DigestChecksum entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DigestHashFormat'
        $c | Should -Match 'Initialize-FileConversion-DigestChecksum'
    }
}
