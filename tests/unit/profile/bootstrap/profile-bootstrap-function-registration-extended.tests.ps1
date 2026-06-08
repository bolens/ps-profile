<#
tests/unit/profile-bootstrap-function-registration-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/FunctionRegistration.ps1'
}
Describe 'profile.d/bootstrap/FunctionRegistration.ps1 extended scenarios' {
    It 'Documents collision-safe function and alias registration utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Function and alias registration utilities'
        $c | Should -Match 'collision-safe function'
    }
    It 'Defines Set-AgentModeFunction and Set-AgentModeAlias helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AgentModeFunction'
        $c | Should -Match 'Set-AgentModeAlias'
        $c | Should -Match 'Register-LazyFunction'
    }
    It 'Defines Register-ToolWrapper and Register-FragmentFunction helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-ToolWrapper'
        $c | Should -Match 'Register-FragmentFunction'
        $c | Should -Match 'New-FragmentCommandProxy'
    }
}
