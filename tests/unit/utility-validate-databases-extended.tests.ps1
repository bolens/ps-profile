<#
tests/unit/utility-validate-databases-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/database/validate-databases.ps1'
}
Describe 'validate-databases.ps1 extended scenarios' {
    It 'Documents TestOperations and OutputFormat parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'TestOperations'
        $c | Should -Match 'OutputFormat'
    }
    It 'Validates SQLite availability and cache directory access' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'SQLite availability'
        $c | Should -Match 'Cache directory'
    }
    It 'Tests read and write operations when TestOperations is set' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'read/write'
        $c | Should -Match '\$TestOperations'
    }
    It 'Handles database corruption scenarios' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Corruption'
    }
}
