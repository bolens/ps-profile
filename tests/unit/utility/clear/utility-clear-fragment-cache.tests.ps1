<#
tests/unit/utility-clear-fragment-cache.tests.ps1

.SYNOPSIS
    Behavioral unit tests for clear-fragment-cache.ps1 dry-run execution.
#>

function global:Invoke-ClearFragmentCacheScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:ClearCacheScript @ArgumentList 2>&1 | Out-String
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
    $script:ClearCacheScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'clear-fragment-cache.ps1'
    $ConfirmPreference = 'None'
}

Describe 'clear-fragment-cache.ps1 execution' {
    It 'WhatIf previews cache clearing without failing' {
        $result = Invoke-ClearFragmentCacheScript -ArgumentList @('-WhatIf')
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match '\[WhatIf\]'
        $result.Output | Should -Match 'Would attempt to clear'
    }

    It 'Deletes the cache database in an isolated cache directory' {
        if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $cacheDir = New-TestTempDirectory -Prefix 'ClearFragmentCacheApply'
            $dbPath = Join-Path $cacheDir 'fragment-cache.db'
            'CREATE TABLE fragment_ast_cache (id INTEGER PRIMARY KEY);' | sqlite3 $dbPath 2>&1 | Out-Null
            Test-Path -LiteralPath $dbPath | Should -Be $true

            $result = Invoke-TestScriptFile -ScriptPath $script:ClearCacheScript -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Deleted cache database|cache database not found'
            Test-Path -LiteralPath $dbPath | Should -Be $false
    }

    It 'Clears only in-memory caches when IncludeDatabase is disabled' {
        if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'sqlite3 is not installed'
            return
        }

        $cacheDir = New-TestTempDirectory -Prefix 'ClearFragmentCacheMemoryOnly'
            $dbPath = Join-Path $cacheDir 'fragment-cache.db'
            'CREATE TABLE fragment_ast_cache (id INTEGER PRIMARY KEY);' | sqlite3 $dbPath 2>&1 | Out-Null
            Test-Path -LiteralPath $dbPath | Should -Be $true

            $result = Invoke-TestScriptFile -ScriptPath $script:ClearCacheScript -ArgumentList @(
                '-IncludeDatabase:$false'
            ) -EnvironmentVariables @{
                PS_PROFILE_CACHE_DIR = $cacheDir
            }

            $result.ExitCode | Should -BeIn @(0, 1)
            Test-Path -LiteralPath $dbPath | Should -Be $true
            $result.Output | Should -Match 'FragmentContentCache|FragmentAstCache|No cache components were cleared|cache clearing completed'
    }
}
