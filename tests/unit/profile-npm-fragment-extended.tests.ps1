<#
tests/unit/profile-npm-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/npm.ps1'
}
Describe 'profile.d/npm.ps1 extended scenarios' {
    It 'Declares standard tier guarded by npm availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand npm\)'
    }
    It 'Defines Install-NpmPackage with dev global and prod switches' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-NpmPackage'
        $c | Should -Match '\[switch\]\$Dev'
    }
    It 'Registers npminstall and npmadd aliases for package installation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'npminstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'npmadd'"
    }
}
