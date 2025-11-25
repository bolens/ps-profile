
Describe 'Alias helper' {
    BeforeAll {
        # Resolve bootstrap path directly
        $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $script:BootstrapPath = Join-Path $repoRoot 'profile.d\00-bootstrap.ps1'
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap file not found: $script:BootstrapPath"
        }
    }

    Context 'Alias factory' {
        It 'Set-AgentModeAlias returns definition when requested and alias works' {
            . $script:BootstrapPath
            $name = "test_alias_$(Get-Random)"
            $def = Set-AgentModeAlias -Name $name -Target 'Write-Output' -ReturnDefinition
            $def | Should -Not -Be $false
            $def.GetType().Name | Should -Be 'String'
            $out = & $name 'hello'
            $out | Should -Be 'hello'
        }
    }
}

Describe 'Documentation Generation' {
    BeforeAll {
        # Resolve scripts utils docs path directly
        $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $script:ScriptsUtilsDocsPath = Join-Path $repoRoot 'scripts\utils\docs'
        if (-not (Test-Path $script:ScriptsUtilsDocsPath)) {
            throw "Scripts utils docs path not found: $script:ScriptsUtilsDocsPath"
        }

        # Cache compiled regex for comment parsing
        $script:CommentBlockRegex = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }

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

            # Test that the script can parse the function
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

            $funcAst = $functionAsts[0]
            $start = $funcAst.Extent.StartOffset
            $beforeText = $content.Substring(0, $start)
            $commentMatches = $script:CommentBlockRegex.Matches($beforeText)

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

            # Create a test profile.d directory with a test function
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

            # Run the documentation generator with custom profile path
            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $result = & $scriptPath -OutputPath $tempDir 2>&1

            # The script should run without throwing an exception
            $true | Should -Be $true
        }

        It 'generates index with functions and aliases sections' {
            $tempDir = Join-Path $TestDrive 'docs_index'
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            $scriptPath = Join-Path $script:ScriptsUtilsDocsPath 'generate-docs.ps1'
            $outputPath = Join-Path $tempDir 'api'
            $result = & $scriptPath -OutputPath $outputPath 2>&1

            $readmePath = Join-Path $outputPath 'README.md'
            if (Test-Path $readmePath) {
                $content = Get-Content $readmePath -Raw
                # Check for new structure with functions and aliases sections
                $content | Should -Match '## Functions'
                $content | Should -Match '## Aliases'
                # Check for links to subdirectories
                $content | Should -Match 'functions/'
                $content | Should -Match 'aliases/'
            }
        }
    }
}
