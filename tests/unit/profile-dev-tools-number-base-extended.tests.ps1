<#
tests/unit/profile-dev-tools-number-base-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/data/number-base.ps1'
}
Describe 'profile.d/dev-tools-modules/data/number-base.ps1 extended scenarios' {
    It 'Documents number base conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Number base conversion utilities'
        $c | Should -Match 'Ensure-DevTools'
    }
    It 'Defines Convert-NumberBase between Binary, Octal, Decimal, and Hexadecimal' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-NumberBase'
        $c | Should -Match 'Initialize-DevTools-NumberBase'
        $c | Should -Match 'Hexadecimal'
    }
    It 'Registers base-convert alias targeting Convert-NumberBase' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'base-convert'"
        $c | Should -Match "Target 'Convert-NumberBase'"
    }
}
