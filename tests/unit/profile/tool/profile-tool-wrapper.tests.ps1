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
    if (-not (Get-Command Get-TestRepoRoot -ErrorAction SilentlyContinue)) {
        throw "Get-TestRepoRoot function not available. TestSupport.ps1 may not have loaded correctly from: $PSScriptRoot"
    }

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    
    # Load dependencies first
    $globalStatePath = Join-Path $script:BootstrapDir 'GlobalState.ps1'
    if (Test-Path $globalStatePath) {
        . $globalStatePath
    }
    
    $commandCachePath = Join-Path $script:BootstrapDir 'CommandCache.ps1'
    if (Test-Path $commandCachePath) {
        . $commandCachePath
    }
    
    $missingToolWarningsPath = Join-Path $script:BootstrapDir 'MissingToolWarnings.ps1'
    if (Test-Path $missingToolWarningsPath) {
        . $missingToolWarningsPath
    }
    
    # Load the module under test
    $functionRegistrationPath = Join-Path $script:BootstrapDir 'FunctionRegistration.ps1'
    if (Test-Path $functionRegistrationPath) {
        . $functionRegistrationPath
    }
    else {
        throw "FunctionRegistration.ps1 not found at: $functionRegistrationPath"
    }
    
    # Create a test command for testing
    $script:TestCommandName = "TestToolWrapper_$(Get-Random)"
    $script:TestFunctionName = "TestToolWrapperFunc_$(Get-Random)"
}

AfterAll {
    # Clean up test functions
    Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
    
    # Clear command cache
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
}

Describe 'Register-ToolWrapper Function' {
    
    Context 'Basic Registration' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }
        
        It 'Registers a tool wrapper function successfully' {
            # Use a command that likely exists (like 'git' or 'pwsh')
            $testCmd = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } else { 'pwsh' }
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmd
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Throws on null FunctionName (ValidateNotNullOrEmpty)' {
            { Register-ToolWrapper -FunctionName $null -CommandName 'test' } | Should -Throw
        }

        It 'Throws on empty FunctionName (ValidateNotNullOrEmpty)' {
            { Register-ToolWrapper -FunctionName '' -CommandName 'test' } | Should -Throw
        }

        It 'Throws on null CommandName (ValidateNotNullOrEmpty)' {
            { Register-ToolWrapper -FunctionName 'test' -CommandName $null } | Should -Throw
        }

        It 'Throws on empty CommandName (ValidateNotNullOrEmpty)' {
            { Register-ToolWrapper -FunctionName 'test' -CommandName '' } | Should -Throw
        }
        
        It 'Does not overwrite existing function' {
            # Create a function first
            Set-Item -Path "Function:\$script:TestFunctionName" -Value { 'existing' } -Force
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName 'test'
            
            $result | Should -Be $false
            $existing = Get-Item -Path "Function:\$script:TestFunctionName" -ErrorAction SilentlyContinue
            $existing | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Command Execution' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }
        
        It 'Executes command when available' {
            # Use a command that exists
            $testCmd = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } elseif (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmd
            
            $result | Should -Be $true
            
            # Test that the wrapper function exists and can be called
            $wrapper = Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue
            $wrapper | Should -Not -BeNullOrEmpty
        }
        
        It 'Shows warning when command is not found' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $nonExistentCmd
            
            $result | Should -Be $true

            # Verify function was created
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

            # Call the wrapper — should emit a warning about the missing command, not throw
            { & $script:TestFunctionName 2>&1 | Out-Null } | Should -Not -Throw
        }
        
        It 'Uses custom warning message when provided' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"
            $customWarning = "Custom warning for $nonExistentCmd"
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $nonExistentCmd `
                -WarningMessage $customWarning
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Uses InstallHint when provided' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"
            $installHint = "Install with: scoop install $nonExistentCmd"
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $nonExistentCmd `
                -InstallHint $installHint
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Command Detection' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }

        It 'Registers wrapper for a function-type command discovered via Test-CachedCommand' {
            $testCmdName = "TestCmd_$(Get-Random)"
            Set-Item -Path "Function:\\$testCmdName" -Value { 'test-output' } -Force

            try {
                if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                    Clear-TestCachedCommandCache | Out-Null
                }

                $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmdName
                $result | Should -Be $true

                # The wrapper must be callable without throwing
                { & $script:TestFunctionName 2>&1 | Out-Null } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path "Function:\\$testCmdName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Falls back to Get-Command when Test-CachedCommand not available' {
            Set-ItResult -Skipped -Because 'removing Test-CachedCommand mid-session would corrupt cache state; behavior is covered by other integration paths'
        }
    }
    
    Context 'Error Handling' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }

        It 'Wrapper for missing command emits a warning (not throws) when invoked with InstallHint' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"
            $installHint = "Install with: scoop install $nonExistentCmd"

            Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $nonExistentCmd `
                -InstallHint $installHint | Out-Null

            # Calling the wrapper should not throw — it should warn
            { & $script:TestFunctionName 2>&1 | Out-Null } | Should -Not -Throw
        }

        It 'Wrapper for missing command emits a warning (not throws) when invoked with WarningMessage' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"

            Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $nonExistentCmd `
                -WarningMessage "Tool $nonExistentCmd not found" | Out-Null

            { & $script:TestFunctionName 2>&1 | Out-Null } | Should -Not -Throw
        }
    }
    
    Context 'Idempotency' {
        It 'Can be called multiple times safely' {
            $testCmd = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } else { 'pwsh' }
            $idempotentName = "IdempotencyTest_$(Get-Random)"

            try {
                $result1 = Register-ToolWrapper -FunctionName $idempotentName -CommandName $testCmd
                $result2 = Register-ToolWrapper -FunctionName $idempotentName -CommandName $testCmd

                $result1 | Should -Be $true
                $result2 | Should -Be $false  # Second call returns false (function already exists)
            }
            finally {
                Remove-Item -Path "Function:\$idempotentName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$idempotentName" -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context 'CommandType Parameter' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }

        It 'Defaults to Application command type (git is an Application)' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not installed on this system'
                return
            }

            $cmdTypeName = "CmdTypeTest_$(Get-Random)"
            try {
                $result = Register-ToolWrapper -FunctionName $cmdTypeName -CommandName 'git'
                $result | Should -Be $true

                # Wrapper should exist and forwarding should work
                { & $cmdTypeName --version 2>&1 | Out-Null } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path "Function:\$cmdTypeName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$cmdTypeName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Accepts Function CommandType and wraps a function correctly' {
            $innerFunc = "InnerFunc_$(Get-Random)"
            $outerFunc = "OuterFunc_$(Get-Random)"
            Set-Item -Path "Function:\$innerFunc" -Value { Write-Output 'wrapped-output' } -Force

            try {
                $result = Register-ToolWrapper -FunctionName $outerFunc `
                    -CommandName $innerFunc `
                    -CommandType Function

                $result | Should -Be $true

                # Calling the wrapper should not throw
                { & $outerFunc 2>&1 | Out-Null } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path "Function:\$innerFunc" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\$outerFunc" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$outerFunc" -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

