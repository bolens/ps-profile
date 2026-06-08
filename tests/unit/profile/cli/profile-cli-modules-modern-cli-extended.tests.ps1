<#
tests/unit/profile-cli-modules-modern-cli-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/cli-modules/modern-cli.ps1'
}
Describe 'profile.d/cli-modules/modern-cli.ps1 extended scenarios' {
    It 'Documents modern CLI tool wrappers with Register-ToolWrapper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Modern CLI tools helper functions'
        $c | Should -Match 'Register-ToolWrapper'
    }
    It 'Registers bat fd http zoxide and delta tool wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Register-ToolWrapper -FunctionName 'bat'"
        $c | Should -Match "Register-ToolWrapper -FunctionName 'fd'"
        $c | Should -Match "Register-ToolWrapper -FunctionName 'zoxide'"
    }
    It 'Defines enhanced wrappers and short aliases ffd grg and z' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-WithFd'
        $c | Should -Match 'Grep-WithRipgrep'
        $c | Should -Match "Set-AgentModeAlias -Name 'ffd'"
    }
}
