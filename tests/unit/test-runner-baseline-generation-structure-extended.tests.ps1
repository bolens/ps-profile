<#
tests/unit/test-runner-baseline-generation-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/BaselineGeneration.psm1'
}
Describe 'scripts/utils/code-quality/modules/BaselineGeneration.psm1 structure extended scenarios' {
    It 'Documents performance baseline generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Performance baseline generation utilities'
        $c | Should -Match 'BaselineGeneration.psm1'
    }
    It 'Defines New-PerformanceBaseline helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-PerformanceBaseline'
        $c | Should -Match 'performance-baseline.json'
        $c | Should -Match 'PerformanceData'
    }
    It 'Imports TestEnvironment and JsonUtilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestEnvironment.psm1'
        $c | Should -Match 'JsonUtilities.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
