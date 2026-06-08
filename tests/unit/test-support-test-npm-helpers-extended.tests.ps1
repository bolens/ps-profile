<#
tests/unit/test-support-test-npm-helpers-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestNpmHelpers.ps1'
}
Describe 'tests/TestSupport/TestNpmHelpers.ps1 extended scenarios' {
    It 'Documents NPM package availability testing utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestNpmHelpers.ps1'
        $c | Should -Match 'NPM package availability'
    }
    It 'Defines Get-TestNodeModuleSearchPaths helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestNodeModuleSearchPaths'
        $c | Should -Match 'node_modules'
    }
    It 'Defines Test-NpmPackageAvailable helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-NpmPackageAvailable'
    }
}

