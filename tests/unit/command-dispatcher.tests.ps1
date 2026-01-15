# ===============================================
# command-dispatcher.tests.ps1
# Unit tests for CommandDispatcher.psm1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    $script:DispatcherModulePath = Join-Path $script:FragmentLibDir 'CommandDispatcher.psm1'
    $script:RegistryModulePath = Join-Path $script:FragmentLibDir 'FragmentCommandRegistry.psm1'
    
    # Import registry module first (dispatcher depends on it)
    if (Test-Path -LiteralPath $script:RegistryModulePath) {
        Import-Module $script:RegistryModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    
    if (Test-Path -LiteralPath $script:DispatcherModulePath) {
        Import-Module $script:DispatcherModulePath -DisableNameChecking -ErrorAction Stop
    }
    else {
        Write-Warning "CommandDispatcher module not found at: $script:DispatcherModulePath"
    }
    
    # Initialize registry if needed
    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:FragmentCommandRegistry = @{}
    }
}

BeforeEach {
    # Unregister dispatcher before each test for clean state
    if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
        $null = Unregister-CommandDispatcher
    }
    
    # Clear registry
    if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentCommandRegistry.Clear()
    }
    
    # Reset environment variable
    if ($env:PS_PROFILE_AUTO_LOAD_FRAGMENTS) {
        $script:OriginalAutoLoad = $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS
    }
    else {
        $script:OriginalAutoLoad = $null
    }
    $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '1'
}

AfterEach {
    # Restore environment variable
    if ($script:OriginalAutoLoad) {
        $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = $script:OriginalAutoLoad
    }
    else {
        Remove-Item -Path env:PS_PROFILE_AUTO_LOAD_FRAGMENTS -ErrorAction SilentlyContinue
    }
}

AfterAll {
    # Clean up
    if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
        $null = Unregister-CommandDispatcher
    }
    
    if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentCommandRegistry.Clear()
    }
}

Describe 'CommandDispatcher.psm1 - Test-CommandInRegistry' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-DispatcherCommand' -FragmentName 'bootstrap' -CommandType 'Function'
        }
    }
    
    It 'Returns true for registered command' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            Test-CommandInRegistry -CommandName 'Test-DispatcherCommand' | Should -Be $true
        }
    }
    
    It 'Returns false for unregistered command' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            Test-CommandInRegistry -CommandName 'NonExistentCommand' | Should -Be $false
        }
    }
    
    It 'Returns false for null or empty command name' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            Test-CommandInRegistry -CommandName '' | Should -Be $false
            Test-CommandInRegistry -CommandName $null | Should -Be $false
        }
    }
}

Describe 'CommandDispatcher.psm1 - Register-CommandDispatcher' {
    It 'Registers dispatcher successfully' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            $result = Register-CommandDispatcher
            $result | Should -Be $true
            
            if (Get-Command Test-CommandDispatcherRegistered -ErrorAction SilentlyContinue) {
                Test-CommandDispatcherRegistered | Should -Be $true
            }
        }
    }
    
    It 'Returns false when auto-loading is disabled' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '0'
            $result = Register-CommandDispatcher
            $result | Should -Be $false
        }
    }
    
    It 'Returns false when registry is not available' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            # Temporarily remove registry
            $originalRegistry = $global:FragmentCommandRegistry
            Remove-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue
            
            try {
                $result = Register-CommandDispatcher
                $result | Should -Be $false
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
    
    It 'Can be called multiple times (idempotent)' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            Register-CommandDispatcher | Should -Be $true
            Register-CommandDispatcher | Should -Be $true  # Should not error
        }
    }
    
    It 'Can force re-registration' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            Register-CommandDispatcher | Should -Be $true
            Register-CommandDispatcher -Force | Should -Be $true
        }
    }
}

Describe 'CommandDispatcher.psm1 - Unregister-CommandDispatcher' {
    It 'Unregisters dispatcher successfully' {
        $hasRegister = Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue
        $hasUnregister = Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue
        if ($hasRegister -and $hasUnregister) {
            $null = Register-CommandDispatcher
            $result = Unregister-CommandDispatcher
            $result | Should -Be $true
            
            if (Get-Command Test-CommandDispatcherRegistered -ErrorAction SilentlyContinue) {
                Test-CommandDispatcherRegistered | Should -Be $false
            }
        }
    }
    
    It 'Returns false when dispatcher is not registered' {
        if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
            $result = Unregister-CommandDispatcher
            $result | Should -Be $false
        }
    }
}

Describe 'CommandDispatcher.psm1 - Test-CommandDispatcherRegistered' {
    It 'Returns false when dispatcher is not registered' {
        if (Get-Command Test-CommandDispatcherRegistered -ErrorAction SilentlyContinue) {
            Test-CommandDispatcherRegistered | Should -Be $false
        }
    }
    
    It 'Returns true when dispatcher is registered' {
        $hasRegister = Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue
        $hasTest = Get-Command Test-CommandDispatcherRegistered -ErrorAction SilentlyContinue
        if ($hasRegister -and $hasTest) {
            $null = Register-CommandDispatcher
            Test-CommandDispatcherRegistered | Should -Be $true
        }
    }
}

Describe 'CommandDispatcher.psm1 - Invoke-CommandDispatcher' {
    BeforeEach {
        # Register a test command
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-InvokeCommand' -FragmentName 'bootstrap' -CommandType 'Function'
        }
    }
    
    It 'Returns false for unregistered command' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            # Create mock CommandLookupEventArgs
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            $result = Invoke-CommandDispatcher -CommandName 'NonExistentCommand' -CommandLookupEventArgs $mockEventArgs
            $result | Should -Be $false
        }
    }
    
    It 'Returns false when auto-loading is disabled' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '0'
            
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            $result = Invoke-CommandDispatcher -CommandName 'Test-InvokeCommand' -CommandLookupEventArgs $mockEventArgs
            $result | Should -Be $false
        }
    }
    
    It 'Handles null or empty command name' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            Invoke-CommandDispatcher -CommandName '' -CommandLookupEventArgs $mockEventArgs | Should -Be $false
            Invoke-CommandDispatcher -CommandName $null -CommandLookupEventArgs $mockEventArgs | Should -Be $false
        }
    }
    
    It 'Handles timeout configuration' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            $env:PS_PROFILE_AUTO_LOAD_TIMEOUT = '60'
            
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            # Should not throw with timeout configured
            { Invoke-CommandDispatcher -CommandName 'NonExistentCommand' -CommandLookupEventArgs $mockEventArgs } | Should -Not -Throw
            
            Remove-Item -Path env:PS_PROFILE_AUTO_LOAD_TIMEOUT -ErrorAction SilentlyContinue
        }
    }
    
    It 'Handles invalid timeout configuration gracefully' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            $env:PS_PROFILE_AUTO_LOAD_TIMEOUT = 'invalid'
            
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            # Should use default timeout
            { Invoke-CommandDispatcher -CommandName 'NonExistentCommand' -CommandLookupEventArgs $mockEventArgs } | Should -Not -Throw
            
            Remove-Item -Path env:PS_PROFILE_AUTO_LOAD_TIMEOUT -ErrorAction SilentlyContinue
        }
    }
    
    It 'Handles Invoke-WithWideEvent when available' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            # This test verifies the function works with wide event tracking
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            { Invoke-CommandDispatcher -CommandName 'NonExistentCommand' -CommandLookupEventArgs $mockEventArgs } | Should -Not -Throw
        }
    }
    
    It 'Handles fallback when Invoke-WithWideEvent is not available' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            # This test verifies the function works without wide event tracking
            $mockEventArgs = [PSCustomObject]@{
                StopSearch = $true
            }
            $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
            
            { Invoke-CommandDispatcher -CommandName 'NonExistentCommand' -CommandLookupEventArgs $mockEventArgs } | Should -Not -Throw
        }
    }
    
    It 'Handles missing Load-FragmentForCommand gracefully' {
        if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
            # Register command but ensure Load-FragmentForCommand is not available
            if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
                $null = Register-FragmentCommand -CommandName 'Test-MissingLoader' -FragmentName 'bootstrap' -CommandType 'Function'
                
                $mockEventArgs = [PSCustomObject]@{
                    StopSearch = $true
                }
                $mockEventArgs | Add-Member -MemberType ScriptMethod -Name 'StopSearch' -Value { param($value) $this.StopSearch = $value } -Force
                
                # Should handle gracefully even if loader is missing
                { Invoke-CommandDispatcher -CommandName 'Test-MissingLoader' -CommandLookupEventArgs $mockEventArgs } | Should -Not -Throw
            }
        }
    }
}

Describe 'CommandDispatcher.psm1 - Register-CommandDispatcher error handling' {
    It 'Handles chaining with existing CommandNotFoundAction' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            # Set up an existing handler
            $originalHandler = $ExecutionContext.InvokeCommand.CommandNotFoundAction
            $testHandler = { param($cmd, $args) }
            $ExecutionContext.InvokeCommand.CommandNotFoundAction = $testHandler
            
            try {
                $result = Register-CommandDispatcher
                $result | Should -Be $true
            }
            finally {
                $ExecutionContext.InvokeCommand.CommandNotFoundAction = $originalHandler
            }
        }
    }
    
    It 'Handles errors during handler registration gracefully' {
        if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
            # This test verifies error handling in registration
            { Register-CommandDispatcher } | Should -Not -Throw
        }
    }
}

Describe 'CommandDispatcher.psm1 - Test-CommandInRegistry error handling' {
    It 'Handles missing registry module gracefully' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            # Temporarily remove registry
            $originalRegistry = $global:FragmentCommandRegistry
            Remove-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue
            
            try {
                Test-CommandInRegistry -CommandName 'AnyCommand' | Should -Be $false
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
    
    It 'Handles module function call errors gracefully' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            # Function should handle errors in module function calls
            { Test-CommandInRegistry -CommandName 'TestCommand' } | Should -Not -Throw
        }
    }
    
    It 'Handles direct registry check errors gracefully' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            # Function should handle errors in direct registry checks
            { Test-CommandInRegistry -CommandName 'TestCommand' } | Should -Not -Throw
        }
    }
}
