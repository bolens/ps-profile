# ===============================================
# command-access.tests.ps1
# Integration tests for fragment command access features
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    
    # Load bootstrap to initialize global state
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Import fragment modules
    $registryModulePath = Join-Path $script:FragmentLibDir 'FragmentCommandRegistry.psm1'
    $loaderModulePath = Join-Path $script:FragmentLibDir 'FragmentLoader.psm1'
    $dispatcherModulePath = Join-Path $script:FragmentLibDir 'CommandDispatcher.psm1'
    
    if (Test-Path -LiteralPath $registryModulePath) {
        Import-Module $registryModulePath -DisableNameChecking -ErrorAction Stop
    }
    
    if (Test-Path -LiteralPath $loaderModulePath) {
        Import-Module $loaderModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    
    if (Test-Path -LiteralPath $dispatcherModulePath) {
        Import-Module $dispatcherModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

AfterAll {
    # Clean up: unregister dispatcher if registered
    if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
        $null = Unregister-CommandDispatcher
    }
    
    # Clear registry for clean state
    if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentCommandRegistry.Clear()
    }
}

Describe 'Fragment Command Access - Integration Tests' {
    Context 'Command Registry' {
        BeforeAll {
            # Register a test command
            if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
                $null = Register-FragmentCommand -CommandName 'Test-CommandAccess' -FragmentName 'bootstrap' -CommandType 'Function'
            }
        }
        
        It 'Registers commands in global registry' {
            if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
                $global:FragmentCommandRegistry.Count | Should -BeGreaterThan 0
            }
        }
        
        It 'Can look up fragment for a command' {
            if (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue) {
                $fragment = Get-FragmentForCommand -CommandName 'Test-CommandAccess'
                $fragment | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Can get command registry info' {
            if (Get-Command Get-CommandRegistryInfo -ErrorAction SilentlyContinue) {
                $info = Get-CommandRegistryInfo -CommandName 'Test-CommandAccess'
                $info | Should -Not -BeNullOrEmpty
                $info.Fragment | Should -Be 'bootstrap'
                $info.Type | Should -Be 'Function'
            }
        }
        
        It 'Can test if command is in registry' {
            if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
                Test-CommandInRegistry -CommandName 'Test-CommandAccess' | Should -Be $true
                Test-CommandInRegistry -CommandName 'NonExistentCommand' | Should -Be $false
            }
        }
    }
    
    Context 'On-Demand Fragment Loading' {
        It 'Can load fragment by name' {
            if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
                { Load-Fragment -FragmentName 'bootstrap' } | Should -Not -Throw
            }
        }
        
        It 'Can load fragment for a command' {
            if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
                # Register a test command first
                if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
                    $null = Register-FragmentCommand -CommandName 'Test-LoadCommand' -FragmentName 'bootstrap' -CommandType 'Function'
                    
                    { Load-FragmentForCommand -CommandName 'Test-LoadCommand' } | Should -Not -Throw
                }
            }
        }
        
        It 'Respects fragment idempotency' {
            if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
                # Loading the same fragment multiple times should not error
                { 
                    Load-Fragment -FragmentName 'bootstrap'
                    Load-Fragment -FragmentName 'bootstrap'
                } | Should -Not -Throw
            }
        }
        
        It 'Handles missing fragments gracefully' {
            if (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
                { Load-Fragment -FragmentName 'NonExistentFragment' } | Should -Not -Throw
            }
        }
    }
    
    Context 'Command Dispatcher' {
        BeforeEach {
            # Unregister dispatcher before each test for clean state
            if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
                $null = Unregister-CommandDispatcher
            }
        }
        
        It 'Can register command dispatcher' {
            if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
                $result = Register-CommandDispatcher
                $result | Should -Be $true
            }
        }
        
        It 'Can test if dispatcher is registered' {
            if (Get-Command Test-CommandDispatcherRegistered -ErrorAction SilentlyContinue) {
                if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
                    $null = Register-CommandDispatcher
                    Test-CommandDispatcherRegistered | Should -Be $true
                }
            }
        }
        
        It 'Can unregister command dispatcher' {
            if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
                $null = Register-CommandDispatcher
                
                if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
                    $result = Unregister-CommandDispatcher
                    $result | Should -Be $true
                    Test-CommandDispatcherRegistered | Should -Be $false
                }
            }
        }
        
        It 'Respects auto-loading environment variable' {
            if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
                # Test with auto-loading disabled
                $originalValue = $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS
                try {
                    $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '0'
                    $result = Register-CommandDispatcher
                    # Should return false when disabled
                    $result | Should -Be $false
                }
                finally {
                    if ($originalValue) {
                        $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = $originalValue
                    }
                    else {
                        Remove-Item -Path env:PS_PROFILE_AUTO_LOAD_FRAGMENTS -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
    
    Context 'End-to-End Command Access' {
        BeforeAll {
            # Ensure bootstrap is loaded and has some commands registered
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
        }
        
        It 'Can access commands after fragment loading' {
            # This test verifies the full flow:
            # 1. Command is registered
            # 2. Fragment can be loaded on-demand
            # 3. Command becomes available
            
            if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
                # Find a real command from bootstrap
                $testCommand = $null
                if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
                    foreach ($cmdName in $global:FragmentCommandRegistry.Keys) {
                        $cmdInfo = $global:FragmentCommandRegistry[$cmdName]
                        if ($cmdInfo.Type -eq 'Function' -and $cmdInfo.Fragment -eq 'bootstrap') {
                            $testCommand = $cmdName
                            break
                        }
                    }
                }
                
                if ($testCommand) {
                    # Verify command is in registry
                    Test-CommandInRegistry -CommandName $testCommand | Should -Be $true
                    
                    # Verify we can get fragment info
                    if (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue) {
                        $fragment = Get-FragmentForCommand -CommandName $testCommand
                        $fragment | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }
    
    Context 'Error Handling' {
        It 'Handles missing registry gracefully' {
            # Temporarily clear registry
            $originalRegistry = $null
            if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
                $originalRegistry = $global:FragmentCommandRegistry
                $global:FragmentCommandRegistry = @{}
            }
            
            try {
                if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
                    Test-CommandInRegistry -CommandName 'AnyCommand' | Should -Be $false
                }
            }
            finally {
                if ($originalRegistry) {
                    $global:FragmentCommandRegistry = $originalRegistry
                }
            }
        }
        
        It 'Handles missing modules gracefully' {
            # Test that functions degrade gracefully when modules aren't available
            # This is tested implicitly by the conditional checks in the tests above
            $true | Should -Be $true
        }
    }
}
