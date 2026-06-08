<#
tests/unit/utility-module-update-checker-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/modules/ModuleUpdateChecker.psm1'
}
Describe 'scripts/utils/dependencies/modules/ModuleUpdateChecker.psm1 structure extended scenarios' {
    It 'Documents module update checking utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module update checking utilities'
        $c | Should -Match 'ModuleUpdateChecker.psm1'
    }
    It 'Defines local module discovery and update tests' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-LocalModules'
        $c | Should -Match 'Test-ModuleUpdate'
        $c | Should -Match 'Get-ModuleUpdates'
    }
    It 'Imports Retry module for resilient checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Retry.psm1'
        $c | Should -Match 'Import-CachedPowerShellDataFile'
        $c | Should -Match 'Export-ModuleMember'
    }
}
