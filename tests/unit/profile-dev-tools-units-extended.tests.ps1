<#
tests/unit/profile-dev-tools-units-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/data/units.ps1'
}
Describe 'profile.d/dev-tools-modules/data/units.ps1 extended scenarios' {
    It 'Documents unit conversion utilities for file sizes and time' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Unit conversion utilities'
        $c | Should -Match 'file sizes, time intervals'
    }
    It 'Defines Convert-Units with file size and time unit tables' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-Units'
        $c | Should -Match 'Initialize-DevTools-Units'
        $c | Should -Match 'fileSizeUnits'
    }
    It 'Registers unit-convert alias targeting Convert-Units' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'unit-convert'"
        $c | Should -Match "Target 'Convert-Units'"
    }
}
