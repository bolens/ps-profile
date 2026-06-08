<#
tests/unit/profile-conversion-data-network-network-mime-types-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/network/network-mime-types.ps1'
}
Describe 'profile.d/conversion-modules/data/network/network-mime-types.ps1 extended scenarios' {
    It 'Documents MIME types parsing and conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'MIME types parsing and conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-NetworkMimeTypes with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-NetworkMimeTypes'
        $c | Should -Match 'Parse-MimeType'
    }
    It 'Registers parse-mime and mime-from-ext entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'parse-mime'
        $c | Should -Match 'mime-from-ext'
    }
}
