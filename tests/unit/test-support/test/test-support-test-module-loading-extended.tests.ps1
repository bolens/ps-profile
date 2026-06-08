<#
tests/unit/test-support-test-module-loading-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestModuleLoading.ps1'
}
Describe 'tests/TestSupport/TestModuleLoading.ps1 extended scenarios' {
    It 'Documents module loading utilities for tests' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestModuleLoading.ps1'
        $c | Should -Match 'Module loading utilities'
    }
    It 'Defines Import-TestModule and conversion module loaders' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-TestModule'
        $c | Should -Match 'Import-ConversionHelpers'
        $c | Should -Match 'Ensure-ConversionModulesLoaded'
    }
    It 'Defines Initialize-TestProfile for integration tests' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-TestProfile'
        $c | Should -Match 'Initialize-ConversionIntegration'
    }
}

