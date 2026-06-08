<#
tests/unit/test-runner-test-path-resolution-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestPathResolution.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestPathResolution.psm1 structure extended scenarios' {
    It 'Documents test path resolution utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test path resolution utilities'
        $c | Should -Match 'TestPathResolution.psm1'
    }
    It 'Defines suite and specific path helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestPaths'
        $c | Should -Match 'Get-TestSuitePaths'
        $c | Should -Match 'Get-SpecificTestPaths'
    }
    It 'Imports CommonEnums and FileSystem modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'FileSystem.psm1'
        $c | Should -Match 'Get-TestFilesFromDirectory'
    }
}
