
Describe 'Fragment cache path helpers' {
    BeforeAll {
        $script:FragmentCachePathModule = Join-Path $PSScriptRoot '..\..\scripts\lib\fragment\FragmentCachePath.psm1'
        if (-not (Test-Path -LiteralPath $script:FragmentCachePathModule)) {
            throw "FragmentCachePath module not found at: $script:FragmentCachePathModule"
        }

        Import-Module $script:FragmentCachePathModule -DisableNameChecking -Force
    }

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
