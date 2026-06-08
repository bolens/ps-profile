<#
tests/unit/test-runner-exception-handler-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/ExceptionHandler.psm1'
}
Describe 'scripts/utils/code-quality/modules/ExceptionHandler.psm1 structure extended scenarios' {
    It 'Documents exception handling for naming validation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ExceptionHandler.psm1'
        $c | Should -Match 'naming validation'
    }
    It 'Defines Get-NamingExceptions parser' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-NamingExceptions'
        $c | Should -Match 'ExceptionVerbs'
    }
    It 'Defines Test-IsException helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-IsException'
        $c | Should -Match 'Export-ModuleMember'
    }
}

