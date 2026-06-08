<#
tests/unit/utility-verify-cache-cleared.tests.ps1

.SYNOPSIS
    Behavioral unit tests for verify-cache-cleared.ps1 with an isolated cache directory.
#>

function global:New-FragmentCacheDatabaseWithEntries {
    param(
        [Parameter(Mandatory)]
        [string]$CacheDir
    )

    $dbPath = Join-Path $CacheDir 'fragment-cache.db'
    $schema = @'
CREATE TABLE fragment_ast_cache (id INTEGER PRIMARY KEY);
INSERT INTO fragment_ast_cache DEFAULT VALUES;
CREATE TABLE fragment_content_cache (id INTEGER PRIMARY KEY);
INSERT INTO fragment_content_cache DEFAULT VALUES;
'@
    $schema | & sqlite3 $dbPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to seed fragment-cache.db at $dbPath"
    }

    return $dbPath
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
    $script:VerifyCacheScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'verify-cache-cleared.ps1'
    $script:SqliteAvailable = [bool](Get-Command sqlite3 -ErrorAction SilentlyContinue)
    $ConfirmPreference = 'None'
}

Describe 'verify-cache-cleared.ps1 execution' {
    It 'Reports success when the cache database does not exist in an isolated cache directory' {
        $cacheDir = New-TestTempDirectory -Prefix 'VerifyCacheCleared'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:VerifyCacheScript -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Database file does not exist|cache is cleared'
        }
        finally {
            if (Test-Path -LiteralPath $cacheDir) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Reports non-empty cache entries without failing when sqlite3 is available' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $cacheDir = New-TestTempDirectory -Prefix 'VerifyCacheNotCleared'
        try {
            $null = New-FragmentCacheDatabaseWithEntries -CacheDir $cacheDir
            $result = Invoke-TestScriptFile -ScriptPath $script:VerifyCacheScript -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Database file exists'
            $result.Output | Should -Match 'Cache is NOT fully cleared|AST cache entries: 1|Content cache entries: 1'
        }
        finally {
            if (Test-Path -LiteralPath $cacheDir) {
                Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
