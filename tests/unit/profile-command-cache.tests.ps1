<#
tests/unit/profile-command-cache.tests.ps1

.SYNOPSIS
    Unit tests for CommandCache bootstrap helpers.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot

    $bootstrapPath = Join-Path $script:TestRepoRoot 'profile.d/bootstrap.ps1'
    if (-not (Test-Path -LiteralPath $bootstrapPath)) {
        throw "Bootstrap not found: $bootstrapPath"
    }

    . $bootstrapPath
}

Describe 'CommandCache helpers' {
    Context 'Get-ExternalCommandLookupNames' {
        It 'Returns go-yq alias chain for yq lookups' {
            $names = Get-ExternalCommandLookupNames -Name 'yq'
            $names[0] | Should -Be 'go-yq'
            $names | Should -Contain 'yq'
        }

        It 'Returns normalized name for other commands' {
            $names = Get-ExternalCommandLookupNames -Name '  git  '
            $names | Should -Be @('git')
        }
    }

    Context 'Get-CachedExternalCommand' {
        AfterEach {
            Set-TestCommandAvailabilityState -CommandName 'cached-ext-cmd-test' -Available $false -ErrorAction SilentlyContinue
        }

        It 'Prefers test mock commands over host binaries' {
            Set-TestCommandAvailabilityState -CommandName 'cached-ext-cmd-test' -Available $true
            $cmd = Get-CachedExternalCommand -Name 'cached-ext-cmd-test'
            $cmd.CommandType | Should -Be 'Function'
            $cmd.Name | Should -Be 'cached-ext-cmd-test'
        }

        It 'Returns null when command is unavailable' {
            Get-CachedExternalCommand -Name 'definitely-missing-cmd-xyz-999' | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-TestCachedCommandCacheEntry' {
        It 'Removes a single cache entry so the next lookup refreshes' {
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

        It 'Returns false for blank names' {
            Remove-TestCachedCommandCacheEntry -Name '   ' | Should -Be $false
        }
    }

    Context 'Test-HasCommand compatibility wrapper' {
        It 'Delegates to Test-CachedCommand' {
            $commandName = "HasCommandWrapper_$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-Item -Path "Function:\global:$commandName" -Value { 'ok' } -Force
                Test-HasCommand -Name $commandName | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
                Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    Context 'Test-IsMikefarahYqExecutable' {
        It 'Returns false for whitespace executable paths' {
            Test-IsMikefarahYqExecutable -Executable '   ' | Should -Be $false
        }

        It 'Detects mikefarah yq via stubbed version output' {
            $stubName = "yq-stub-$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-Item -Path "Function:\global:$stubName" -Value {
                    if ($args -contains '--version') {
                        Write-Output 'yq version github.com/mikefarah/yq/v4'
                        return
                    }
                    Write-Output 'help'
                } -Force

                Test-IsMikefarahYqExecutable -Executable $stubName | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\global:$stubName" -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
