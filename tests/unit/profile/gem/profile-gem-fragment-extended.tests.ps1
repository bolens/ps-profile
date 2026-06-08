<#
tests/unit/profile-gem-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/gem.ps1'
}
Describe 'profile.d/gem.ps1 extended scenarios' {
    It 'Declares standard tier guarded by gem availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand gem'
    }
    It 'Defines Test-GemOutdated wrapping gem outdated' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-GemOutdated'
        $c | Should -Match 'gem outdated'
    }
    It 'Registers gem-outdated and gem-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'gem-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'gem-update'"
    }
}
