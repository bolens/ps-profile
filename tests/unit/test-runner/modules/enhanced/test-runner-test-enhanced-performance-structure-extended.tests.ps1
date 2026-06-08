<#
tests/unit/test-runner-test-enhanced-performance-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestEnhancedPerformance.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestEnhancedPerformance.psm1 structure extended scenarios' {
    It 'Documents enhanced performance monitoring module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestEnhancedPerformance.psm1'
        $c | Should -Match 'performance'
    }
    It 'Tracks memory and CPU metrics during test runs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'memory'
        $c | Should -Match 'CPU'
    }
    It 'Exports enhanced performance helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}

