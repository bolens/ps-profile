<#
tests/unit/profile-conversion-data-compression-xz-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/compression/xz.ps1'
}
Describe 'profile.d/conversion-modules/data/compression/xz.ps1 extended scenarios' {
    It 'Documents XZ/LZMA compression format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'XZ/LZMA compression format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreCompressionXz with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreCompressionXz'
        $c | Should -Match '_Compress-Xz'
    }
    It 'Registers compress-xz and compress-lzma entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'compress-xz'
        $c | Should -Match 'compress-lzma'
    }
}
