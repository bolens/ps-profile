<#
tests/unit/utility-check-task-parity-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-task-parity.ps1 task runner parity checker.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TaskParityScript = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/check-task-parity.ps1'
}

Describe 'check-task-parity.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Generate and TargetFile parameters' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match '\.PARAMETER Generate'
            $content | Should -Match 'TargetFile'
        }

        It 'Compares Taskfile Makefile package.json justfile and tasks.json' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'Taskfile\.yml'
            $content | Should -Match 'Makefile'
            $content | Should -Match 'package\.json'
        }
    }

    Context 'Parity analysis' {
        It 'Reports tasks missing across runner files' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'missing in others'
            $content | Should -Match 'Command differences'
        }

        It 'Imports TaskParityUtilities module helpers' {
            $content = Get-Content -LiteralPath $script:TaskParityScript -Raw
            $content | Should -Match 'TaskParityUtilities'
        }
    }
}
