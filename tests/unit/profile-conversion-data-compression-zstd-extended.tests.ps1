<#
tests/unit/profile-conversion-data-compression-zstd-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/compression/zstd.ps1'
}
Describe 'profile.d/conversion-modules/data/compression/zstd.ps1 extended scenarios' {
    It 'Documents Zstandard \(zstd\) compression format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Zstandard \(zstd\) compression format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreCompressionZstd with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreCompressionZstd'
        $c | Should -Match '_Compress-Zstd'
    }
    It 'Registers compress-zstd and Expand-Zstd entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'compress-zstd'
        $c | Should -Match 'Expand-Zstd'
    }
}
