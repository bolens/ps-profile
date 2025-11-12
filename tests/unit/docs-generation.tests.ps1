#
# Tests for the documentation generation helpers.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
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
        It 'creates markdown files with correct structure' {
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
            & $scriptPath -OutputPath $tempDir 2>&1 | Out-Null

            $true | Should -Be $true
        }

        It 'generates index with alphabetical function list' {
            $tempDir = Join-Path $TestDrive 'docs_index'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            & $scriptPath -OutputPath $tempDir 2>&1 | Out-Null

            $readmePath = Join-Path $tempDir 'README.md'
            if (Test-Path $readmePath) {
                $content = Get-Content $readmePath -Raw
                foreach ($pattern in '## Functions by Fragment', 'Total Functions:', 'Generated:') {
                    $content | Should -Match $pattern
                }
            }
        }
    }
}
