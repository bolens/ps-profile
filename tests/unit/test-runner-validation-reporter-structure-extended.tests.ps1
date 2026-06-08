<#
tests/unit/test-runner-validation-reporter-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/ValidationReporter.psm1'
}
Describe 'scripts/utils/code-quality/modules/ValidationReporter.psm1 structure extended scenarios' {
    It 'Documents validation reporting module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ValidationReporter.psm1'
        $c | Should -Match 'validation'
    }
    It 'Defines Get-ValidationResults and Write-ValidationReport' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ValidationResults'
        $c | Should -Match 'Write-ValidationReport'
    }
    It 'Defines Save-ValidationReport helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Save-ValidationReport'
        $c | Should -Match 'Export-ModuleMember'
    }
}

