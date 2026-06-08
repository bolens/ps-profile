<#
tests/unit/utility-security-rules-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/security/modules/SecurityRules.psm1'
}
Describe 'scripts/utils/security/modules/SecurityRules.psm1 structure extended scenarios' {
    It 'Documents security rule configuration utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Security rule configuration utilities'
        $c | Should -Match 'SecurityRules.psm1'
    }
    It 'Defines Get-SecurityRules for PSScriptAnalyzer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-SecurityRules'
        $c | Should -Match 'PSScriptAnalyzer'
        $c | Should -Match 'PSAvoidUsingInvokeExpression'
    }
    It 'Exports security rules function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function Get-SecurityRules'
        $c | Should -Match 'PSAvoidUsingPlainTextForPassword'
    }
}
