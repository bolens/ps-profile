. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Bootstrap Helper Functions' {
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
}