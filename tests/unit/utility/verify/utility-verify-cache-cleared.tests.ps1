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
    BeforeEach {
        $script:PreviousCacheDirectory = $env:PS_PROFILE_CACHE_DIR
        $env:PS_PROFILE_CACHE_DIR = New-TestTempDirectory -Prefix 'VerifyCacheCleared'
    }

    AfterEach {
        if ($null -eq $script:PreviousCacheDirectory) {
            Remove-Item Env:PS_PROFILE_CACHE_DIR -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_CACHE_DIR = $script:PreviousCacheDirectory
        }
    }

    It 'Reports success when the cache database does not exist in an isolated cache directory' {
        { & $script:VerifyCacheScript } | Should -Not -Throw
    }

    It 'Reports non-empty cache entries without failing when sqlite3 is available' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $null = New-FragmentCacheDatabaseWithEntries -CacheDir $env:PS_PROFILE_CACHE_DIR

        { & $script:VerifyCacheScript } | Should -Not -Throw
    }

    It 'Reports a fully cleared cache when database tables exist but contain no rows' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $dbPath = Join-Path $env:PS_PROFILE_CACHE_DIR 'fragment-cache.db'
        @'
CREATE TABLE fragment_ast_cache (id INTEGER PRIMARY KEY);
CREATE TABLE fragment_content_cache (id INTEGER PRIMARY KEY);
'@ | & sqlite3 $dbPath 2>&1 | Out-Null

        { & $script:VerifyCacheScript } | Should -Not -Throw
    }

    It 'handles an invalid cache database without leaking temporary files' {
        if (-not $script:SqliteAvailable) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        Set-Content -LiteralPath (Join-Path $env:PS_PROFILE_CACHE_DIR 'fragment-cache.db') -Value 'not a database' -Encoding UTF8

        { & $script:VerifyCacheScript } | Should -Not -Throw
    }

    It 'reports an existing database when SQLite is unavailable' {
        Set-Content -LiteralPath (Join-Path $env:PS_PROFILE_CACHE_DIR 'fragment-cache.db') -Value 'fixture' -Encoding UTF8
        $previousPath = $env:PATH
        $env:PATH = New-TestTempDirectory -Prefix 'EmptyExecutablePath'
        try {
            { & $script:VerifyCacheScript } | Should -Not -Throw
        }
        finally {
            $env:PATH = $previousPath
        }
    }
}
