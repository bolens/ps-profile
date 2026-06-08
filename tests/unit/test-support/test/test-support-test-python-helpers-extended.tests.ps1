<#
tests/unit/test-support-test-python-helpers-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestPythonHelpers.ps1'
}
Describe 'tests/TestSupport/TestPythonHelpers.ps1 extended scenarios' {
    It 'Documents Python package availability testing utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestPythonHelpers.ps1'
        $c | Should -Match 'Python package'
    }
    It 'Defines Test-PythonPackageAvailable helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-PythonPackageAvailable'
    }
    It 'Defines conversion Python test context helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ConversionPythonTestContext'
        $c | Should -Match 'Get-PythonPackageInstallRecommendation'
    }
}

