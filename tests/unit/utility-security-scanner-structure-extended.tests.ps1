<#
tests/unit/utility-security-scanner-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/security/modules/SecurityScanner.psm1'
}
Describe 'scripts/utils/security/modules/SecurityScanner.psm1 structure extended scenarios' {
    It 'Documents security scanning utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Security scanning utilities'
        $c | Should -Match 'SecurityScanner.psm1'
    }
    It 'Defines Invoke-SecurityScan analyzer entry point' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-SecurityScan'
        $c | Should -Match 'PSScriptAnalyzer'
        $c | Should -Match 'SecretPatterns'
    }
    It 'Accepts allowlist and false positive patterns' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FalsePositivePatterns'
        $c | Should -Match 'Allowlist'
        $c | Should -Match 'Export-ModuleMember'
    }
}
