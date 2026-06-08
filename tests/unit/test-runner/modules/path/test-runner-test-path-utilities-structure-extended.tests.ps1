<#
tests/unit/test-runner-test-path-utilities-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestPathUtilities.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestPathUtilities.psm1 structure extended scenarios' {
    It 'Documents test path utilities for runner scripts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestPathUtilities.psm1'
        $c | Should -Match 'Test path validation, filtering, and logging utilities'
    }
    It 'Defines Test-TestPaths and Filter-TestPaths helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-TestPaths'
        $c | Should -Match 'Filter-TestPaths'
        $c | Should -Match 'Get-ShuffledTestPaths'
    }
    It 'Exports path helper functions for test discovery' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Write-TestDiscoveryInfo'
    }
}
