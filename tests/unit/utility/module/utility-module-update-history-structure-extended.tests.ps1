<#
tests/unit/utility-module-update-history-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/modules/ModuleUpdateHistory.psm1'
}
Describe 'scripts/utils/dependencies/modules/ModuleUpdateHistory.psm1 structure extended scenarios' {
    It 'Documents module update history tracking utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module update history tracking utilities'
        $c | Should -Match 'ModuleUpdateHistory.psm1'
    }
    It 'Defines Save-UpdateHistory persistence helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Save-UpdateHistory'
        $c | Should -Match 'module-update-history.json'
        $c | Should -Match 'UpdatesAvailable'
    }
    It 'Limits history size and exports saver' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Select-Object -Last 100'
        $c | Should -Match 'Ensure-DirectoryExists'
        $c | Should -Match 'Export-ModuleMember'
    }
}
