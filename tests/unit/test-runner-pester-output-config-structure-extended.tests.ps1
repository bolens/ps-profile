<#
tests/unit/test-runner-pester-output-config-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/PesterOutputConfig.psm1'
}
Describe 'scripts/utils/code-quality/modules/PesterOutputConfig.psm1 structure extended scenarios' {
    It 'Documents Pester output configuration module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PesterOutputConfig.psm1'
        $c | Should -Match 'output'
    }
    It 'Defines verbosity and CI optimization helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-PesterOutputVerbosity'
        $c | Should -Match 'Set-PesterCIOptimizations'
    }
    It 'Defines Set-PesterTestResults helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-PesterTestResults'
        $c | Should -Match 'Export-ModuleMember'
    }
}

