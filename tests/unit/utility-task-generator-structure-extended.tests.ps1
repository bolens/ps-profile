<#
tests/unit/utility-task-generator-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/modules/TaskGenerator.psm1'
}
Describe 'scripts/utils/task-parity/modules/TaskGenerator.psm1 structure extended scenarios' {
    It 'Documents missing task generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Generates missing tasks in task runner files'
        $c | Should -Match 'TaskGenerator.psm1'
    }
    It 'Defines Add-MissingTasks and format-specific writers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Add-MissingTasks'
        $c | Should -Match 'Format-TaskfileTask'
        $c | Should -Match 'Format-MakefileTask'
        $c | Should -Match 'Format-JustfileTask'
    }
    It 'Updates package.json and tasks.json task files' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Update-PackageJsonTasks'
        $c | Should -Match 'Update-TasksJsonTasks'
        $c | Should -Match 'Export-ModuleMember'
    }
}
