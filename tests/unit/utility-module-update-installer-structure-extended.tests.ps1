<#
tests/unit/utility-module-update-installer-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/modules/ModuleUpdateInstaller.psm1'
}
Describe 'scripts/utils/dependencies/modules/ModuleUpdateInstaller.psm1 structure extended scenarios' {
    It 'Documents module update installation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module update installation utilities'
        $c | Should -Match 'ModuleUpdateInstaller.psm1'
    }
    It 'Defines single and batch module update installers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-ModuleUpdate'
        $c | Should -Match 'Install-ModuleUpdates'
        $c | Should -Match 'ModuleUpdate'
    }
    It 'Imports Retry module for resilient installs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Retry.psm1'
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Install-ModuleUpdates'
    }
}
