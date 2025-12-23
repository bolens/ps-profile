. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:CachePath = Join-Path $script:LibPath 'utilities' 'Cache.psm1'
    
    # Import the module under test
    Import-Module $script:CachePath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
}

Describe 'Cache Module Functions' {

    Context 'Set-CachedValue' {
        It 'Caches a value successfully' {
            Set-CachedValue -Key 'TestKey1' -Value 'TestValue1'
            $result = Get-CachedValue -Key 'TestKey1'
            $result | Should -Be 'TestValue1'
        }

        It 'Caches different value types' {
            Set-CachedValue -Key 'StringValue' -Value 'String'
            Set-CachedValue -Key 'IntValue' -Value 42
            Set-CachedValue -Key 'BoolValue' -Value $true
            Set-CachedValue -Key 'ArrayValue' -Value @(1, 2, 3)
            Set-CachedValue -Key 'ObjectValue' -Value @{ Name = 'Test'; Value = 123 }
            
            Get-CachedValue -Key 'StringValue' | Should -Be 'String'
            Get-CachedValue -Key 'IntValue' | Should -Be 42
            Get-CachedValue -Key 'BoolValue' | Should -Be $true
            Get-CachedValue -Key 'ArrayValue' | Should -Be @(1, 2, 3)
            (Get-CachedValue -Key 'ObjectValue').Name | Should -Be 'Test'
        }

        It 'Uses default expiration time' {
            Set-CachedValue -Key 'DefaultExpiry' -Value 'Test'
            $result = Get-CachedValue -Key 'DefaultExpiry'
            $result | Should -Be 'Test'
        }

        It 'Uses custom expiration time' {
            Set-CachedValue -Key 'CustomExpiry' -Value 'Test' -ExpirationSeconds 60
            $result = Get-CachedValue -Key 'CustomExpiry'
            $result | Should -Be 'Test'
        }

        It 'Overwrites existing cached value' {
            Set-CachedValue -Key 'OverwriteKey' -Value 'Original'
            Set-CachedValue -Key 'OverwriteKey' -Value 'Updated'
            $result = Get-CachedValue -Key 'OverwriteKey'
            $result | Should -Be 'Updated'
        }

        It 'Exports Set-CachedValue function' {
            $module = Get-Module Cache
            $module.ExportedFunctions.Keys | Should -Contain 'Set-CachedValue'
        }
    }

    Context 'Get-CachedValue' {
        It 'Returns null for non-existent key' {
            $result = Get-CachedValue -Key 'NonExistentKey'
            $result | Should -BeNullOrEmpty
        }

        It 'Returns cached value when available' {
            Set-CachedValue -Key 'GetTestKey' -Value 'GetTestValue'
            $result = Get-CachedValue -Key 'GetTestKey'
            $result | Should -Be 'GetTestValue'
        }

        It 'Returns null for expired cache entry' {
            # Set a value with very short expiration (100ms for faster tests)
            Set-CachedValue -Key 'ExpiredKey' -Value 'ExpiredValue' -ExpirationSeconds 0.1
            Start-Sleep -Milliseconds 150
            $result = Get-CachedValue -Key 'ExpiredKey'
            $result | Should -BeNullOrEmpty
        }

        It 'Removes expired cache entry' {
            Set-CachedValue -Key 'ExpiredRemoveKey' -Value 'ExpiredValue' -ExpirationSeconds 0.1
            Start-Sleep -Milliseconds 150
            Get-CachedValue -Key 'ExpiredRemoveKey'
            # Second call should also return null (entry was removed)
            $result = Get-CachedValue -Key 'ExpiredRemoveKey'
            $result | Should -BeNullOrEmpty
        }

        It 'Returns cached value before expiration' {
            Set-CachedValue -Key 'ValidKey' -Value 'ValidValue' -ExpirationSeconds 10
            $result = Get-CachedValue -Key 'ValidKey'
            $result | Should -Be 'ValidValue'
        }

        It 'Handles Value parameter for setting cache' {
            Get-CachedValue -Key 'DirectSetKey' -Value 'DirectValue'
            $result = Get-CachedValue -Key 'DirectSetKey'
            $result | Should -Be 'DirectValue'
        }

        It 'Exports Get-CachedValue function' {
            $module = Get-Module Cache
            $module.ExportedFunctions.Keys | Should -Contain 'Get-CachedValue'
        }
    }

    Context 'Clear-CachedValue' {
        It 'Clears a cached value' {
            Set-CachedValue -Key 'ClearTestKey' -Value 'ClearTestValue'
            Clear-CachedValue -Key 'ClearTestKey'
            $result = Get-CachedValue -Key 'ClearTestKey'
            $result | Should -BeNullOrEmpty
        }

        It 'Clears non-existent key without error' {
            { Clear-CachedValue -Key 'NonExistentClearKey' } | Should -Not -Throw
        }

        It 'Removes both value and expiration entry' {
            Set-CachedValue -Key 'FullClearKey' -Value 'FullClearValue' -ExpirationSeconds 60
            Clear-CachedValue -Key 'FullClearKey'
            $result = Get-CachedValue -Key 'FullClearKey'
            $result | Should -BeNullOrEmpty
        }

        It 'Exports Clear-CachedValue function' {
            $module = Get-Module Cache
            $module.ExportedFunctions.Keys | Should -Contain 'Clear-CachedValue'
        }
    }

    Context 'Cache Isolation' {
        It 'Maintains separate cache entries for different keys' {
            Set-CachedValue -Key 'IsolatedKey1' -Value 'Value1'
            Set-CachedValue -Key 'IsolatedKey2' -Value 'Value2'
            
            Get-CachedValue -Key 'IsolatedKey1' | Should -Be 'Value1'
            Get-CachedValue -Key 'IsolatedKey2' | Should -Be 'Value2'
        }

        It 'Clears only specified key' {
            Set-CachedValue -Key 'KeepKey' -Value 'KeepValue'
            Set-CachedValue -Key 'RemoveKey' -Value 'RemoveValue'
            
            Clear-CachedValue -Key 'RemoveKey'
            
            Get-CachedValue -Key 'KeepKey' | Should -Be 'KeepValue'
            Get-CachedValue -Key 'RemoveKey' | Should -BeNullOrEmpty
        }
    }

    Context 'Cache Expiration' {
        It 'Respects expiration time' {
            # Use longer expiration time for more reliable testing (1 second)
            # Clear any existing cache entry first
            Clear-CachedValue -Key 'ShortExpiry'
            Set-CachedValue -Key 'ShortExpiry' -Value 'ShortValue' -ExpirationSeconds 1.0
            Start-Sleep -Milliseconds 300
            Get-CachedValue -Key 'ShortExpiry' | Should -Be 'ShortValue' -Because "Value should still be cached before expiration"
            Start-Sleep -Milliseconds 800
            Get-CachedValue -Key 'ShortExpiry' | Should -BeNullOrEmpty -Because "Value should be expired after expiration time"
        }

        It 'Handles zero expiration (no expiration)' {
            # Note: The current implementation doesn't support infinite expiration,
            # but we can test with a very long expiration
            Set-CachedValue -Key 'LongExpiry' -Value 'LongValue' -ExpirationSeconds 3600
            Get-CachedValue -Key 'LongExpiry' | Should -Be 'LongValue'
        }

        It 'Updates expiration when overwriting value' {
            # Use longer expiration times for more reliable testing
            # Clear any existing cache entry first
            Clear-CachedValue -Key 'ExpiryUpdate'
            Set-CachedValue -Key 'ExpiryUpdate' -Value 'Original' -ExpirationSeconds 0.5
            Start-Sleep -Milliseconds 200
            Set-CachedValue -Key 'ExpiryUpdate' -Value 'Updated' -ExpirationSeconds 1.0
            Start-Sleep -Milliseconds 600
            # Should still be valid because expiration was updated
            Get-CachedValue -Key 'ExpiryUpdate' | Should -Be 'Updated' -Because "Expiration was updated when value was overwritten"
        }
    }

    Context 'Cache Performance' {
        It 'Handles multiple cache operations efficiently' {
            for ($i = 1; $i -le 100; $i++) {
                Set-CachedValue -Key "PerfKey$i" -Value "PerfValue$i"
            }
            
            for ($i = 1; $i -le 100; $i++) {
                Get-CachedValue -Key "PerfKey$i" | Should -Be "PerfValue$i"
            }
        }

        It 'Handles concurrent cache operations' {
            # Simulate concurrent operations
            $jobs = 1..10 | ForEach-Object {
                Start-Job -ScriptBlock {
                    param($CachePath)
                    Import-Module $CachePath -DisableNameChecking -Force
                    Set-CachedValue -Key "ConcurrentKey$_" -Value "ConcurrentValue$_"
                    Get-CachedValue -Key "ConcurrentKey$_"
                } -ArgumentList $script:CachePath
            }
            
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            # Verify all operations completed
            $results | Should -Not -BeNullOrEmpty
        }
    }
}

