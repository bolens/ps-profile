<#
tests/unit/library-fragment-cache-path.tests.ps1

.SYNOPSIS
    Unit tests for FragmentCachePath helpers.
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

    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'core/PlatformPaths.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $libPath 'fragment/FragmentCachePath.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module FragmentCachePath, PlatformPaths -ErrorAction SilentlyContinue -Force
}

Describe 'Fragment cache path helpers' {
    It 'Get-FragmentCacheDbPath returns a database path' {
        $dbPath = Get-FragmentCacheDbPath
        $dbPath | Should -Not -BeNullOrEmpty
        $dbPath | Should -Match 'fragment-cache\.db$'
    }

    It 'Get-FragmentCacheDirectory returns a cache directory path' {
        $cacheDir = Get-FragmentCacheDirectory
        $cacheDir | Should -Not -BeNullOrEmpty
        $dbPath = Get-FragmentCacheDbPath
        Split-Path -Parent $dbPath | Should -Be $cacheDir
    }
}
