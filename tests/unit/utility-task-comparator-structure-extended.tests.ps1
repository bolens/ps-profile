<#
tests/unit/utility-task-comparator-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/modules/TaskComparator.psm1'
}
Describe 'scripts/utils/task-parity/modules/TaskComparator.psm1 structure extended scenarios' {
    It 'Documents task comparison utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Compares task definitions across multiple task runner files'
        $c | Should -Match 'TaskComparator.psm1'
    }
    It 'Defines Compare-Tasks and Normalize-Command helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Compare-Tasks'
        $c | Should -Match 'Normalize-Command'
        $c | Should -Match 'MissingTasks'
    }
    It 'Imports TaskParityUtilities module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TaskParityUtilities.psm1'
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'command differences'
    }
}
