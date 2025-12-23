. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:SafeImportPath = Join-Path $script:LibPath 'core' 'SafeImport.psm1'
    
    # Import Validation module first (dependency)
    $validationPath = Join-Path $script:LibPath 'core' 'Validation.psm1'
    if (Test-Path $validationPath) {
        Import-Module $validationPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    Import-Module $script:SafeImportPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module SafeImport -ErrorAction SilentlyContinue -Force
    Remove-Module Validation -ErrorAction SilentlyContinue -Force
}

Describe 'SafeImport Module Functions' {
    Context 'Test-ModulePath' {
        BeforeEach {
            $script:TestDir = Join-Path $TestDrive 'TestSafeImport'
            $script:TestModule = Join-Path $script:TestDir 'TestModule.psm1'
            New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
            Set-Content -Path $script:TestModule -Value '# Test module'
        }

        AfterEach {
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Returns true for existing module files' {
            Test-ModulePath -ModulePath $script:TestModule | Should -Be $true
        }

        It 'Returns false for non-existent module files' {
            Test-ModulePath -ModulePath (Join-Path $script:TestDir 'Nonexistent.psm1') | Should -Be $false
        }

        It 'Returns false for null paths' {
            Test-ModulePath -ModulePath $null | Should -Be $false
        }

        It 'Returns false for empty string paths' {
            Test-ModulePath -ModulePath '' | Should -Be $false
        }

        It 'Returns false for directory paths' {
            Test-ModulePath -ModulePath $script:TestDir | Should -Be $false
        }

        It 'Accepts FileInfo objects' {
            $fileInfo = Get-Item $script:TestModule
            Test-ModulePath -ModulePath $fileInfo | Should -Be $true
        }
    }

    Context 'Import-ModuleSafely' {
        BeforeEach {
            $script:TestDir = Join-Path $TestDrive 'TestImportSafely'
            $script:TestModule = Join-Path $script:TestDir 'TestModule.psm1'
            New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
            
            # Create a simple test module
            $moduleContent = @'
function Test-ExportedFunction {
    return 'test-result'
}
Export-ModuleMember -Function 'Test-ExportedFunction'
'@
            Set-Content -Path $script:TestModule -Value $moduleContent
        }

        AfterEach {
            Remove-Module TestModule -ErrorAction SilentlyContinue -Force
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Imports existing module successfully' {
            $module = Import-ModuleSafely -ModulePath $script:TestModule -ErrorAction Stop
            $module | Should -Not -BeNullOrEmpty
            $module.Name | Should -Be 'TestModule'
        }

        It 'Returns null for non-existent module when not required' {
            $module = Import-ModuleSafely -ModulePath (Join-Path $script:TestDir 'Nonexistent.psm1') `
                -ErrorAction SilentlyContinue
            $module | Should -BeNullOrEmpty
        }

        It 'Throws for non-existent module when required' {
            { Import-ModuleSafely -ModulePath (Join-Path $script:TestDir 'Nonexistent.psm1') -Required } | Should -Throw
        }

        It 'Imports with DisableNameChecking' {
            $module = Import-ModuleSafely -ModulePath $script:TestModule -DisableNameChecking -ErrorAction Stop
            $module | Should -Not -BeNullOrEmpty
        }

        It 'Imports into global scope when specified' {
            $module = Import-ModuleSafely -ModulePath $script:TestModule -Global -ErrorAction Stop
            $module | Should -Not -BeNullOrEmpty
        }

        It 'Handles import errors gracefully when not required' {
            # Create a module with syntax errors
            $badModule = Join-Path $script:TestDir 'BadModule.psm1'
            Set-Content -Path $badModule -Value 'invalid syntax {'
            
            $module = Import-ModuleSafely -ModulePath $badModule -ErrorAction SilentlyContinue
            $module | Should -BeNullOrEmpty
        }

        It 'Throws on import errors when ErrorAction is Stop' {
            $badModule = Join-Path $script:TestDir 'BadModule.psm1'
            Set-Content -Path $badModule -Value 'invalid syntax {'
            
            { Import-ModuleSafely -ModulePath $badModule -ErrorAction Stop } | Should -Throw
        }

        It 'Exports functions from imported module' {
            $module = Import-ModuleSafely -ModulePath $script:TestModule -ErrorAction Stop
            $module | Should -Not -BeNullOrEmpty
            # Verify module was imported
            $module.Name | Should -Be 'TestModule'
            # Check that the function is exported by the module
            # The module object returned by Import-Module contains ExportedCommands which
            # is the authoritative source for what functions are exported
            $module.ExportedCommands.Keys | Should -Contain 'Test-ExportedFunction'
            # Verify the exported command object exists and has correct properties
            $exportedCmd = $module.ExportedCommands['Test-ExportedFunction']
            $exportedCmd | Should -Not -BeNullOrEmpty
            $exportedCmd.Name | Should -Be 'Test-ExportedFunction'
            # Note: When modules are imported by path (not by name), Get-Module may not
            # find them by name in all PowerShell versions. The module object returned
            # by Import-ModuleSafely is the authoritative source for verification.
        }
    }

    Context 'Get-ModulePath' {
        BeforeEach {
            $script:TestDir = Join-Path $TestDrive 'TestGetModulePath'
            $script:TestModule = Join-Path $script:TestDir 'TestModule.psm1'
            New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
            Set-Content -Path $script:TestModule -Value '# Test module'
        }

        AfterEach {
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Resolves absolute paths' {
            $result = Get-ModulePath -ModulePath $script:TestModule
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be (Resolve-Path $script:TestModule).Path
        }

        It 'Resolves relative paths with base path' {
            $relativePath = 'TestModule.psm1'
            $result = Get-ModulePath -ModulePath $relativePath -BasePath $script:TestDir
            $result | Should -Be (Resolve-Path $script:TestModule).Path
        }

        It 'Returns null for non-existent paths when MustExist is true' {
            $result = Get-ModulePath -ModulePath (Join-Path $script:TestDir 'Nonexistent.psm1')
            $result | Should -BeNullOrEmpty
        }

        It 'Returns path for non-existent paths when MustExist is false' {
            $nonExistentPath = Join-Path $script:TestDir 'Nonexistent.psm1'
            $result = Get-ModulePath -ModulePath $nonExistentPath -MustExist:$false
            $result | Should -Not -BeNullOrEmpty
            # Get-ModulePath should return the resolved path even if file doesn't exist
            $expectedPath = (Resolve-Path (Split-Path $nonExistentPath -Parent)).Path
            $expectedPath = Join-Path $expectedPath 'Nonexistent.psm1'
            $result | Should -Be $expectedPath
        }

        It 'Returns null for null input' {
            Get-ModulePath -ModulePath $null | Should -BeNullOrEmpty
        }

        It 'Returns null for empty string input' {
            Get-ModulePath -ModulePath '' | Should -BeNullOrEmpty
        }

        It 'Normalizes path separators' {
            $result = Get-ModulePath -ModulePath $script:TestModule
            $result | Should -Not -Match '/'
        }
    }
}

