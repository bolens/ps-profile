<#
tests/unit/test-support-test-execution-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestExecution.ps1'
}
Describe 'tests/TestSupport/TestExecution.ps1 extended scenarios' {
    It 'Documents test script execution utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestExecution.ps1'
        $c | Should -Match 'Test script execution'
    }
    It 'Defines Invoke-TestPwshScript helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-TestPwshScript'
        $c | Should -Match 'pwsh'
    }
    It 'Defines performance threshold helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-PerformanceThreshold'
        $c | Should -Match 'Initialize-FragmentPerformanceThresholds'
    }
}

