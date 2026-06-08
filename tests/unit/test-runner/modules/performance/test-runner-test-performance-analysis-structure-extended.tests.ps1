<#
tests/unit/test-runner-test-performance-analysis-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestPerformanceAnalysis.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestPerformanceAnalysis.psm1 structure extended scenarios' {
    It 'Documents test performance analysis module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestPerformanceAnalysis.psm1'
        $c | Should -Match 'performance analysis'
    }
    It 'Defines Get-PerformanceAnalysis helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-PerformanceAnalysis'
    }
    It 'Exports performance analysis function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Get-PerformanceAnalysis'
    }
}

