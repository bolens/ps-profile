<#
tests/unit/test-support-test-environment-stubs-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestEnvironmentStubs.ps1'
}
Describe 'tests/TestSupport/TestEnvironmentStubs.ps1 extended scenarios' {
    It 'Documents environment variable stubs with cleanup' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestEnvironmentStubs.ps1'
        $c | Should -Match 'Environment variable stubs'
    }
    It 'Defines mock registry helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-Mock'
        $c | Should -Match 'Restore-AllMocks'
        $c | Should -Match 'Clear-MockRegistry'
    }
    It 'Defines Mock-EnvironmentVariable helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Mock-EnvironmentVariable'
        $c | Should -Match 'Restore-EnvironmentVariable'
        $c | Should -Match 'Mock-EnvironmentVariables'
    }
}

