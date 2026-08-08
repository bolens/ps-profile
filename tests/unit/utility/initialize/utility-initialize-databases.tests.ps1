<#
tests/unit/utility-initialize-databases.tests.ps1

.SYNOPSIS
    Behavioral unit tests for initialize-databases.ps1 execution.
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
    $script:InitializeDatabasesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'initialize-databases.ps1'
    $script:SqliteAvailable = [bool](Get-Command sqlite3 -ErrorAction SilentlyContinue)
    $script:CacheDir = New-TestTempDirectory -Prefix 'InitializeDatabasesCache'
    $script:InitializeResult = Invoke-TestScriptFile -ScriptPath $script:InitializeDatabasesScript -EnvironmentVariables @{
        PS_PROFILE_CACHE_DIR = $script:CacheDir
    }
    $ConfirmPreference = 'None'
}

Describe 'initialize-databases.ps1 execution' {
    It 'Runs initialization and reports SQLite availability' {
        $script:InitializeResult.Output | Should -Match 'Initializing SQLite Databases'
        $script:InitializeResult.Output | Should -Match 'SQLite'
        $script:InitializeResult.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Exits with setup error when SQLite is unavailable' {
        if ($script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is installed on this system'
            return
        }

        $script:InitializeResult.Output | Should -Match 'SQLite is not available'
        $script:InitializeResult.ExitCode | Should -BeIn @(2, 3)
    }

    It 'Uses an isolated cache directory when PS_PROFILE_CACHE_DIR is set' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $script:InitializeResult.Output | Should -Match ([regex]::Escape($script:CacheDir))
        $script:InitializeResult.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }
}
