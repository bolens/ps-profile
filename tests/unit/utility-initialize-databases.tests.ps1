<#
tests/unit/utility-initialize-databases.tests.ps1

.SYNOPSIS
    Behavioral unit tests for initialize-databases.ps1 execution.
#>

function global:Invoke-InitializeDatabasesScript {
    param(
        [string[]]$ArgumentList = @()
    )

    $output = & pwsh -NoProfile -File $script:InitializeDatabasesScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:InitializeDatabasesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'initialize-databases.ps1'
    $script:SqliteAvailable = [bool](Get-Command sqlite3 -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'initialize-databases.ps1 execution' {
    It 'Runs initialization and reports SQLite availability' {
        $result = Invoke-InitializeDatabasesScript

        $result.Output | Should -Match 'Initializing SQLite Databases'
        $result.Output | Should -Match 'SQLite'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }

    It 'Exits with setup error when SQLite is unavailable' {
        if ($script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is installed on this system'
            return
        }

        $result = Invoke-InitializeDatabasesScript
        $result.Output | Should -Match 'SQLite is not available'
        $result.ExitCode | Should -BeIn @(2, 3)
    }
}
