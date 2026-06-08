<#
tests/unit/profile-hatch-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/hatch.ps1'
}
Describe 'profile.d/hatch.ps1 extended scenarios' {
    It 'Declares standard tier and requires Test-CachedCommand hatch' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand hatch'
    }
    It 'Defines New-HatchEnvironment and Build-HatchProject helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-HatchEnvironment'
        $c | Should -Match 'Build-HatchProject'
    }
    It 'Registers hatchenv and hatchbuild aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'hatchenv'"
        $c | Should -Match "Set-AgentModeAlias -Name 'hatchbuild'"
    }
}
