<#
tests/unit/profile-command-cache-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CommandCache bootstrap helpers.
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

Describe 'CommandCache extended scenarios' {
    Context 'AssumedAvailableCommands' {
        AfterEach {
            if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
                Clear-TestCommandAvailabilityStub
            }
        }

        It 'Treats assumed commands as available without probing providers' {
            $commandName = "assumed-cmd-$([Guid]::NewGuid().ToString('N'))"
            Set-TestCommandAvailabilityState -CommandName $commandName -Available $true

            Test-CachedCommand -Name $commandName | Should -Be $true
            Get-CachedExternalCommand -Name $commandName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ExternalCommandLookupNames' {
        It 'Returns only normalized name for non-yq commands' {
            Get-ExternalCommandLookupNames -Name '  docker  ' | Should -Be @('docker')
        }
    }

    Context 'Clear-TestCachedCommandCache' {
        It 'Allows stale cache entries to refresh after the cache is cleared' {
            $commandName = "CacheClearTest_$([Guid]::NewGuid().ToString('N'))"
            try {
                Test-CachedCommand -Name $commandName | Should -Be $false

                Set-Item -Path "Function:\global:$commandName" -Value { 'cached' } -Force
                Test-CachedCommand -Name $commandName | Should -Be $false -Because 'stale false cache should remain until cache is cleared'

                Clear-TestCachedCommandCache | Should -Be $true
                Test-CachedCommand -Name $commandName | Should -Be $true -Because 'lookup should refresh after cache clear'
            }
            finally {
                Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
                Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    Context 'Invoke-CachedYqCommand' {
        It 'Throws when no yq executable is available' {
            Set-TestCommandAvailabilityState -CommandName 'yq' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'go-yq' -Available $false

            { Invoke-CachedYqCommand --version } | Should -Throw '*yq command not found*'
        }
    }
}
