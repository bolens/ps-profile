<#
tests/unit/profile-wsl-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/wsl.ps1'
}
Describe 'profile.d/wsl.ps1 extended scenarios' {
    It 'Declares essential tier for WSL helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Stop-WSL and Get-WSLDistribution wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Stop-WSL'
        $c | Should -Match 'Get-WSLDistribution'
        $c | Should -Match 'wsl --shutdown'
        $c | Should -Match 'wsl --list --verbose'
    }
    It 'Registers wsl-shutdown, wsl-list, and ubuntu aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'wsl-shutdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'wsl-list'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ubuntu'"
    }
}
