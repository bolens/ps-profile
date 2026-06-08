<#
tests/unit/profile-nimble-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/nimble.ps1'
}
Describe 'profile.d/nimble.ps1 extended scenarios' {
    It 'Declares standard tier guarded by nimble availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand nimble'
    }
    It 'Defines Test-NimbleOutdated wrapping nimble outdated' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-NimbleOutdated'
        $c | Should -Match 'nimble outdated'
    }
    It 'Registers nimble-outdated and nimble-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'nimble-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'nimble-update'"
    }
}
