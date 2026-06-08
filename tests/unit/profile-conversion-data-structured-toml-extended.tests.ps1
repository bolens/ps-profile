<#
tests/unit/profile-conversion-data-structured-toml-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/toml.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/toml.ps1 extended scenarios' {
    It 'Documents TOML document conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TOML \(Tom''s Obvious, Minimal Language\) conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Toml with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Toml'
        $c | Should -Match 'PSToml'
    }
    It 'Registers toml-to-json and json-to-toml entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'toml-to-json'
        $c | Should -Match 'json-to-toml'
    }
}
