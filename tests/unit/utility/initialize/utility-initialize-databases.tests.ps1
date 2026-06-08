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

    It 'Uses an isolated cache directory when PS_PROFILE_CACHE_DIR is set' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $cacheDir = New-TestTempDirectory -Prefix 'InitializeDatabasesCache'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:InitializeDatabasesScript -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.Output | Should -Match ([regex]::Escape($cacheDir))
            $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
        }
        finally {
            if (Test-Path -LiteralPath $cacheDir) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
