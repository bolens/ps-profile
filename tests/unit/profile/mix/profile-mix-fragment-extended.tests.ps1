<#
tests/unit/profile-mix-fragment-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/mix.ps1'
}
Describe 'profile.d/mix.ps1 extended scenarios' {
    It 'Declares standard tier guarded by mix availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand mix'
    }
    It 'Defines Test-MixOutdated wrapping mix deps.outdated' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-MixOutdated'
        $c | Should -Match 'mix deps.outdated'
    }
    It 'Registers mix-outdated and mix-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'mix-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'mix-update'"
    }
}
