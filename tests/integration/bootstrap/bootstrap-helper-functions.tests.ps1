

Describe 'Bootstrap Helper Functions' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
                throw "Get-TestPath returned null or empty value for BootstrapPath"
            }
            if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
                throw "Bootstrap file not found at: $script:BootstrapPath"
            }
            . $script:BootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to load bootstrap in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Bootstrap helper functions' {
        It 'Test-CachedCommand caches command availability results' {
            $commandName = "TestCachedCommand_{0}" -f (Get-Random)
            $cleanupNeeded = $false
            
            try {
                Remove-TestCachedCommandCacheEntry -Name $commandName | Out-Null
                $scriptBlock = { 'cached' }
                Set-Item -Path "Function:\$commandName" -Value $scriptBlock -Force
                Set-Item -Path "Function:\global:$commandName" -Value $scriptBlock -Force
                $cleanupNeeded = $true

                $result1 = Test-CachedCommand -Name $commandName
                $result2 = Test-CachedCommand -Name $commandName
                $result1 | Should -Be $result2 -Because "cached results should be consistent"
                $result1 | Should -Be $true -Because "command should be available after creation"
            }
            catch {
                $errorDetails = @{
                    Message     = $_.Exception.Message
                    CommandName = $commandName
                    Category    = $_.CategoryInfo.Category
                }
                Write-Error "Test-CachedCommand caching test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
                    Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Test-CachedCommand returns false for non-existent commands' {
            $nonExistent = "TestCommand_$(Get-Random)_$(Get-Random)"
            $result = Test-CachedCommand -Name $nonExistent
            $result | Should -Be $false
        }

        It 'Test-CachedCommand checks function provider first' {
            $testFuncName = "TestFunc_$(Get-Random)"
            $cleanupNeeded = $false
            
            try {
                $scriptBlock = { 'test' }
                Set-Item -Path "Function:\$testFuncName" -Value $scriptBlock -Force
                Set-Item -Path "Function:\global:$testFuncName" -Value $scriptBlock -Force
                $cleanupNeeded = $true

                Test-Path -LiteralPath "Function:\$testFuncName" | Should -BeTrue -Because "function should exist in function provider"
                $result = Test-CachedCommand -Name $testFuncName
                $result | Should -Be $true -Because "Test-CachedCommand should detect function provider first"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FunctionName = $testFuncName
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Test-CachedCommand function provider test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Item -Path "Function:\$testFuncName" -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "Function:\global:$testFuncName" -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Test-CachedCommand checks alias provider' {
            $testAliasName = "TestAlias_$(Get-Random)"
            $cleanupNeeded = $false
            
            try {
                $aliasResult = Set-AgentModeAlias -Name $testAliasName -Target 'Get-Command'
                if (-not $aliasResult) {
                    throw "Failed to create test alias: $testAliasName"
                }
                $cleanupNeeded = $true

                Get-Alias -Name $testAliasName -ErrorAction Stop | Should -Not -BeNullOrEmpty -Because "alias should exist after creation"
                $result = Test-CachedCommand -Name $testAliasName
                $result | Should -Be $true -Because "Test-CachedCommand should detect alias provider"
            }
            catch {
                $errorDetails = @{
                    Message   = $_.Exception.Message
                    AliasName = $testAliasName
                    Category  = $_.CategoryInfo.Category
                }
                Write-Error "Test-CachedCommand alias provider test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Alias -Name $testAliasName -Scope Global -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Test-CachedCommand returns false for non-existent commands' {
            $nonExistent = "TestCommand_$(Get-Random)_$(Get-Random)"
            $result = Test-CachedCommand -Name $nonExistent
            $result | Should -Be $false
        }

        It 'Clear-TestCachedCommandCache clears all cached entries' {
            $commandName1 = "TestClearCache1_$(Get-Random)"
            $commandName2 = "TestClearCache2_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                # Add some cached entries
                $result1 = Add-AssumedCommand -Name $commandName1
                $result2 = Add-AssumedCommand -Name $commandName2
                if (-not $result1 -or -not $result2) {
                    throw "Failed to add assumed commands for cache test"
                }
                $cleanupNeeded = $true

                # Verify they are cached
                Test-CachedCommand -Name $commandName1 | Should -Be $true -Because "command should be cached after being assumed"
                Test-CachedCommand -Name $commandName2 | Should -Be $true -Because "command should be cached after being assumed"

                # Clear cache
                Clear-TestCachedCommandCache

                # Verify cache is cleared (should still be assumed but not cached)
                Test-CachedCommand -Name $commandName1 | Should -Be $true -Because "command should still be assumed after cache clear"
                Test-CachedCommand -Name $commandName2 | Should -Be $true -Because "command should still be assumed after cache clear"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Command1 = $commandName1
                    Command2 = $commandName2
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Clear-TestCachedCommandCache test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-AssumedCommand -Name $commandName1 -ErrorAction SilentlyContinue | Out-Null
                    Remove-AssumedCommand -Name $commandName2 -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }

        It 'Get-AssumedCommands returns list of assumed commands' {
            $assumedName1 = "AssumedTest1_$(Get-Random)"
            $assumedName2 = "AssumedTest2_$(Get-Random)"
            $cleanupNeeded = $false

            try {
                # Initially should be empty or not contain our test commands
                $initialAssumed = Get-AssumedCommands
                $initialAssumed | Should -Not -Be $null -Because "Get-AssumedCommands should return a non-null result"
                $initialAssumed.GetType().FullName | Should -Be 'System.String[]' -Because "Get-AssumedCommands should return a string array"

                # Add assumed commands
                $result1 = Add-AssumedCommand -Name $assumedName1
                $result2 = Add-AssumedCommand -Name $assumedName2
                $result1 | Should -Be $true -Because "Add-AssumedCommand should succeed for new command"
                $result2 | Should -Be $true -Because "Add-AssumedCommand should succeed for new command"
                $cleanupNeeded = $true

                # Get assumed commands
                $assumedCommands = Get-AssumedCommands
                $assumedCommands | Should -Contain $assumedName1 -Because "assumed command should be in the list"
                $assumedCommands | Should -Contain $assumedName2 -Because "assumed command should be in the list"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Command1 = $assumedName1
                    Command2 = $assumedName2
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Get-AssumedCommands test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-AssumedCommand -Name $assumedName1 -ErrorAction SilentlyContinue | Out-Null
                    Remove-AssumedCommand -Name $assumedName2 -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }

        It 'Set-AgentModeFunction returns false when function already exists' {
            try {
                $existingFunc = 'Get-Command'
                if (-not (Get-Command -Name $existingFunc -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because "Test requires existing function: $existingFunc"
                    return
                }
                
                $result = Set-AgentModeFunction -Name $existingFunc -Body { 'test' }
                $result | Should -Be $false -Because "Set-AgentModeFunction should return false when function already exists"
            }
            catch {
                $errorDetails = @{
                    Message      = $_.Exception.Message
                    FunctionName = $existingFunc
                    Category     = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeFunction existing function test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Set-AgentModeAlias returns false when alias already exists' {
            try {
                $existingAlias = 'ls'
                if (-not (Get-Command -Name $existingAlias -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because "Test requires existing alias: $existingAlias"
                    return
                }
                
                $result = Set-AgentModeAlias -Name $existingAlias -Target 'Get-Command'
                $result | Should -Be $false -Because "Set-AgentModeAlias should return false when alias already exists"
            }
            catch {
                $errorDetails = @{
                    Message   = $_.Exception.Message
                    AliasName = $existingAlias
                    Category  = $_.CategoryInfo.Category
                }
                Write-Error "Set-AgentModeAlias existing alias test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }
    }
}

