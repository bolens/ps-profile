<#
tests/unit/test-runner-test-comprehensive-reporting-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestComprehensiveReporting.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestComprehensiveReporting.psm1 structure extended scenarios' {
    It 'Documents comprehensive test reporting module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestComprehensiveReporting.psm1'
        $c | Should -Match 'comprehensive'
    }
    It 'Defines report generation entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-ComprehensiveTestReport'
        $c | Should -Match 'comprehensive'
    }
    It 'Exports comprehensive reporting helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}

