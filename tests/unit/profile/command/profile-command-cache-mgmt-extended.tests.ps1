<#
tests/unit/profile-command-cache-mgmt-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Test-CachedCommand cache management helpers.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'CommandCache.ps1')
}

Describe 'Command cache management extended scenarios' {
    BeforeEach {
        Clear-TestCachedCommandCache | Out-Null
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    AfterEach {
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Clear-TestCachedCommandCache' {
        It 'Clears cached lookup results for repeated command probes' {
            Test-CachedCommand -Name 'pwsh' | Out-Null
            $global:TestCachedCommandCache.Count | Should -BeGreaterThan (0)

            Clear-TestCachedCommandCache | Should -Be $true
            $global:TestCachedCommandCache.Count | Should -Be 0
        }
    }

    Context 'Remove-TestCachedCommandCacheEntry' {
        It 'Forces the next lookup to refresh a single command entry' {
            $commandName = "CacheEntryTest_$([Guid]::NewGuid().ToString('N'))"
            try {
                Test-CachedCommand -Name $commandName | Should -Be $false

                Set-Item -Path "Function:\global:$commandName" -Value { 'cached' } -Force
                Test-CachedCommand -Name $commandName | Should -Be $false -Because 'stale false cache should remain until entry is removed'

                Remove-TestCachedCommandCacheEntry -Name $commandName | Should -Be $true
                Test-CachedCommand -Name $commandName | Should -Be $true -Because 'lookup should refresh after cache entry removal'
            }
            finally {
                Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
                Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses case-insensitive cache keys when removing entries' {
            $commandName = "CacheCase_$([Guid]::NewGuid().ToString('N'))"
            try {
                Test-CachedCommand -Name $commandName | Out-Null
                Set-Item -Path "Function:\global:$commandName" -Value { 'cached' } -Force
                Test-CachedCommand -Name $commandName.ToUpperInvariant() | Out-Null

                Remove-TestCachedCommandCacheEntry -Name $commandName.ToLowerInvariant() | Should -Be $true
                Test-CachedCommand -Name $commandName | Should -Be $true
            }
            finally {
                Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
                Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns false for whitespace command names' {
            Remove-TestCachedCommandCacheEntry -Name '   ' | Should -Be $false
        }
    }

    Context 'Test-HasCommand compatibility wrapper' {
        It 'Delegates availability checks to Test-CachedCommand' {
            Set-TestCommandAvailabilityState -CommandName 'pwsh' -Available $true
            Test-HasCommand -Name 'pwsh' | Should -Be $true
        }
    }
}
