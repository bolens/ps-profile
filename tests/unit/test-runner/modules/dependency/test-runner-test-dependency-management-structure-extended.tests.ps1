<#
tests/unit/test-runner-test-dependency-management-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestDependencyManagement.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestDependencyManagement.psm1 structure extended scenarios' {
    It 'Documents test dependency management utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test dependency management utilities'
        $c | Should -Match 'TestDependencyManagement.psm1'
    }
    It 'Defines Get-TestExecutionOrder for ordered runs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestExecutionOrder'
        $c | Should -Match 'DependencyMap'
    }
    It 'Exports execution order helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function Get-TestExecutionOrder'
    }
}
