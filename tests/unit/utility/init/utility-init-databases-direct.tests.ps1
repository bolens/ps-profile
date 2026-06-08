<#
tests/unit/utility-init-databases-direct.tests.ps1

.SYNOPSIS
    Behavioral unit tests for init-databases-direct.ps1 with an isolated cache directory.
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
    $script:InitDatabasesDirectScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'init-databases-direct.ps1'
    $script:SqliteAvailable = [bool](Get-Command sqlite3 -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'init-databases-direct.ps1 execution' {
    It 'Creates SQLite database files in an isolated cache directory' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $cacheDir = New-TestTempDirectory -Prefix 'InitDatabasesDirectCache'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:InitDatabasesDirectScript -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'All databases initialized successfully'
            Get-ChildItem -LiteralPath $cacheDir -Filter '*.db' | Measure-Object | Select-Object -ExpandProperty Count |
                Should -BeGreaterOrEqual 3
        }
        finally {
            if (Test-Path -LiteralPath $cacheDir) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Reports SQLite not found when sqlite3 is unavailable on PATH' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed; cannot verify missing-sqlite path'
            return
        }

        $emptyPathDir = New-TestTempDirectory -Prefix 'InitDbMissingSqlitePath'
        $pwshExe = (Get-Command pwsh -ErrorAction Stop).Source
        try {
            $output = & $pwshExe -NoProfile -Command "`$env:PATH='$emptyPathDir'; & '$($script:InitDatabasesDirectScript -replace '''', '''''')'" 2>&1 | Out-String
            $exitCode = $LASTEXITCODE

            $exitCode | Should -BeIn @(1, 2)
            $output | Should -Match 'SQLite not found'
        }
        finally {
            if (Test-Path -LiteralPath $emptyPathDir) {
                Remove-Item -LiteralPath $emptyPathDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
