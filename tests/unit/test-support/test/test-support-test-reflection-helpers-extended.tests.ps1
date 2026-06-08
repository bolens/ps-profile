<#
tests/unit/test-support-test-reflection-helpers-extended.tests.ps1
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

