<#
tests/unit/module-import.tests.ps1

.SYNOPSIS
    Unit tests for ModuleImport.psm1 module functions.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import PathResolution first (ModuleImport depends on it)
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

    # Import the ModuleImport module
    $moduleImportPath = Get-TestPath -RelativePath 'scripts\lib\ModuleImport.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
}

Describe 'Get-LibPath' {
    Context 'Valid script path handling' {
        It 'Returns scripts/lib path for scripts/utils/ location' {
            # Find an existing utility script dynamically
            $searchRoot = Get-TestPath -RelativePath 'scripts' -StartPath $PSScriptRoot -EnsureExists
            $candidate = Get-ChildItem -Path $searchRoot -Filter 'run-lint.ps1' -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1

            $candidate | Should -Not -BeNullOrEmpty -Because 'run-lint.ps1 should exist within scripts/utils'

            $libPath = Get-LibPath -ScriptPath $candidate.FullName
            $libPath | Should -Exist
            $libPath | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $candidate.FullName) 'scripts' 'lib')
            
            # Verify it's actually scripts/lib by checking for known modules
            (Test-Path (Join-Path $libPath 'ExitCodes.psm1')) | Should -Be $true
            (Test-Path (Join-Path $libPath 'Logging.psm1')) | Should -Be $true
            (Test-Path (Join-Path $libPath 'PathResolution.psm1')) | Should -Be $true
        }

        It 'Returns scripts/lib path for scripts/checks/ location' {
            $relativePath = Get-TestPath -RelativePath 'scripts\checks\check-script-standards.ps1' -StartPath $PSScriptRoot
            $actualScriptPath = if (Test-Path $relativePath) {
                (Resolve-Path $relativePath).Path
            }
            else {
                $scriptsChecksDir = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
                Join-Path $scriptsChecksDir 'check-script-standards.ps1'
            }

            if (Test-Path $actualScriptPath) {
                $libPath = Get-LibPath -ScriptPath $actualScriptPath
                $libPath | Should -Exist
                $libPath | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $actualScriptPath) 'scripts' 'lib')
            }
            else {
                Set-ItResult -Skipped -Because "Test script not found at $actualScriptPath"
            }
        }

        It 'Returns scripts/lib path for scripts/lib/ location' {
            $libScriptPath = Get-TestPath -RelativePath 'scripts\lib\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
            $libPath = Get-LibPath -ScriptPath $libScriptPath
            $libPath | Should -Exist
            $libPath | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $libScriptPath) 'scripts' 'lib')
        }

        It 'Returns scripts/lib path for scripts/git/ location' {
            $gitScriptPath = Get-TestPath -RelativePath 'scripts\git\install-githooks.ps1' -StartPath $PSScriptRoot
            if (Test-Path $gitScriptPath) {
                $libPath = Get-LibPath -ScriptPath $gitScriptPath
                $libPath | Should -Exist
                $libPath | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $gitScriptPath) 'scripts' 'lib')
            }
            else {
                Set-ItResult -Skipped -Because "Test script not found at $gitScriptPath"
            }
        }
    }

    Context 'Caching behavior' {
        It 'Caches lib path resolution' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            
            # First call
            $libPath1 = Get-LibPath -ScriptPath $testScriptPath
            
            # Second call should return cached result
            $libPath2 = Get-LibPath -ScriptPath $testScriptPath
            
            $libPath1 | Should -Be $libPath2
        }
    }

    Context 'Error handling' {
        It 'Throws error for invalid script path' {
            { Get-LibPath -ScriptPath 'C:\Invalid\Path\script.ps1' } | Should -Throw
        }
    }
}

Describe 'Import-LibModule' {
    Context 'Valid module imports' {
        It 'Imports existing module successfully' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            
            # Remove module if already loaded
            Remove-Module -Name 'ExitCodes' -ErrorAction SilentlyContinue
            
            $module = Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $testScriptPath -DisableNameChecking -Global
            $module | Should -Not -BeNullOrEmpty
            $module.Name | Should -Be 'ExitCodes'
            
            # Verify module is actually loaded
            Get-Module -Name 'ExitCodes' | Should -Not -BeNullOrEmpty
        }

        It 'Imports module without .psm1 extension' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            
            Remove-Module -Name 'Logging' -ErrorAction SilentlyContinue
            
            $module = Import-LibModule -ModuleName 'Logging' -ScriptPath $testScriptPath -DisableNameChecking -Global
            $module | Should -Not -BeNullOrEmpty
            Get-Module -Name 'Logging' | Should -Not -BeNullOrEmpty
        }

        It 'Imports module with .psm1 extension' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            
            Remove-Module -Name 'PathResolution' -ErrorAction SilentlyContinue
            
            $module = Import-LibModule -ModuleName 'PathResolution.psm1' -ScriptPath $testScriptPath -DisableNameChecking -Global
            $module | Should -Not -BeNullOrEmpty
            Get-Module -Name 'PathResolution' | Should -Not -BeNullOrEmpty
        }

        It 'Imports module with DisableNameChecking switch' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            
            Remove-Module -Name 'ExitCodes' -ErrorAction SilentlyContinue
            
            { Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $testScriptPath -DisableNameChecking } | Should -Not -Throw
        }
    }

    Context 'Error handling' {
        It 'Throws error for non-existent module when Required is true' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            $nonExistentModule = "NonExistentModule_$(New-Guid)"
            
            { Import-LibModule -ModuleName $nonExistentModule -ScriptPath $testScriptPath -Required:$true } | Should -Throw
        }

        It 'Returns null for non-existent module when Required is false' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            $nonExistentModule = "NonExistentModule_$(New-Guid)"
            
            $result = Import-LibModule -ModuleName $nonExistentModule -ScriptPath $testScriptPath -Required:$false -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Throws error for invalid script path' {
            { Import-LibModule -ModuleName 'ExitCodes' -ScriptPath 'C:\Invalid\Path\script.ps1' } | Should -Throw
        }
    }

    Context 'ErrorAction parameter' {
        It 'Respects ErrorAction Stop' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            $nonExistentModule = "NonExistentModule_$(New-Guid)"
            
            { Import-LibModule -ModuleName $nonExistentModule -ScriptPath $testScriptPath -ErrorAction Stop } | Should -Throw
        }

        It 'Respects ErrorAction SilentlyContinue' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            $nonExistentModule = "NonExistentModule_$(New-Guid)"
            
            $result = Import-LibModule -ModuleName $nonExistentModule -ScriptPath $testScriptPath -ErrorAction SilentlyContinue -Required:$false
            $result | Should -BeNullOrEmpty
        }
    }
}

