<#
tests/unit/library-cache-key-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for cache key stability and hash-based file keys.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/utilities/CacheKey.psm1') -Force
    $script:TempDir = New-TestTempDirectory -Prefix 'CacheKeyExtended'
}

AfterAll {
    Remove-Module CacheKey -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CacheKey extended scenarios' {
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
    }
}
