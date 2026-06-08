<#
tests/unit/profile-fzf-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/fzf.ps1'
}
Describe 'profile.d/fzf.ps1 extended scenarios' {
    It 'Declares essential tier for fuzzy finder helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Find-FileFuzzy guarded by Test-CachedCommand fzf' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-FileFuzzy'
        $c | Should -Match 'Test-CachedCommand fzf'
    }
    It 'Registers ff alias and documents PowerShell.Profile.Fzf module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ff'"
        $c | Should -Match 'PowerShell.Profile.Fzf'
    }
}
