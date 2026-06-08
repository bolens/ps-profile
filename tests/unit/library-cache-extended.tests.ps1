<#
tests/unit/library-cache-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Cache falsy values and clear behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'utilities' 'Cache.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
}

Describe 'Cache extended scenarios' {
    BeforeEach {
        Clear-CachedValue -Key 'CacheExtendedFalse' -ErrorAction SilentlyContinue
        Clear-CachedValue -Key 'CacheExtendedZero' -ErrorAction SilentlyContinue
        Clear-CachedValue -Key 'CacheExtendedEmptyHash' -ErrorAction SilentlyContinue
        Clear-CachedValue -Key 'CacheExtendedClearMe' -ErrorAction SilentlyContinue
    }

    Context 'Get-CachedValue' {
        It 'Distinguishes cached false from missing entries' {
            Set-CachedValue -Key 'CacheExtendedFalse' -Value $false

            $result = Get-CachedValue -Key 'CacheExtendedFalse'
            ($null -eq $result) | Should -Be $false
            $result | Should -Be $false
        }

        It 'Retrieves cached zero values' {
            Set-CachedValue -Key 'CacheExtendedZero' -Value 0

            Get-CachedValue -Key 'CacheExtendedZero' | Should -Be 0
        }

        It 'Retrieves cached empty hashtables' {
            Set-CachedValue -Key 'CacheExtendedEmptyHash' -Value @{}

            $result = Get-CachedValue -Key 'CacheExtendedEmptyHash'
            $result | Should -BeOfType [hashtable]
            @($result.Keys).Count | Should -Be 0
        }

        It 'Clears entries through Get-CachedValue -Clear' {
            Set-CachedValue -Key 'CacheExtendedClearMe' -Value 'temporary'
            Get-CachedValue -Key 'CacheExtendedClearMe' -Clear | Out-Null

            Get-CachedValue -Key 'CacheExtendedClearMe' | Should -BeNullOrEmpty
        }

        It 'Expires entries immediately when ExpirationSeconds is zero' {
            Set-CachedValue -Key 'CacheExtendedZeroExpiry' -Value 'short-lived' -ExpirationSeconds 0
            Start-Sleep -Milliseconds 50

            Get-CachedValue -Key 'CacheExtendedZeroExpiry' | Should -BeNullOrEmpty
        }
    }
}
