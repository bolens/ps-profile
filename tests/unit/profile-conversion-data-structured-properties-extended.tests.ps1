<#
tests/unit/profile-conversion-data-structured-properties-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/properties.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/properties.ps1 extended scenarios' {
    It 'Documents Java Properties file format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Java Properties file format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Properties with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Properties'
        $c | Should -Match '_ConvertFrom-PropertiesToJson'
    }
    It 'Registers _ConvertTo-PropertiesFromJson and _ConvertFrom-PropertiesToYaml entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertTo-PropertiesFromJson'
        $c | Should -Match '_ConvertFrom-PropertiesToYaml'
    }
}
