<#
tests/unit/profile-conversion-data-structured-cfg-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/cfg.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/cfg.ps1 extended scenarios' {
    It 'Documents CFG/ConfigParser format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CFG/ConfigParser format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Cfg with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Cfg'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers cfg-to-json and json-to-cfg entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'cfg-to-json'
        $c | Should -Match 'json-to-cfg'
    }
}
