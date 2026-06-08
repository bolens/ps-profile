<#
tests/unit/profile-lang-python-pipx-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-python-pipx.ps1'
}
Describe 'profile.d/lang-python-pipx.ps1 extended scenarios' {
    It 'Declares standard tier with Test-FragmentLoaded idempotency guard' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match "FragmentName 'lang-python-pipx'"
    }
    It 'Defines Install-PythonApp with Invoke-MissingToolWarning when pipx unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-PythonApp'
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers pipx-install alias and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pipx-install'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'lang-python-pipx'"
    }
}
