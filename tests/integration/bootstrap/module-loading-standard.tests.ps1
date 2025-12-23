# ===============================================
# Integration Tests for Standardized Module Loading System
# ===============================================
# Tests the Import-FragmentModule, Import-FragmentModules, and Test-FragmentModulePath functions
# in a real fragment loading environment

BeforeAll {
    # Load TestSupport for helper functions
    . $PSScriptRoot/../../TestSupport.ps1
    
    # Get test repository root
    $testRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    
    # Load bootstrap to get module loading functions
    $bootstrapPath = Join-Path $testRepoRoot 'profile.d' 'bootstrap.ps1'
    if (-not (Test-Path -LiteralPath $bootstrapPath)) {
        throw "Bootstrap file not found at: $bootstrapPath"
    }
    
    # Clear any existing fragment loading state
    $global:__psprofile_fragment_loaded = @{}
    
    # Load bootstrap
    . $bootstrapPath
    
    # Verify module loading functions are available
    if (-not (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue)) {
        throw "Import-FragmentModule not available after loading bootstrap"
    }
    if (-not (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue)) {
        throw "Import-FragmentModules not available after loading bootstrap"
    }
    if (-not (Get-Command Test-FragmentModulePath -ErrorAction SilentlyContinue)) {
        throw "Test-FragmentModulePath not available after loading bootstrap"
    }
    
    # Create test fragment root directory
    $script:testFragmentRoot = Join-Path $TestDrive 'test-fragments'
    New-Item -ItemType Directory -Path $script:testFragmentRoot -Force | Out-Null
    
    # Create test module structure
    $testModulesDir = Join-Path $script:testFragmentRoot 'test-modules'
    New-Item -ItemType Directory -Path $testModulesDir -Force | Out-Null
    
    # Create a simple test module (use global scope to ensure function is accessible)
    $testModuleContent = @'
function global:Test-ModuleFunction {
    param([string]$Message = "Hello from test module")
    Write-Output $Message
}
'@
    $testModulePath = Join-Path $testModulesDir 'test-module.ps1'
    Set-Content -Path $testModulePath -Value $testModuleContent -NoNewline
    
    # Create a subdirectory module
    $subDir = Join-Path $testModulesDir 'subdir'
    New-Item -ItemType Directory -Path $subDir -Force | Out-Null
    $subModulePath = Join-Path $subDir 'sub-module.ps1'
    Set-Content -Path $subModulePath -Value $testModuleContent -NoNewline
}

AfterAll {
    # Cleanup
    if (Test-Path -LiteralPath $script:testFragmentRoot) {
        Remove-Item -Path $script:testFragmentRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Module Loading System Integration Tests" {
    Context "Import-FragmentModule - Basic Loading" {
        It "Loads a simple module from test directory" {
            # Remove function if it exists from previous test
            Remove-Item Function:Test-ModuleFunction -Force -ErrorAction SilentlyContinue
            Remove-Item Function:global:Test-ModuleFunction -Force -ErrorAction SilentlyContinue
            
            $result = Import-FragmentModule `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'test-module.ps1') `
                -Context "Test: test-module.ps1"
            
            $result | Should -Be $true
            
            # Verify function was loaded (should be in global scope)
            $cmd = Get-Command Test-ModuleFunction -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
            
            # Verify function works
            $output = Test-ModuleFunction -Message "test"
            $output | Should -Be "test"
        }
        
        It "Loads a module from subdirectory" {
            $result = Import-FragmentModule `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'subdir', 'sub-module.ps1') `
                -Context "Test: sub-module.ps1"
            
            $result | Should -Be $true
        }
        
        It "Returns false for non-existent module" {
            $result = Import-FragmentModule `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'nonexistent.ps1') `
                -Context "Test: nonexistent.ps1"
            
            $result | Should -Be $false
        }
    }
    
    Context "Import-FragmentModules - Batch Loading" {
        It "Loads multiple modules in batch" {
            $modules = @(
                @{ ModulePath = @('test-modules', 'test-module.ps1'); Context = 'Test: batch-module-1' },
                @{ ModulePath = @('test-modules', 'subdir', 'sub-module.ps1'); Context = 'Test: batch-module-2' }
            )
            
            $result = Import-FragmentModules `
                -FragmentRoot $script:testFragmentRoot `
                -Modules $modules
            
            $result.SuccessCount | Should -Be 2
            $result.FailureCount | Should -Be 0
            $result.Results.Count | Should -Be 2
        }
        
        It "Handles mixed valid and invalid modules" {
            $modules = @(
                @{ ModulePath = @('test-modules', 'test-module.ps1'); Context = 'Test: valid-module' },
                @{ ModulePath = @('test-modules', 'nonexistent.ps1'); Context = 'Test: invalid-module' }
            )
            
            $result = Import-FragmentModules `
                -FragmentRoot $script:testFragmentRoot `
                -Modules $modules
            
            $result.SuccessCount | Should -Be 1
            $result.FailureCount | Should -Be 1
            $result.Failed | Should -Contain 'Test: invalid-module'
        }
    }
    
    Context "Test-FragmentModulePath - Path Validation" {
        It "Validates existing module path" {
            $result = Test-FragmentModulePath `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'test-module.ps1')
            
            $result | Should -Be $true
        }
        
        It "Validates non-existent module path" {
            $result = Test-FragmentModulePath `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'nonexistent.ps1')
            
            $result | Should -Be $false
        }
        
        It "Validates path using full path parameter" {
            $fullPath = Join-Path $script:testFragmentRoot 'test-modules' 'test-module.ps1'
            $result = Test-FragmentModulePath -Path $fullPath
            
            $result | Should -Be $true
        }
    }
    
    Context "Integration with Real Fragments" {
        It "Can load actual fragment modules using standardized system" {
            $testRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            $profileDir = Join-Path $testRepoRoot 'profile.d'
            
            # Test loading a simple module from an actual fragment
            # Use a module that should exist (like from system)
            $systemModulePath = Join-Path $profileDir 'system' 'FileOperations.ps1'
            if (Test-Path -LiteralPath $systemModulePath) {
                $result = Import-FragmentModule `
                    -FragmentRoot $profileDir `
                    -ModulePath @('system', 'FileOperations.ps1') `
                    -Context "Integration: FileOperations.ps1"
                
                $result | Should -Be $true
            }
        }
    }
    
    Context "Error Handling and Fallback" {
        It "Handles missing fragment root gracefully" {
            $result = Import-FragmentModule `
                -FragmentRoot '' `
                -ModulePath @('test-modules', 'test-module.ps1') `
                -Context "Test: empty-root"
            
            $result | Should -Be $false
        }
        
        It "Handles empty module path gracefully" {
            # Empty array causes parameter binding error, so we expect an exception
            { Import-FragmentModule `
                    -FragmentRoot $script:testFragmentRoot `
                    -ModulePath @() `
                    -Context "Test: empty-path" `
                    -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context "Caching and Performance" {
        It "Uses path caching when CacheResults is enabled" {
            # First call should cache
            $result1 = Import-FragmentModule `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'test-module.ps1') `
                -Context "Test: cache-test-1" `
                -CacheResults
            
            $result1 | Should -Be $true
            
            # Second call should use cache
            $result2 = Import-FragmentModule `
                -FragmentRoot $script:testFragmentRoot `
                -ModulePath @('test-modules', 'test-module.ps1') `
                -Context "Test: cache-test-2" `
                -CacheResults
            
            $result2 | Should -Be $true
        }
    }
}

