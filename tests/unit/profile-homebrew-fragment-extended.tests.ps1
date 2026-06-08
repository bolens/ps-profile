<#
tests/unit/profile-homebrew-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/homebrew.ps1'
}
Describe 'profile.d/homebrew.ps1 extended scenarios' {
    It 'Declares standard tier guarded by brew availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand brew\)'
    }
    It 'Defines Install-BrewPackage with cask support for GUI apps' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-BrewPackage'
        $c | Should -Match '\[switch\]\$Cask'
    }
    It 'Registers brewinstall and brewoutdated aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'brewinstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'brewoutdated'"
    }
}
