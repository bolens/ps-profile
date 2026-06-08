<#
tests/unit/utility-security-patterns-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/security/modules/SecurityPatterns.psm1'
}
Describe 'scripts/utils/security/modules/SecurityPatterns.psm1 structure extended scenarios' {
    It 'Documents security pattern matching utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Security pattern matching utilities'
        $c | Should -Match 'SecurityPatterns.psm1'
    }
    It 'Defines external command and secret pattern getters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ExternalCommandPatterns'
        $c | Should -Match 'Get-SecretPatterns'
        $c | Should -Match 'Get-FalsePositivePatterns'
    }
    It 'Exports pattern helper functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'compiled regex'
    }
}
