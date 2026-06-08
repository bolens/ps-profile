<#
tests/unit/profile-oh-my-posh-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/oh-my-posh.ps1'
}
Describe 'profile.d/oh-my-posh.ps1 extended scenarios' {
    It 'Declares essential tier for prompt framework initialization' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Uses Test-CachedCommand before initializing oh-my-posh' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-CachedCommand 'oh-my-posh'"
        $c | Should -Match 'oh-my-posh init'
    }
    It 'Treats starship as mutually exclusive with oh-my-posh prompt setup' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'mutually exclusive'
        $c | Should -Match 'Starship'
    }
}
