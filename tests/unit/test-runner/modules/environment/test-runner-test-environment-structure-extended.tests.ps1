<#
tests/unit/test-runner-test-environment-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestEnvironment.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestEnvironment.psm1 structure extended scenarios' {
    It 'Documents test environment detection utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test environment detection and health check utilities'
        $c | Should -Match 'TestEnvironment.psm1'
    }
    It 'Defines environment info and health checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestEnvironment'
        $c | Should -Match 'Test-TestEnvironmentHealth'
    }
    It 'Exports environment helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'IsCI'
    }
}
