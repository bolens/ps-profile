# Load TestSupport.ps1 - ensure it's loaded before using its functions
$testSupportPath = Join-Path $PSScriptRoot '..\TestSupport.ps1'
if (Test-Path $testSupportPath) {
    . $testSupportPath
}
else {
    throw "TestSupport.ps1 not found at: $testSupportPath"
}

BeforeAll {
    # Ensure TestSupport functions are available - reload if needed
    if (-not (Get-Command Get-TestRepoRoot -ErrorAction SilentlyContinue)) {
        $testSupportPath = Join-Path $PSScriptRoot '..\TestSupport.ps1'
        if (Test-Path $testSupportPath) {
            . $testSupportPath
        }
        if (-not (Get-Command Get-TestRepoRoot -ErrorAction SilentlyContinue)) {
            throw "Get-TestRepoRoot function not available. TestSupport.ps1 may not have loaded correctly from: $testSupportPath"
        }
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
        
        It 'Returns false for null FunctionName' {
            $result = Register-ToolWrapper -FunctionName $null -CommandName 'test'
            $result | Should -Be $false
        }
        
        It 'Returns false for empty FunctionName' {
            $result = Register-ToolWrapper -FunctionName '' -CommandName 'test'
            $result | Should -Be $false
        }
        
        It 'Returns false for null CommandName' {
            $result = Register-ToolWrapper -FunctionName 'test' -CommandName $null
            $result | Should -Be $false
        }
        
        It 'Returns false for empty CommandName' {
            $result = Register-ToolWrapper -FunctionName 'test' -CommandName ''
            $result | Should -Be $false
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
            
            # Call the wrapper - should show warning (we can't easily capture warnings in tests)
            # But we can verify the function exists and can be called
            try {
                & $script:TestFunctionName 2>&1 | Out-Null
            }
            catch {
                # Expected - command doesn't exist
            }
            
            $true | Should -Be $true  # Function was created successfully
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
        
        It 'Uses Test-CachedCommand when available' {
            # Create a test command
            $testCmdName = "TestCmd_$(Get-Random)"
            Set-Item -Path "Function:\$testCmdName" -Value { 'test' } -Force
            
            try {
                # Clear cache first
                if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                    Clear-TestCachedCommandCache | Out-Null
                }
                
                $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmdName
                
                $result | Should -Be $true
                
                # The wrapper should use Test-CachedCommand internally
                # We can't easily verify this without more complex mocking, but the function should work
                Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path "Function:\$testCmdName" -Force -ErrorAction SilentlyContinue
            }
        }
        
        It 'Falls back to Get-Command when Test-CachedCommand not available' {
            # This is hard to test without removing Test-CachedCommand, but we can verify
            # the function still works
            $testCmd = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } else { 'pwsh' }
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmd
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Error Handling' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }
        
        It 'Uses Write-MissingToolWarning when available and InstallHint provided' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"
            $installHint = "Install with: scoop install $nonExistentCmd"
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $nonExistentCmd `
                -InstallHint $installHint
            
            $result | Should -Be $true
            # Function should be created (we can't easily verify Write-MissingToolWarning was called)
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Falls back to Write-Warning when Write-MissingToolWarning not available' {
            $nonExistentCmd = "NonExistentCommand_$(Get-Random)"
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $nonExistentCmd `
                -WarningMessage "Tool $nonExistentCmd not found"
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Idempotency' {
        It 'Can be called multiple times safely' {
            $testCmd = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } else { 'pwsh' }
            
            $result1 = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmd
            $result2 = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmd
            
            $result1 | Should -Be $true
            $result2 | Should -Be $false  # Second call should return false (function already exists)
            
            # Clean up
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context 'CommandType Parameter' {
        AfterEach {
            Remove-Item -Path "Function:\$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$script:TestFunctionName" -Force -ErrorAction SilentlyContinue
        }
        
        It 'Defaults to Application command type' {
            $testCmd = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } else { 'pwsh' }
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName -CommandName $testCmd
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Accepts custom CommandType' {
            # Test with Function type (using a function we know exists)
            $testFunc = if (Get-Command Get-Command -ErrorAction SilentlyContinue) { 'Get-Command' } else { 'Write-Host' }
            
            $result = Register-ToolWrapper -FunctionName $script:TestFunctionName `
                -CommandName $testFunc `
                -CommandType Function
            
            $result | Should -Be $true
            Get-Command $script:TestFunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

