<#
tests/unit/profile-conversion-data-compression-snappy-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/compression/snappy.ps1'
}
Describe 'profile.d/conversion-modules/data/compression/snappy.ps1 extended scenarios' {
    It 'Documents Snappy compression format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Snappy compression format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreCompressionSnappy with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreCompressionSnappy'
        $c | Should -Match 'Get-CachedExternalCommand ''snappy'''
    }
    It 'Registers compress-snappy and Expand-Snappy entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'compress-snappy'
        $c | Should -Match 'Expand-Snappy'
    }
}
