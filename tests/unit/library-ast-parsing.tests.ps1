. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import FileContent module first (dependency)
    $fileContentPath = Join-Path $script:LibPath 'file' 'FileContent.psm1'
    if (Test-Path $fileContentPath) {
        Import-Module $fileContentPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    $script:AstParsingPath = Join-Path $script:LibPath 'code-analysis' 'AstParsing.psm1'
    Import-Module $script:AstParsingPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory and files
    $script:TestDir = Join-Path $env:TEMP "test-ast-parsing-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    # Create test PowerShell file with functions
    $script:TestScript = Join-Path $script:TestDir 'test-script.ps1'
    $testContent = @'
    function Test-Function1 {
        param([string]$Param1)
        Write-Host "Test 1"
    }

    function Test-Function2 {
        param([int]$Param2)
        Write-Host "Test 2"
    }

    function global:InternalFunction {
        Write-Host "Internal"
    }
'@
    Set-Content -Path $script:TestScript -Value $testContent -Encoding UTF8
    
    # Create empty file
    $script:EmptyScript = Join-Path $script:TestDir 'empty.ps1'
    Set-Content -Path $script:EmptyScript -Value '' -Encoding UTF8
}

AfterAll {
    Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
    Remove-Module FileContent -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'AstParsing Module Functions' {
    Context 'Get-PowerShellAst' {
        It 'Parses valid PowerShell file' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $ast | Should -Not -BeNullOrEmpty
            $ast | Should -BeOfType [System.Management.Automation.Language.ScriptBlockAst]
        }

        It 'Throws error for non-existent file' {
            $nonExistentFile = Join-Path $script:TestDir 'nonexistent.ps1'
            { Get-PowerShellAst -Path $nonExistentFile } | Should -Throw "*not found*"
        }

        It 'Throws error for empty file' {
            { Get-PowerShellAst -Path $script:EmptyScript } | Should -Throw "*empty*"
        }

        It 'Throws error for invalid PowerShell syntax' {
            $invalidScript = Join-Path $script:TestDir 'invalid.ps1'
            Set-Content -Path $invalidScript -Value '{ invalid syntax }' -Encoding UTF8
            { Get-PowerShellAst -Path $invalidScript } | Should -Throw
        }

        It 'Uses Read-FileContent when available' {
            # Function should use Read-FileContent if available
            $ast = Get-PowerShellAst -Path $script:TestScript
            $ast | Should -Not -BeNullOrEmpty
        }

        It 'Falls back to Get-Content when Read-FileContent not available' {
            # Temporarily remove FileContent module
            Remove-Module FileContent -ErrorAction SilentlyContinue -Force
            
            $ast = Get-PowerShellAst -Path $script:TestScript
            $ast | Should -Not -BeNullOrEmpty
            
            # Re-import FileContent
            $fileContentPath = Join-Path $script:LibPath 'file' 'FileContent.psm1'
            if (Test-Path $fileContentPath) {
                Import-Module $fileContentPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
        }
    }

    Context 'Get-FunctionsFromAst' {
        It 'Finds all functions in AST' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast
            $functions | Should -Not -BeNullOrEmpty
            $functions.Count | Should -BeGreaterOrEqual 2
        }

        It 'Excludes internal functions by default' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast
            $functionNames = $functions | ForEach-Object { $_.Name }
            $functionNames | Should -Not -Contain 'global:InternalFunction'
        }

        It 'Includes internal functions when IncludeInternal specified' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast -IncludeInternal
            $functionNames = $functions | ForEach-Object { $_.Name }
            $functionNames | Should -Contain 'global:InternalFunction'
        }

        It 'Returns FunctionDefinitionAst objects' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast
            $functions | ForEach-Object {
                $_ | Should -BeOfType [System.Management.Automation.Language.FunctionDefinitionAst]
            }
        }
    }

    Context 'Get-FunctionSignature' {
        It 'Extracts function signature' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast
            $func1 = $functions | Where-Object { $_.Name -eq 'Test-Function1' } | Select-Object -First 1
            
            $signature = Get-FunctionSignature -FuncAst $func1
            $signature | Should -Not -BeNullOrEmpty
            $signature | Should -Match 'Test-Function1'
        }

        It 'Includes parameter information in signature' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast
            $func1 = $functions | Where-Object { $_.Name -eq 'Test-Function1' } | Select-Object -First 1
            
            $signature = Get-FunctionSignature -FuncAst $func1
            $signature | Should -Match 'Param1'
        }

        It 'Handles functions without parameters' {
            $testScriptNoParams = Join-Path $script:TestDir 'no-params.ps1'
            $content = 'function Test-NoParams { Write-Host "test" }'
            Set-Content -Path $testScriptNoParams -Value $content -Encoding UTF8
            
            $ast = Get-PowerShellAst -Path $testScriptNoParams
            $functions = Get-FunctionsFromAst -Ast $ast
            $func = $functions | Select-Object -First 1
            
            $signature = Get-FunctionSignature -FuncAst $func
            $signature | Should -Not -BeNullOrEmpty
            $signature | Should -Match 'Test-NoParams'
        }
    }

    Context 'Get-TextBeforeFunction' {
        It 'Extracts text before function' {
            $ast = Get-PowerShellAst -Path $script:TestScript
            $functions = Get-FunctionsFromAst -Ast $ast
            $func1 = $functions | Where-Object { $_.Name -eq 'Test-Function1' } | Select-Object -First 1
            
            $content = Get-Content -Path $script:TestScript -Raw
            $beforeText = Get-TextBeforeFunction -FuncAst $func1 -Content $content
            $beforeText | Should -Not -BeNullOrEmpty
        }

        It 'Returns empty string when function is at start of file' {
            $testScriptStart = Join-Path $script:TestDir 'start.ps1'
            $content = 'function Test-Start { }'
            Set-Content -Path $testScriptStart -Value $content -Encoding UTF8
            
            $ast = Get-PowerShellAst -Path $testScriptStart
            $functions = Get-FunctionsFromAst -Ast $ast
            $func = $functions | Select-Object -First 1
            
            $content = Get-Content -Path $testScriptStart -Raw
            $beforeText = Get-TextBeforeFunction -FuncAst $func -Content $content
            $beforeText | Should -BeNullOrEmpty
        }
    }
}

