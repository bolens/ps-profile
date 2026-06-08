<#
tests/unit/utility-add-validate-task-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/add-validate-task.ps1'
}
Describe 'add-validate-task.ps1 extended scenarios' {
    It 'Uses TaskGenerator Add-MissingTasks for parity updates' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'TaskGenerator\.psm1'
        $c | Should -Match 'Add-MissingTasks'
    }
    It 'Adds validate task invoking validate-profile.ps1' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'validate-profile\.ps1'
        $c | Should -Match "'validate'"
    }
    It 'Targets Taskfile Makefile package.json justfile and tasks.json' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Taskfile'
        $c | Should -Match 'Makefile'
        $c | Should -Match 'package\.json'
    }
    It 'Skips files that already define the validate task' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'already exists'
    }
}
