<#
tests/unit/library-cache-key-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for cache key stability, debug paths, and error handling.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-TestLibraryModule -ModulePath (Join-Path $script:RepoRoot 'scripts/lib/utilities/CacheKey.psm1')
    $script:TempDir = New-TestTempDirectory -Prefix 'CacheKeyExtended'
}

function script:Clear-CacheKeyTestEnvironment {
    foreach ($name in @('PS_PROFILE_DEBUG', 'PS_PROFILE_DEBUG_CACHEKEY')) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }
}

AfterAll {
    Clear-CacheKeyTestEnvironment
    Remove-Module CacheKey -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CacheKey extended scenarios' {
    BeforeEach { Clear-CacheKeyTestEnvironment }

    Context 'New-FileCacheKey' {
        It 'Produces identical hash keys for unchanged file content' {
            $file = Join-Path $script:TempDir 'stable-hash.txt'
            Set-Content -LiteralPath $file -Value 'stable-content' -Encoding UTF8

            $first = New-FileCacheKey -FilePath $file -UseHash
            $second = New-FileCacheKey -FilePath $file -UseHash

            $first | Should -Be $second
        }

        It 'Produces the same key for absolute and resolved paths to the same file' {
            $file = Join-Path $script:TempDir 'resolved-path.txt'
            Set-Content -LiteralPath $file -Value 'path-content' -Encoding UTF8

            $absoluteKey = New-FileCacheKey -FilePath (Resolve-Path -LiteralPath $file).Path
            $relativeKey = New-FileCacheKey -FilePath $file

            $absoluteKey.Split('_')[-1] | Should -Be $relativeKey.Split('_')[-1]
        }

        It 'Emits structured warnings when hash generation fails with debug enabled' {
            $file = Join-Path $script:TempDir 'hash-fallback.txt'
            Set-Content -LiteralPath $file -Value 'hash-fallback-content' -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            Enable-TestStructuredLogging

            $key = New-FileCacheKey -FilePath $file -UseHash -HashAlgorithm 'InvalidAlgorithm'
            $key | Should -Match '^File_hash_fallback_txt_\d+$'
        }

        It 'Logs file cache key details at debug level 3' {
            $file = Join-Path $script:TempDir 'debug-file.txt'
            Set-Content -LiteralPath $file -Value 'debug-content' -Encoding UTF8

            $env:PS_PROFILE_DEBUG = '3'
            $key = New-FileCacheKey -FilePath $file -Prefix 'DebugFile'
            $key | Should -Match '^DebugFile_debug_file_txt_\d+$'
        }

        It 'Uses structured errors for missing files when debug is enabled' {
            $missing = Join-Path $script:TempDir 'missing-file-cache.txt'
            $env:PS_PROFILE_DEBUG = '1'
            Enable-TestStructuredLogging

            { New-FileCacheKey -FilePath $missing } | Should -Throw '*File not found*'
        }
    }

    Context 'New-DirectoryCacheKey' {
        It 'Produces stable keys for the same directory path' {
            $dir = Join-Path $script:TempDir 'stable-dir'
            New-Item -ItemType Directory -Path $dir -Force | Out-Null

            $first = New-DirectoryCacheKey -DirectoryPath $dir
            $second = New-DirectoryCacheKey -DirectoryPath $dir

            $first | Should -Be $second
        }

        It 'Produces different keys for different directory paths' {
            $dirA = Join-Path $script:TempDir 'dir-a'
            $dirB = Join-Path $script:TempDir 'dir-b'
            New-Item -ItemType Directory -Path $dirA, $dirB -Force | Out-Null

            New-DirectoryCacheKey -DirectoryPath $dirA |
                Should -Not -Be (New-DirectoryCacheKey -DirectoryPath $dirB)
        }

        It 'Logs directory cache key details at debug level 3' {
            $dir = Join-Path $script:TempDir 'debug-dir'
            New-Item -ItemType Directory -Path $dir -Force | Out-Null

            $env:PS_PROFILE_DEBUG = '3'
            $key = New-DirectoryCacheKey -DirectoryPath $dir -Prefix 'DebugDir'
            $key | Should -Be 'DebugDir_debug_dir'
        }
    }

    Context 'New-CacheKey' {
        It 'Preserves component order in generated keys' {
            New-CacheKey -Prefix 'Order' -Components 'alpha', 'beta', 'gamma' |
                Should -Be 'Order_alpha_beta_gamma'
        }

        It 'Collapses duplicate separators when components contain underscores' {
            $key = New-CacheKey -Prefix 'Dup' -Components 'has__underscore', 'value'

            $key | Should -Be 'Dup_has_underscore_value'
        }

        It 'Exercises debug tracing for nested collections when cache key debug is enabled' {
            $env:PS_PROFILE_DEBUG_CACHEKEY = '1'
            $nested = @(@('nested-a', 'nested-b'), [System.Collections.Generic.List[string]]@('list-c'))
            $key = New-CacheKey -Prefix 'DebugNested' -Components $nested, 42, $true

            $key | Should -Be 'DebugNested_nested_a_nested_b_list_c_42_True'
        }

        It 'Exercises verbose debug output at PS_PROFILE_DEBUG level 3' {
            $env:PS_PROFILE_DEBUG = '3'
            $list = [System.Collections.ArrayList]::new()
            $null = $list.Add('trace-a')
            $null = $list.Add('trace-b')

            $key = New-CacheKey -Prefix 'Trace' -Components $list, 'plain'
            $key | Should -Be 'Trace_trace_a_trace_b_plain'
        }

        It 'Uses structured errors for invalid prefixes when debug is enabled' {
            $env:PS_PROFILE_DEBUG = '2'
            Enable-TestStructuredLogging

            { New-CacheKey -Prefix '   ' -Components 'Value' } | Should -Throw '*Prefix cannot be null or empty*'
        }

        It 'Skips array string representations for empty object arrays' {
            $env:PS_PROFILE_DEBUG_CACHEKEY = '1'
            $key = New-CacheKey -Prefix 'ArrayProbe' -Components @('real-value')

            $key | Should -Be 'ArrayProbe_real_value'
        }

        It 'Handles iteration failures for non-iterable custom objects as primitives' {
            $env:PS_PROFILE_DEBUG_CACHEKEY = '1'
            $key = New-CacheKey -Prefix 'Custom' -Components ([System.Guid]::NewGuid().ToString('N'))

            $key | Should -Match '^Custom_[0-9a-f]+$'
        }
    }
}
