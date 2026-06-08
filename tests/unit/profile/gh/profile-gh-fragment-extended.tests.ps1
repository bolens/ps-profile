<#
tests/unit/profile-gh-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/gh.ps1'
}
Describe 'profile.d/gh.ps1 extended scenarios' {
    It 'Declares essential tier for GitHub CLI helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Open-GitHubRepository guarded by Test-CachedCommand gh' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Open-GitHubRepository'
        $c | Should -Match 'Test-CachedCommand gh'
    }
    It 'Registers gh-open alias and documents PowerShell.Profile.GitHub' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'gh-open'"
        $c | Should -Match 'PowerShell.Profile.GitHub'
    }
}
