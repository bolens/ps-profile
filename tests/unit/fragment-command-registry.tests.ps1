# ===============================================
# fragment-command-registry.tests.ps1
# Unit tests for FragmentCommandRegistry.psm1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    $script:RegistryModulePath = Join-Path $script:FragmentLibDir 'FragmentCommandRegistry.psm1'
    
    if (Test-Path -LiteralPath $script:RegistryModulePath) {
        Import-Module $script:RegistryModulePath -DisableNameChecking -ErrorAction Stop
    }
    else {
        Write-Warning "FragmentCommandRegistry module not found at: $script:RegistryModulePath"
    }
    
    # Initialize global registry if it doesn't exist
    if (-not (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:FragmentCommandRegistry = @{}
    }
}

BeforeEach {
    # Clear registry before each test for isolation
    if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentCommandRegistry.Clear()
    }
}

AfterAll {
    # Clean up
    if (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) {
        $global:FragmentCommandRegistry.Clear()
    }
}

Describe 'FragmentCommandRegistry.psm1 - Register-FragmentCommand' {
    It 'Registers a function command' {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $result = Register-FragmentCommand -CommandName 'Test-Function' -FragmentName 'test-fragment' -CommandType 'Function'
            $result | Should -Be $true
            
            $global:FragmentCommandRegistry.ContainsKey('Test-Function') | Should -Be $true
            $global:FragmentCommandRegistry['Test-Function'].Fragment | Should -Be 'test-fragment'
            $global:FragmentCommandRegistry['Test-Function'].Type | Should -Be 'Function'
        }
    }
    
    It 'Registers an alias command with target' {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $result = Register-FragmentCommand -CommandName 'tf' -FragmentName 'test-fragment' -CommandType 'Alias' -Target 'Test-Function'
            $result | Should -Be $true
            
            $global:FragmentCommandRegistry.ContainsKey('tf') | Should -Be $true
            $global:FragmentCommandRegistry['tf'].Type | Should -Be 'Alias'
            $global:FragmentCommandRegistry['tf'].Target | Should -Be 'Test-Function'
        }
    }
    
    It 'Registers command with dependencies' {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $deps = @('bootstrap', 'env')
            $result = Register-FragmentCommand -CommandName 'Test-WithDeps' -FragmentName 'test-fragment' -CommandType 'Function' -Dependencies $deps
            $result | Should -Be $true
            
            $global:FragmentCommandRegistry['Test-WithDeps'].Dependencies | Should -Be $deps
        }
    }
    
    It 'Returns false for null or empty command name' {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            Register-FragmentCommand -CommandName '' -FragmentName 'test' -CommandType 'Function' | Should -Be $false
            Register-FragmentCommand -CommandName $null -FragmentName 'test' -CommandType 'Function' | Should -Be $false
        }
    }
    
    It 'Returns false for null or empty fragment name' {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            Register-FragmentCommand -CommandName 'Test' -FragmentName '' -CommandType 'Function' | Should -Be $false
            Register-FragmentCommand -CommandName 'Test' -FragmentName $null -CommandType 'Function' | Should -Be $false
        }
    }
}

Describe 'FragmentCommandRegistry.psm1 - Get-FragmentForCommand' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-Command' -FragmentName 'test-fragment' -CommandType 'Function'
        }
    }
    
    It 'Returns fragment name for registered command' {
        if (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue) {
            $fragment = Get-FragmentForCommand -CommandName 'Test-Command'
            $fragment | Should -Be 'test-fragment'
        }
    }
    
    It 'Returns null for unregistered command' {
        if (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue) {
            $fragment = Get-FragmentForCommand -CommandName 'NonExistentCommand'
            $fragment | Should -BeNullOrEmpty
        }
    }
    
    It 'Returns null for null or empty command name' {
        if (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue) {
            Get-FragmentForCommand -CommandName '' | Should -BeNullOrEmpty
            Get-FragmentForCommand -CommandName $null | Should -BeNullOrEmpty
        }
    }
}

Describe 'FragmentCommandRegistry.psm1 - Get-CommandRegistryInfo' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-Info' -FragmentName 'test-fragment' -CommandType 'Function' -Dependencies @('bootstrap')
        }
    }
    
    It 'Returns complete registry info for command' {
        if (Get-Command Get-CommandRegistryInfo -ErrorAction SilentlyContinue) {
            $info = Get-CommandRegistryInfo -CommandName 'Test-Info'
            $info | Should -Not -BeNullOrEmpty
            $info.Fragment | Should -Be 'test-fragment'
            $info.Type | Should -Be 'Function'
            $info.Dependencies | Should -Contain 'bootstrap'
            $info.ContainsKey('RegisteredAt') | Should -Be $true
        }
    }
    
    It 'Returns null for unregistered command' {
        if (Get-Command Get-CommandRegistryInfo -ErrorAction SilentlyContinue) {
            $info = Get-CommandRegistryInfo -CommandName 'NonExistentCommand'
            $info | Should -BeNullOrEmpty
        }
    }
}

Describe 'FragmentCommandRegistry.psm1 - Test-CommandInRegistry' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-Registered' -FragmentName 'test-fragment' -CommandType 'Function'
        }
    }
    
    It 'Returns true for registered command' {
        if (Get-Command Test-CommandInRegistry -ErrorAction SilentlyContinue) {
            Test-CommandInRegistry -CommandName 'Test-Registered' | Should -Be $true
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
    
    It 'Returns false when registry does not exist' {
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
}

Describe 'FragmentCommandRegistry.psm1 - Get-CommandsForFragment' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-Cmd1' -FragmentName 'fragment-a' -CommandType 'Function'
            $null = Register-FragmentCommand -CommandName 'Test-Cmd2' -FragmentName 'fragment-a' -CommandType 'Function'
            $null = Register-FragmentCommand -CommandName 'Test-Cmd3' -FragmentName 'fragment-b' -CommandType 'Function'
        }
    }
    
    It 'Returns all commands for a fragment' {
        if (Get-Command Get-CommandsForFragment -ErrorAction SilentlyContinue) {
            $commands = Get-CommandsForFragment -FragmentName 'fragment-a'
            $commands | Should -Not -BeNullOrEmpty
            $commands.Count | Should -Be 2
            $commands | Should -Contain 'Test-Cmd1'
            $commands | Should -Contain 'Test-Cmd2'
        }
    }
    
    It 'Returns empty array for fragment with no commands' {
        if (Get-Command Get-CommandsForFragment -ErrorAction SilentlyContinue) {
            $commands = Get-CommandsForFragment -FragmentName 'fragment-c'
            $commands | Should -Not -BeNullOrEmpty
            $commands.Count | Should -Be 0
        }
    }
    
    It 'Returns empty array when registry does not exist' {
        if (Get-Command Get-CommandsForFragment -ErrorAction SilentlyContinue) {
            # Temporarily remove registry
            $originalRegistry = $global:FragmentCommandRegistry
            Remove-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue
            
            try {
                $commands = Get-CommandsForFragment -FragmentName 'fragment-a'
                $commands | Should -Not -BeNullOrEmpty
                $commands.Count | Should -Be 0
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
    
    It 'Handles invalid registry entries gracefully' {
        if (Get-Command Get-CommandsForFragment -ErrorAction SilentlyContinue) {
            # Add an invalid entry directly to the registry
            $global:FragmentCommandRegistry['InvalidEntry'] = $null
            
            { $commands = Get-CommandsForFragment -FragmentName 'fragment-a' } | Should -Not -Throw
            $commands | Should -Not -BeNullOrEmpty
        }
    }
    
    It 'Returns empty array for null or empty fragment name' {
        if (Get-Command Get-CommandsForFragment -ErrorAction SilentlyContinue) {
            Get-CommandsForFragment -FragmentName '' | Should -Not -BeNullOrEmpty
            (Get-CommandsForFragment -FragmentName '').Count | Should -Be 0
            Get-CommandsForFragment -FragmentName $null | Should -Not -BeNullOrEmpty
            (Get-CommandsForFragment -FragmentName $null).Count | Should -Be 0
        }
    }
}

Describe 'FragmentCommandRegistry.psm1 - Export-CommandRegistry and Import-CommandRegistry' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-Export1' -FragmentName 'test-fragment' -CommandType 'Function'
            $null = Register-FragmentCommand -CommandName 'Test-Export2' -FragmentName 'test-fragment' -CommandType 'Function'
        }
    }
    
    It 'Exports registry to JSON string' {
        if (Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue) {
            $json = Export-CommandRegistry
            $json | Should -Not -BeNullOrEmpty
            $json | Should -Match 'Test-Export1'
            $json | Should -Match 'Test-Export2'
        }
    }
    
    It 'Exports registry to file' {
        if (Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue) {
            $exportPath = Join-Path $TestDrive 'registry.json'
            Export-CommandRegistry -Path $exportPath
            
            Test-Path -LiteralPath $exportPath | Should -Be $true
            $content = Get-Content -Path $exportPath -Raw
            $content | Should -Match 'Test-Export1'
        }
    }
    
    It 'Exports empty registry when registry does not exist' {
        if (Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue) {
            # Temporarily remove registry
            $originalRegistry = $global:FragmentCommandRegistry
            Remove-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue
            
            try {
                $json = Export-CommandRegistry
                $json | Should -Not -BeNullOrEmpty
                $json | Should -Match '^\s*\{\s*\}\s*$'
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
    
    It 'Handles file write errors gracefully' {
        if (Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue) {
            # Try to write to invalid path
            $invalidPath = Join-Path $TestDrive 'nonexistent\subdir\registry.json'
            { Export-CommandRegistry -Path $invalidPath } | Should -Throw
        }
    }
    
    It 'Imports registry from JSON string' {
        $hasExport = Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue
        $hasImport = Get-Command Import-CommandRegistry -ErrorAction SilentlyContinue
        if ($hasExport -and $hasImport) {
            # Export current registry
            $json = Export-CommandRegistry
            
            # Clear registry
            $global:FragmentCommandRegistry.Clear()
            
            # Import
            Import-CommandRegistry -Json $json
            
            # Verify
            $global:FragmentCommandRegistry.ContainsKey('Test-Export1') | Should -Be $true
        }
    }
    
    It 'Imports registry from file' {
        $hasExport = Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue
        $hasImport = Get-Command Import-CommandRegistry -ErrorAction SilentlyContinue
        if ($hasExport -and $hasImport) {
            $exportPath = Join-Path $TestDrive 'registry-import.json'
            Export-CommandRegistry -Path $exportPath
            
            # Clear registry
            $global:FragmentCommandRegistry.Clear()
            
            # Import
            Import-CommandRegistry -Path $exportPath
            
            # Verify
            $global:FragmentCommandRegistry.ContainsKey('Test-Export1') | Should -Be $true
        }
    }
    
    It 'Merges imported registry when Merge is specified' {
        $hasExport = Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue
        $hasImport = Get-Command Import-CommandRegistry -ErrorAction SilentlyContinue
        if ($hasExport -and $hasImport) {
            # Register an existing command
            $null = Register-FragmentCommand -CommandName 'Test-Existing' -FragmentName 'test-fragment' -CommandType 'Function'
            $originalCount = $global:FragmentCommandRegistry.Count
            
            # Export and create import data with new command
            $json = Export-CommandRegistry
            $jsonObj = $json | ConvertFrom-Json | ConvertTo-Json -Depth 10
            $jsonObj = $jsonObj | ConvertFrom-Json
            $jsonObj['Test-New'] = @{
                Fragment     = 'test-fragment'
                Type         = 'Function'
                RegisteredAt = (Get-Date).ToString('o')
            }
            $newJson = $jsonObj | ConvertTo-Json -Depth 10
            
            # Import with merge
            Import-CommandRegistry -Json $newJson -Merge
            
            # Verify both commands exist
            $global:FragmentCommandRegistry.ContainsKey('Test-Existing') | Should -Be $true
            $global:FragmentCommandRegistry.ContainsKey('Test-New') | Should -Be $true
            $global:FragmentCommandRegistry.Count | Should -BeGreaterThan $originalCount
        }
    }
    
    It 'Replaces registry when Merge is not specified' {
        $hasExport = Get-Command Export-CommandRegistry -ErrorAction SilentlyContinue
        $hasImport = Get-Command Import-CommandRegistry -ErrorAction SilentlyContinue
        if ($hasExport -and $hasImport) {
            # Register an existing command
            $null = Register-FragmentCommand -CommandName 'Test-Existing' -FragmentName 'test-fragment' -CommandType 'Function'
            
            # Create import data with only new command
            $newJson = @{
                'Test-New' = @{
                    Fragment     = 'test-fragment'
                    Type         = 'Function'
                    RegisteredAt = (Get-Date).ToString('o')
                }
            } | ConvertTo-Json -Depth 10
            
            # Import without merge
            Import-CommandRegistry -Json $newJson
            
            # Verify only new command exists
            $global:FragmentCommandRegistry.ContainsKey('Test-Existing') | Should -Be $false
            $global:FragmentCommandRegistry.ContainsKey('Test-New') | Should -Be $true
        }
    }
    
    It 'Handles missing import file gracefully' {
        if (Get-Command Import-CommandRegistry -ErrorAction SilentlyContinue) {
            $missingPath = Join-Path $TestDrive 'nonexistent-registry.json'
            Import-CommandRegistry -Path $missingPath | Should -Be $false
        }
    }
    
    It 'Handles invalid JSON gracefully' {
        if (Get-Command Import-CommandRegistry -ErrorAction SilentlyContinue) {
            $invalidJson = '{ invalid json }'
            { Import-CommandRegistry -Json $invalidJson } | Should -Not -Throw
        }
    }
}

Describe 'FragmentCommandRegistry.psm1 - Get-CommandRegistryStats' {
    BeforeEach {
        if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
            $null = Register-FragmentCommand -CommandName 'Test-Stats1' -FragmentName 'fragment-a' -CommandType 'Function'
            $null = Register-FragmentCommand -CommandName 'Test-Stats2' -FragmentName 'fragment-a' -CommandType 'Function'
            $null = Register-FragmentCommand -CommandName 'Test-Stats3' -FragmentName 'fragment-b' -CommandType 'Alias'
        }
    }
    
    It 'Returns registry statistics' {
        if (Get-Command Get-CommandRegistryStats -ErrorAction SilentlyContinue) {
            $stats = Get-CommandRegistryStats
            $stats | Should -Not -BeNullOrEmpty
            $stats.TotalCommands | Should -Be 3
            $stats.Fragments | Should -Be 2
            $stats.CommandsByType | Should -Not -BeNullOrEmpty
            $stats.CommandsByType['Function'] | Should -Be 2
            $stats.CommandsByType['Alias'] | Should -Be 1
            $stats.CommandsByFragment | Should -Not -BeNullOrEmpty
            $stats.CommandsByFragment['fragment-a'] | Should -Be 2
            $stats.CommandsByFragment['fragment-b'] | Should -Be 1
        }
    }
    
    It 'Returns empty stats when registry does not exist' {
        if (Get-Command Get-CommandRegistryStats -ErrorAction SilentlyContinue) {
            # Temporarily remove registry
            $originalRegistry = $global:FragmentCommandRegistry
            Remove-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue
            
            try {
                $stats = Get-CommandRegistryStats
                $stats | Should -Not -BeNullOrEmpty
                $stats.TotalCommands | Should -Be 0
                $stats.Fragments | Should -Be 0
                $stats.CommandsByType | Should -Not -BeNullOrEmpty
                $stats.CommandsByFragment | Should -Not -BeNullOrEmpty
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
    
    It 'Handles invalid registry entries gracefully' {
        if (Get-Command Get-CommandRegistryStats -ErrorAction SilentlyContinue) {
            # Add an invalid entry directly to the registry
            $global:FragmentCommandRegistry['InvalidEntry'] = $null
            
            { $stats = Get-CommandRegistryStats } | Should -Not -Throw
            $stats | Should -Not -BeNullOrEmpty
        }
    }
    
    It 'Handles entries with null fragment or type gracefully' {
        if (Get-Command Get-CommandRegistryStats -ErrorAction SilentlyContinue) {
            # Add entries with null values
            $global:FragmentCommandRegistry['NullFragment'] = @{ Fragment = $null; Type = 'Function' }
            $global:FragmentCommandRegistry['NullType'] = @{ Fragment = 'test'; Type = $null }
            $global:FragmentCommandRegistry['EmptyFragment'] = @{ Fragment = ''; Type = 'Function' }
            $global:FragmentCommandRegistry['EmptyType'] = @{ Fragment = 'test'; Type = '' }
            
            { $stats = Get-CommandRegistryStats } | Should -Not -Throw
            $stats | Should -Not -BeNullOrEmpty
        }
    }
}
