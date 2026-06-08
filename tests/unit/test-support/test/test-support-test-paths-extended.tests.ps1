<#
tests/unit/test-support-test-paths-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestPaths.ps1'
}
Describe 'tests/TestSupport/TestPaths.ps1 extended scenarios' {
    It 'Documents test path resolution utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestPaths.ps1'
        $c | Should -Match 'Get-TestRepoRoot'
    }
    It 'Defines temp directory and artifact path helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-TestTempDirectory'
        $c | Should -Match 'Get-TestArtifactsPath'
        $c | Should -Match 'New-TestTempFile'
    }
    It 'Registers cleanup paths for transient test artifacts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-TestCleanupPath'
        $c | Should -Match 'Clear-RegisteredTestCleanupPaths'
        $c | Should -Match 'Get-TestArtifactPath'
    }
}

