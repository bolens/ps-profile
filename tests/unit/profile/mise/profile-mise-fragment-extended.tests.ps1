<#
tests/unit/profile-mise-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/mise.ps1'
}
Describe 'profile.d/mise.ps1 extended scenarios' {
    It 'Declares standard tier for mise runtime version management' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'formerly rtx'
    }
    It 'Defines Test-MiseOutdated wrapping mise outdated command' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-MiseOutdated'
        $c | Should -Match 'mise outdated'
    }
    It 'Registers mise-outdated and mise-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'mise-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'mise-update'"
    }
}
