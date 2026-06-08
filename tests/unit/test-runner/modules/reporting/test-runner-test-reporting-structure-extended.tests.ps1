<#
tests/unit/test-runner-test-reporting-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestReporting.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestReporting.psm1 structure extended scenarios' {
    It 'Documents test reporting and analysis module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Advanced test reporting and analysis utilities'
        $c | Should -Match 'TestReporting.psm1'
    }
    It 'Defines Get-TestAnalysisReport with analysis submodules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestAnalysisReport'
        $c | Should -Match 'TestFailureAnalysis.psm1'
        $c | Should -Match 'TestReportFormats.psm1'
    }
    It 'Exports reporting entry point for test runner' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Get-TestAnalysisReport'
    }
}
