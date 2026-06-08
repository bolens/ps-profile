<#
tests/unit/profile-command-cache-external-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for external command cache helpers.
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

Describe 'CommandCache external lookup extended scenarios' {
    Context 'Remove-TestCachedCommandCacheEntry' {
        AfterEach {
            Clear-TestCachedCommandCache | Out-Null
        }

        It 'Returns false when the cache is empty' {
            Clear-TestCachedCommandCache | Out-Null
            Remove-TestCachedCommandCacheEntry -Name 'missing-entry' | Should -Be $false
        }

        It 'Removes a cached entry so the next lookup refreshes' {
            $commandName = "CacheEntryTest_$([Guid]::NewGuid().ToString('N'))"
            try {
                Test-CachedCommand -Name $commandName | Should -Be $false

                Set-Item -Path "Function:\$commandName" -Value { 'cached' } -Force
                Remove-TestCachedCommandCacheEntry -Name $commandName | Out-Null
                Test-CachedCommand -Name $commandName | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
                Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    Context 'Test-HasCommand' {
        AfterEach {
            if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
                Clear-TestCommandAvailabilityStub
            }
            Clear-TestCachedCommandCache | Out-Null
        }

        It 'Delegates to Test-CachedCommand for available commands' {
            $commandName = "HasCommandTest_$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-TestCommandAvailabilityState -CommandName $commandName -Available $true
                Set-Item -Path "Function:\$commandName" -Value { 'ok' } -Force
                Clear-TestCachedCommandCache | Out-Null

                Test-HasCommand -Name $commandName | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns false for commands that are not available' {
            Test-HasCommand -Name 'totally-missing-command-xyz' | Should -Be $false
        }
    }

    Context 'Get-CachedExternalCommand' {
        AfterEach {
            if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
                Clear-TestCommandAvailabilityStub
            }
            Clear-TestCachedCommandCache | Out-Null
        }

        It 'Returns a command object for registered mock commands' {
            $commandName = "ExternalCmdTest_$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-TestCommandAvailabilityState -CommandName $commandName -Available $true
                Set-Item -Path "Function:\$commandName" -Value { 'external' } -Force
                Clear-TestCachedCommandCache | Out-Null

                $command = Get-CachedExternalCommand -Name $commandName
                $command | Should -Not -BeNullOrEmpty
                $command.Name | Should -Be $commandName
            }
            finally {
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns null when the command is not available' {
            Get-CachedExternalCommand -Name 'missing-external-command-xyz' | Should -BeNullOrEmpty
        }
    }
}
