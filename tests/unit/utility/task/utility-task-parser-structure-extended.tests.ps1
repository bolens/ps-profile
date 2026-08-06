<#
tests/unit/utility-task-parser-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/task-parity/modules/TaskParser.psm1'
    Import-Module $script:Fragment -DisableNameChecking -Force
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

    It 'parses variadic recipes, dependencies, attributes, and recipe bodies independently' {
        $justfile = New-TestTempFile -Prefix 'TaskParserJustfile' -Extension '.just'
        Set-Content -LiteralPath $justfile -Value @'
# Variadic recipe
test *ARGS:
    pwsh test.ps1 {{ ARGS }}

# Dependency recipe
quality-check lint test:
    echo done

[private] helper name='value':
    echo {{ name }}
'@ -Encoding UTF8

        $tasks = Get-TasksFromJustfile -FilePath $justfile

        $tasks.Count | Should -Be 3
        $tasks.test.Command | Should -Be 'pwsh test.ps1 {{ ARGS }}'
        $tasks.'quality-check'.Command | Should -Be 'echo done'
        $tasks.helper.Command | Should -Be 'echo {{ name }}'
        $tasks.test.Description | Should -Be 'Variadic recipe'
    }

    It 'parses every recipe in the repository justfile without concatenating commands' {
        $justfile = Join-Path $script:TestRepoRoot 'justfile'
        $tasks = Get-TasksFromJustfile -FilePath $justfile

        $tasks.Count | Should -BeGreaterOrEqual 80
        $tasks.'db-init'.Command | Should -Be 'pwsh -NoProfile -File scripts/utils/database/initialize-databases.ps1'
        $tasks.'drift-status'.Command | Should -Be 'drift status'
        $tasks.'test-unit-batch'.Command | Should -Not -Match 'test-conversion'
    }
}
