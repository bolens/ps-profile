<#
tests/unit/utility-task-parser-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/modules/TaskParser.psm1'
}
Describe 'scripts/utils/task-parity/modules/TaskParser.psm1 structure extended scenarios' {
    It 'Documents multi-format task parser utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Parses task definitions from various task runner file formats'
        $c | Should -Match 'TaskParser.psm1'
    }
    It 'Defines parsers for common task runner files' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TasksFromTaskfile'
        $c | Should -Match 'Get-TasksFromMakefile'
        $c | Should -Match 'Get-TasksFromPackageJson'
        $c | Should -Match 'Get-TasksFromJustfile'
    }
    It 'Imports TaskParityUtilities and supports VS Code tasks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TaskParityUtilities.psm1'
        $c | Should -Match 'Get-TasksFromTasksJson'
        $c | Should -Match 'Resolve-CanonicalTaskNameFromVsCodeTask'
    }
}
