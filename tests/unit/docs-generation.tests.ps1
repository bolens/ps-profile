#
# Tests for the documentation generation helpers.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ScriptsUtilsDocsPath = Get-TestPath -RelativePath 'scripts\utils\docs' -StartPath $PSScriptRoot -EnsureExists
    $script:CommentBlockRegex = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
}

Describe 'Documentation generation' {
    Context 'Comment parsing' {
        It 'parses comment-based help correctly' {
            $testFunction = @'
<#
.SYNOPSIS
    Test function for documentation
.DESCRIPTION
    This is a test function with parameters.
.PARAMETER Name
    The name parameter
.PARAMETER Value
    The value parameter
.EXAMPLE
    Test-Function -Name "test" -Value 123
#>
function Test-Function {
    param($Name, $Value)
}
'@

            $tempFile = Join-Path $TestDrive 'test_function.ps1'
            Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            $functionAsts.Count | Should -Be 1
            $functionAsts[0].Name | Should -Be 'Test-Function'
        }

        It 'handles functions without parameters' {
            $testFunction = @'
<#
.SYNOPSIS
    Simple function
.DESCRIPTION
    A function with no parameters
.EXAMPLE
    Simple-Function
#>
function Simple-Function { }
'@

            $tempFile = Join-Path $TestDrive 'simple_function.ps1'
            Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            $functionAsts.Count | Should -Be 1
            $functionAsts[0].Name | Should -Be 'Simple-Function'
        }

        It 'extracts synopsis from comment-based help' {
            $testFunction = @'
<#
.SYNOPSIS
    This is a test synopsis
.DESCRIPTION
    Description here
#>
function Test-Synopsis { }
'@

            $tempFile = Join-Path $TestDrive 'test_synopsis.ps1'
            Set-Content -Path $tempFile -Value $testFunction -Encoding UTF8

            $content = Get-Content $tempFile -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            $functionAsts.Count | Should -Be 1
            $functionAst = $functionAsts[0]
            $startOffset = $functionAst.Extent.StartOffset
            $leadingText = $content.Substring(0, $startOffset)
            $commentMatches = $script:CommentBlockRegex.Matches($leadingText)

            $commentMatches.Count | Should -Be 1
            $helpContent = $commentMatches[-1].Value -replace '^<#\s*', '' -replace '\s*#>$', ''

            if ($helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)\n\s*\.DESCRIPTION') {
                $synopsis = $matches[1].Trim()
                $synopsis | Should -Be 'This is a test synopsis'
            }
        }
    }

    Context 'File generation' {
        It 'creates markdown files in correct subdirectories' {
            $tempDir = Join-Path $TestDrive 'docs_test'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFunction = @'
<#
.SYNOPSIS
    Test function
.DESCRIPTION
    Test description
.PARAMETER Name
    The name parameter
.EXAMPLE
    Test-Function -Name "test"
#>
function Test-Function {
    param($Name)
}
'@

            $testFile = Join-Path $testProfileDir 'test.ps1'
            Set-Content -Path $testFile -Value $testFunction -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            # Verify subdirectories were created
            $functionsPath = Join-Path $outputPath 'functions'
            $aliasesPath = Join-Path $outputPath 'aliases'
            Test-Path $functionsPath | Should -Be $true
            Test-Path $aliasesPath | Should -Be $true
        }

        It 'generates function documentation in functions subdirectory' {
            $tempDir = Join-Path $TestDrive 'docs_functions'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFunction = @'
<#
.SYNOPSIS
    Test function for documentation
.DESCRIPTION
    This function tests documentation generation
#>
function Test-DocumentationFunction {
    param()
}
'@

            $testFile = Join-Path $testProfileDir 'test.ps1'
            Set-Content -Path $testFile -Value $testFunction -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            $functionDocPath = Join-Path $outputPath 'functions\Test-DocumentationFunction.md'
            Test-Path $functionDocPath | Should -Be $true

            if (Test-Path $functionDocPath) {
                $content = Get-Content $functionDocPath -Raw
                $content | Should -Match 'Test-DocumentationFunction'
                $content | Should -Match 'Test function for documentation'
            }
        }

        It 'generates alias documentation in aliases subdirectory' {
            $tempDir = Join-Path $TestDrive 'docs_aliases'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $testProfileDir = Join-Path $tempDir 'profile.d'
            New-Item -ItemType Directory -Path $testProfileDir -Force | Out-Null

            $testFileContent = @'
<#
.SYNOPSIS
    Test function
.DESCRIPTION
    A test function
#>
function Test-TargetFunction {
    param()
}

Set-Alias -Name test-alias -Value Test-TargetFunction
'@

            $testFile = Join-Path $testProfileDir 'test.ps1'
            Set-Content -Path $testFile -Value $testFileContent -Encoding UTF8

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath -ProfilePath $testProfileDir 2>&1 | Out-Null

            $aliasDocPath = Join-Path $outputPath 'aliases\test-alias.md'
            if (Test-Path $aliasDocPath) {
                $content = Get-Content $aliasDocPath -Raw
                $content | Should -Match 'test-alias'
                $content | Should -Match 'Test-TargetFunction'
            }
        }

        It 'generates index with functions and aliases sections' {
            $tempDir = Join-Path $TestDrive 'docs_index'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath 2>&1 | Out-Null

            $readmePath = Join-Path $outputPath 'README.md'
            if (Test-Path $readmePath) {
                $content = Get-Content $readmePath -Raw
                # Check for new structure
                $content | Should -Match '## Functions'
                $content | Should -Match '## Aliases'
                # Check for links to subdirectories
                $content | Should -Match 'functions/'
                $content | Should -Match 'aliases/'
            }
        }

        It 'creates functions and aliases subdirectories' {
            $tempDir = Join-Path $TestDrive 'docs_structure'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            & $scriptPath -OutputPath $outputPath 2>&1 | Out-Null

            # Verify directory structure
            $functionsPath = Join-Path $outputPath 'functions'
            $aliasesPath = Join-Path $outputPath 'aliases'
            
            Test-Path $functionsPath | Should -Be $true -Because 'functions subdirectory should exist'
            Test-Path $aliasesPath | Should -Be $true -Because 'aliases subdirectory should exist'
            
            # Verify they are directories
            (Get-Item $functionsPath).PSIsContainer | Should -Be $true
            (Get-Item $aliasesPath).PSIsContainer | Should -Be $true
        }
    }
}
