<#
tests/unit/test-runner-function-naming-validator-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/FunctionNamingValidator.psm1'
}
Describe 'scripts/utils/code-quality/modules/FunctionNamingValidator.psm1 structure extended scenarios' {
    It 'Documents function naming validation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Function naming validation utilities'
        $c | Should -Match 'FunctionNamingValidator.psm1'
    }
    It 'Defines verb and noun validation helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ApprovedVerb'
        $c | Should -Match 'Get-FunctionParts'
        $c | Should -Match 'Get-Verb'
    }
    It 'Defines agent mode and bootstrap function checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-UsesAgentModeFunction'
        $c | Should -Match 'Test-IsBootstrapFunction'
        $c | Should -Match 'Export-ModuleMember'
    }
}
