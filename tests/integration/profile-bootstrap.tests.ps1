. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Profile Bootstrap Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
        . $script:BootstrapPath
    }

    Context 'Bootstrap helper functions' {
        It 'Test-CachedCommand caches command availability results' {
            $commandName = "TestCachedCommand_{0}" -f (Get-Random)
            Remove-TestCachedCommandCacheEntry -Name $commandName | Out-Null
            $scriptBlock = { 'cached' }
            Set-Item -Path "Function:\$commandName" -Value $scriptBlock -Force
            Set-Item -Path "Function:\global:$commandName" -Value $scriptBlock -Force

            try {
                $result1 = Test-CachedCommand -Name $commandName
                $result2 = Test-CachedCommand -Name $commandName
                $result1 | Should -Be $result2
                $result1 | Should -Be $true
            }
            finally {
                Remove-TestCachedCommandCacheEntry -Name $commandName | Out-Null
                Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Test-CachedCommand returns false for non-existent commands' {
            $nonExistent = "TestCommand_$(Get-Random)_$(Get-Random)"
            $result = Test-CachedCommand -Name $nonExistent
            $result | Should -Be $false
        }

        It 'Test-HasCommand checks function provider first' {
            $testFuncName = "TestFunc_$(Get-Random)"
            $scriptBlock = { 'test' }
            Set-Item -Path "Function:\$testFuncName" -Value $scriptBlock -Force
            Set-Item -Path "Function:\global:$testFuncName" -Value $scriptBlock -Force

            try {
                Test-Path -LiteralPath "Function:\$testFuncName" | Should -BeTrue
                $result = Test-HasCommand -Name $testFuncName
                $result | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\$testFuncName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$testFuncName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Test-HasCommand checks alias provider' {
            $testAliasName = "TestAlias_$(Get-Random)"
            Set-AgentModeAlias -Name $testAliasName -Target 'Get-Command' | Out-Null

            try {
                Get-Alias -Name $testAliasName -ErrorAction Stop | Should -Not -BeNullOrEmpty
                $result = Test-HasCommand -Name $testAliasName
                $result | Should -Be $true
            }
            finally {
                Remove-Alias -Name $testAliasName -Scope Global -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Test-HasCommand returns false for non-existent commands' {
            $nonExistent = "TestCommand_$(Get-Random)_$(Get-Random)"
            $result = Test-HasCommand -Name $nonExistent
            $result | Should -Be $false
        }

        It 'Clear-TestCachedCommandCache clears all cached entries' {
            $commandName1 = "TestClearCache1_$(Get-Random)"
            $commandName2 = "TestClearCache2_$(Get-Random)"

            # Add some cached entries
            Add-AssumedCommand -Name $commandName1 | Out-Null
            Add-AssumedCommand -Name $commandName2 | Out-Null

            # Verify they are cached
            Test-CachedCommand -Name $commandName1 | Should -Be $true
            Test-CachedCommand -Name $commandName2 | Should -Be $true

            # Clear cache
            Clear-TestCachedCommandCache

            # Verify cache is cleared (should still be assumed but not cached)
            Test-HasCommand -Name $commandName1 | Should -Be $true
            Test-HasCommand -Name $commandName2 | Should -Be $true

            # Clean up
            Remove-AssumedCommand -Name $commandName1 | Out-Null
            Remove-AssumedCommand -Name $commandName2 | Out-Null
        }

        It 'Get-AssumedCommands returns list of assumed commands' {
            $assumedName1 = "AssumedTest1_$(Get-Random)"
            $assumedName2 = "AssumedTest2_$(Get-Random)"

            try {
                # Initially should be empty or not contain our test commands
                $initialAssumed = Get-AssumedCommands
                $initialAssumed | Should -Not -Be $null
                $initialAssumed.GetType().FullName | Should -Be 'System.String[]'

                # Add assumed commands
                Add-AssumedCommand -Name $assumedName1 | Should -Be $true
                Add-AssumedCommand -Name $assumedName2 | Should -Be $true

                # Get assumed commands
                $assumedCommands = Get-AssumedCommands
                $assumedCommands | Should -Contain $assumedName1
                $assumedCommands | Should -Contain $assumedName2
            }
            finally {
                Remove-AssumedCommand -Name $assumedName1 | Out-Null
                Remove-AssumedCommand -Name $assumedName2 | Out-Null
            }
        }

        It 'Set-AgentModeFunction returns false when function already exists' {
            $existingFunc = 'Get-Command'
            $result = Set-AgentModeFunction -Name $existingFunc -Body { 'test' }
            $result | Should -Be $false
        }

        It 'Set-AgentModeAlias returns false when alias already exists' {
            $existingAlias = 'ls'
            if (Get-Command -Name $existingAlias -ErrorAction SilentlyContinue) {
                $result = Set-AgentModeAlias -Name $existingAlias -Target 'Get-Command'
                $result | Should -Be $false
            }
        }
    }

    Context 'Idempotency tests' {
        It 'Set-AgentModeFunction is idempotent' {
            . $script:BootstrapPath
            $funcName = "TestIdempotent_$(Get-Random)"

            $result1 = Set-AgentModeFunction -Name $funcName -Body { 'test' }
            $result1 | Should -Be $true

            $result2 = Set-AgentModeFunction -Name $funcName -Body { 'test2' }
            $result2 | Should -Be $false

            $funcResult = & $funcName
            $funcResult | Should -Be 'test'

            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }

        It 'Set-AgentModeAlias is idempotent' {
            . $script:BootstrapPath
            $aliasName = "TestAliasIdempotent_$(Get-Random)"

            $result1 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $result1 | Should -Be $true

            $result2 = Set-AgentModeAlias -Name $aliasName -Target 'Write-Host'
            $result2 | Should -Be $false

            $aliasResult = Get-Alias -Name $aliasName -ErrorAction SilentlyContinue
            if ($aliasResult) {
                $aliasResult.Definition | Should -Match 'Write-Output'
            }

            Remove-Alias -Name $aliasName -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Function scoping and visibility' {
        It 'Set-AgentModeFunction creates global functions' {
            $funcName = "TestGlobal_$(Get-Random)"
            $result = Set-AgentModeFunction -Name $funcName -Body { 'global' }
            $result | Should -Be $true

            Get-Command $funcName -ErrorAction Stop | Should -Not -Be $null

            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }

        It 'Set-AgentModeAlias creates global aliases' {
            $aliasName = "TestGlobalAlias_$(Get-Random)"
            $result = Set-AgentModeAlias -Name $aliasName -Target 'Write-Output'
            $result | Should -Be $true

            Get-Alias $aliasName -ErrorAction Stop | Should -Not -Be $null

            Remove-Alias -Name $aliasName -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Agent mode compatibility' {
        BeforeAll {
            . $script:BootstrapPath
            . (Join-Path $script:ProfileDir '03-agent-mode.ps1')
        }

        It 'am-list function is available when bootstrap loaded' {
            Get-Command am-list -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'am-doc function is available when bootstrap loaded' {
            Get-Command am-doc -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'am-list returns agent mode functions' {
            $result = am-list
            $result | Should -Not -Be $null
        }

        It 'am-doc handles missing documentation gracefully' {
            { am-doc } | Should -Not -Throw
        }
    }

    Context 'Performance and memory tests' {
        BeforeAll {
            . $script:BootstrapPath
        }

        It 'Test-CachedCommand improves performance on repeated calls' {
            $commandName = 'Get-Command'

            $start1 = Get-Date
            $result1 = Test-CachedCommand -Name $commandName
            $time1 = (Get-Date) - $start1

            $start2 = Get-Date
            $result2 = Test-CachedCommand -Name $commandName
            $time2 = (Get-Date) - $start2

            $result1 | Should -Be $result2
            $time2.TotalMilliseconds | Should -BeLessOrEqual ($time1.TotalMilliseconds + 50)
        }

        It 'Set-AgentModeFunction does not leak memory on repeated calls' {
            $funcName = "TestMemory_$(Get-Random)"

            for ($i = 1; $i -le 5; $i++) {
                $result = Set-AgentModeFunction -Name $funcName -Body { "test$i" }
                $result | Should -Be $true
                Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }

            $final = Set-AgentModeFunction -Name $funcName -Body { 'final' }
            $final | Should -Be $true

            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }
    }
}
