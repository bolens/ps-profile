<#
tests/unit/profile-conversion-data-compression-brotli-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/compression/brotli.ps1'
}
Describe 'profile.d/conversion-modules/data/compression/brotli.ps1 extended scenarios' {
    It 'Documents Brotli compression format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Brotli compression format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreCompressionBrotli with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreCompressionBrotli'
        $c | Should -Match 'BrotliStream'
    }
    It 'Registers compress-brotli and Expand-Brotli entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'compress-brotli'
        $c | Should -Match 'Expand-Brotli'
    }
}
