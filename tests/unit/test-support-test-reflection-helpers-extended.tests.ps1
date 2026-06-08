<#
tests/unit/test-support-test-reflection-helpers-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestReflectionHelpers.ps1'
}
Describe 'tests/TestSupport/TestReflectionHelpers.ps1 extended scenarios' {
    It 'Documents reflection wrappers for error path testing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestReflectionHelpers.ps1'
        $c | Should -Match 'Reflection wrappers'
    }
    It 'Defines Invoke-MakeGenericTypeWrapper helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-MakeGenericTypeWrapper'
        $c | Should -Match 'MakeGenericType'
    }
    It 'Defines Invoke-CreateInstanceWrapper helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-CreateInstanceWrapper'
        $c | Should -Match 'ForceException'
    }
}

