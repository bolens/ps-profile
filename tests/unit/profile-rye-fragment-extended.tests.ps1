<#
tests/unit/profile-rye-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/rye.ps1'
}
Describe 'profile.d/rye.ps1 extended scenarios' {
    It 'Declares standard tier guarded by rye availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand rye\)'
    }
    It 'Defines Add-RyePackage with dev and optional flags' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Add-RyePackage'
        $c | Should -Match '\[switch\]\$Optional'
    }
    It 'Registers ryeadd and ryesync aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ryeadd'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ryesync'"
    }
}
