<#
tests/unit/test-runner-test-failure-analysis-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestFailureAnalysis.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestFailureAnalysis.psm1 structure extended scenarios' {
    It 'Documents test failure analysis module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestFailureAnalysis.psm1'
        $c | Should -Match 'failure analysis'
    }
    It 'Defines Get-FailureAnalysis helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-FailureAnalysis'
    }
    It 'Exports failure analysis function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Get-FailureAnalysis'
    }
}

