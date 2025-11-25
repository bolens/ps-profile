#
# Caching helper tests verifying cache lifecycle behavior.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import the Cache module (Common.psm1 no longer exists)
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'Cache.psm1') -DisableNameChecking -ErrorAction Stop -Global
}

Describe 'Caching Functions' {
    AfterEach {
        foreach ($key in 'TestKey', 'TestKey2', 'TestKey3', 'TestKey_Nonexistent') {
            try {
                Clear-CachedValue -Key $key -ErrorAction SilentlyContinue
            }
            catch {
            }
        }
    }

    Context 'Cache lifecycle' {
        It 'Get-CachedValue returns null for non-existent key' {
            $result = Get-CachedValue -Key 'TestKey_Nonexistent'
            $result | Should -BeNullOrEmpty
        }

        It 'Set-CachedValue and Get-CachedValue work correctly' {
            $testValue = 'TestValue123'
            Set-CachedValue -Key 'TestKey' -Value $testValue -ExpirationSeconds 60
            $result = Get-CachedValue -Key 'TestKey'
            $result | Should -Be $testValue
        }

        It 'Clear-CachedValue removes cached value' {
            Set-CachedValue -Key 'TestKey2' -Value 'TestValue'
            Clear-CachedValue -Key 'TestKey2'
            $result = Get-CachedValue -Key 'TestKey2'
            $result | Should -BeNullOrEmpty
        }

        It 'Cached values expire after expiration time' {
            Set-CachedValue -Key 'TestKey3' -Value 'TestValue' -ExpirationSeconds 1
            Start-Sleep -Seconds 2
            $result = Get-CachedValue -Key 'TestKey3'
            $result | Should -BeNullOrEmpty
        }
    }
}
