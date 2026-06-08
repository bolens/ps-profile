<#
tests/unit/profile-profile-updates-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/profile-updates.ps1'
}
Describe 'profile.d/profile-updates.ps1 extended scenarios' {
    It 'Declares optional tier for profile update checking' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Test-ProfileUpdates with git fetch and changelog logic' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ProfileUpdates'
        $c | Should -Match 'git fetch origin'
        $c | Should -Match '.profile-last-update-check'
    }
    It 'Sets ProfileUpdatesLoaded global after initialization' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "ProfileUpdatesLoaded"
        $c | Should -Match "Set-Variable -Name 'ProfileUpdatesLoaded'"
    }
}
