<#
tests/unit/profile-conversion-data-core-yaml-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/core/yaml.ps1'
}
Describe 'profile.d/conversion-modules/data/core/yaml.ps1 extended scenarios' {
    It 'Documents YAML format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'YAML format conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreBasic'
    }
    It 'Defines Initialize-FileConversion-CoreBasicYaml with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreBasicYaml'
        $c | Should -Match 'Test-CachedCommand ''yq'''
    }
    It 'Registers yaml-to-json and json-to-yaml entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'yaml-to-json'
        $c | Should -Match 'json-to-yaml'
    }
}
