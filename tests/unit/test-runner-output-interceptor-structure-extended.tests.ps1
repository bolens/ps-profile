<#
tests/unit/test-runner-output-interceptor-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/OutputInterceptor.psm1'
}
Describe 'scripts/utils/code-quality/modules/OutputInterceptor.psm1 structure extended scenarios' {
    It 'Documents output interception utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Output interception utilities'
        $c | Should -Match 'OutputInterceptor.psm1'
    }
    It 'Defines start and stop interceptor helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-TestOutputInterceptor'
        $c | Should -Match 'Stop-TestOutputInterceptor'
        $c | Should -Match 'Write-Host'
    }
    It 'Imports OutputSanitizer module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'OutputSanitizer.psm1'
        $c | Should -Match 'EmittedWarningMessages'
        $c | Should -Match 'Export-ModuleMember'
    }
}
