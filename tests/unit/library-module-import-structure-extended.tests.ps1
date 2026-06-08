<#
tests/unit/library-module-import-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/lib/ModuleImport.psm1'
}
Describe 'scripts/lib/ModuleImport.psm1 structure extended scenarios' {
    It 'Documents module import utilities for scripts/lib' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module import utilities for scripts/lib'
        $c | Should -Match 'Import-LibModule'
    }
    It 'Imports SafeImport and ErrorHandling dependencies' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SafeImport.psm1'
        $c | Should -Match 'ErrorHandling.psm1'
        $c | Should -Match 'Import-ModuleSafely'
    }
    It 'Exports Get-LibPath and Import-LibModule helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Get-LibPath'
        $c | Should -Match 'function Import-LibModule'
        $c | Should -Match 'Export-ModuleMember'
    }
}

