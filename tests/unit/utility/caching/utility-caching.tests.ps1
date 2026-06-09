#
# Caching helper tests verifying cache lifecycle behavior.
#

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
    # Import the Cache module (Common.psm1 no longer exists)
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'utilities' 'Cache.psm1') -DisableNameChecking -ErrorAction Stop -Global
}

Describe 'Caching Functions' {
    AfterEach {
        foreach ($key in 'TestKey', 'TestKey2', 'TestKey3', 'TestKey_Nonexistent') {
                        Clear-CachedValue -Key $key -ErrorAction SilentlyContinue
        }
        catch {
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
            Set-CachedValue -Key 'TestKey3' -Value 'TestValue' -ExpirationSeconds 0.1
            Start-Sleep -Milliseconds 150
            $result = Get-CachedValue -Key 'TestKey3'
            $result | Should -BeNullOrEmpty
        }
    }
}
