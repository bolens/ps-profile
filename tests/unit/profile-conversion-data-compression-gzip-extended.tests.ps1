<#
tests/unit/profile-conversion-data-compression-gzip-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/compression/gzip.ps1'
}
Describe 'profile.d/conversion-modules/data/compression/gzip.ps1 extended scenarios' {
    It 'Documents Gzip/Zlib compression format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Gzip/Zlib compression format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreCompressionGzip with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreCompressionGzip'
        $c | Should -Match 'System.IO.Compression'
    }
    It 'Registers gzip-compress and gunzip entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'gzip-compress'
        $c | Should -Match 'gunzip'
    }
}
