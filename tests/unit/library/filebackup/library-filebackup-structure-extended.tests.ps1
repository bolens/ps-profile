<#
tests/unit/library-filebackup-structure-extended.tests.ps1

.SYNOPSIS
    Structure tests for FileBackup.psm1 and related gitignore configuration.
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
    $script:ModulePath = Join-Path $script:TestRepoRoot 'scripts' 'lib' 'file' 'FileBackup.psm1'
    $script:GitIgnorePath = Join-Path $script:TestRepoRoot '.gitignore'
}

Describe 'FileBackup.psm1 structure extended scenarios' {
    It 'Documents backup, restore, and prune responsibilities' {
        $content = Get-Content -LiteralPath $script:ModulePath -Raw
        $content | Should -Match 'Repository file backup, restore, and retention utilities'
        $content | Should -Match '\.backups'
    }

    It 'Exports backup lifecycle functions' {
        $content = Get-Content -LiteralPath $script:ModulePath -Raw
        $content | Should -Match 'function New-FileBackup'
        $content | Should -Match 'function Restore-FileBackup'
        $content | Should -Match 'function Remove-OldFileBackups'
        $content | Should -Match 'function Get-FileBackups'
        $content | Should -Match 'function Get-RepoBackupRoot'
        $content | Should -Match 'function Get-RepoBackupCategoryPath'
        $content | Should -Match 'Export-ModuleMember'
    }

    It 'Writes metadata files for restore path resolution' {
        $content = Get-Content -LiteralPath $script:ModulePath -Raw
        $content | Should -Match '\.meta\.json'
        $content | Should -Match 'SourcePath'
        $content | Should -Match 'CreatedAt'
    }

    It 'Uses millisecond timestamps to avoid backup filename collisions' {
        $content = Get-Content -LiteralPath $script:ModulePath -Raw
        $content | Should -Match 'yyyyMMddHHmmssfff'
    }
}

Describe 'Repository backup gitignore configuration' {
    It 'Ignores script-created backups under .backups/' {
        $content = Get-Content -LiteralPath $script:GitIgnorePath -Raw
        $content | Should -Match '\.backups/'
        $content | Should -Match 'FileBackup\.psm1'
    }
}
