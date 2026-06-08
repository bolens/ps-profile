<#
tests/unit/utility-init-databases-direct-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/database/init-databases-direct.ps1'
}
Describe 'init-databases-direct.ps1 extended scenarios' {
    It 'Provides direct database initialization without full profile load' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Initialize'
    }
    It 'Imports SQLite and database schema modules' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'SqliteDatabase|Database'
    }
    It 'Uses ModuleImport for shared library access' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ModuleImport'
    }
    It 'Uses Exit-WithCode for initialization errors' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
