. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import dependencies first
    $regexPath = Join-Path $script:LibPath 'utilities' 'RegexUtilities.psm1'
    if (Test-Path $regexPath) {
        Import-Module $regexPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    $astParsingPath = Join-Path $script:LibPath 'AstParsing.psm1'
    if (Test-Path $astParsingPath) {
        Import-Module $astParsingPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    $script:CommentHelpPath = Join-Path $script:LibPath 'code-analysis' 'CommentHelp.psm1'
    Import-Module $script:CommentHelpPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module CommentHelp -ErrorAction SilentlyContinue -Force
    Remove-Module RegexUtilities -ErrorAction SilentlyContinue -Force
    Remove-Module AstParsing -ErrorAction SilentlyContinue -Force
}

Describe 'CommentHelp Module Functions' {
    Context 'Get-CommentBlockBeforeFunction' {
        It 'Finds comment block before function' {
            $beforeText = @'
<#
.SYNOPSIS
    Test function.
#>
function Test-Function {
}
'@
            $result = Get-CommentBlockBeforeFunction -BeforeText $beforeText
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Match '\.SYNOPSIS'
        }

        It 'Returns null when no comment block exists' {
            $beforeText = 'function Test-Function { }'
            $result = Get-CommentBlockBeforeFunction -BeforeText $beforeText
            $result | Should -BeNullOrEmpty
        }

        It 'Returns last comment block when multiple exist' {
            $beforeText = @'
<#
First comment
#>
<#
.SYNOPSIS
    Second comment (should be returned)
#>
function Test-Function {
}
'@
            $result = Get-CommentBlockBeforeFunction -BeforeText $beforeText
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Match '\.SYNOPSIS'
        }

        It 'Returns all comment blocks when AllBlocks specified' {
            $beforeText = @'
<#
First comment
#>
<#
Second comment
#>
function Test-Function {
}
'@
            $result = Get-CommentBlockBeforeFunction -BeforeText $beforeText -AllBlocks
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Handles empty before text' {
            $result = Get-CommentBlockBeforeFunction -BeforeText ''
            $result | Should -BeNullOrEmpty
        }

        It 'Handles multiline comment blocks' {
            $beforeText = @'
<#
.SYNOPSIS
    Test function.

.DESCRIPTION
    This is a longer description
    that spans multiple lines.
#>
function Test-Function {
}
'@
            $result = Get-CommentBlockBeforeFunction -BeforeText $beforeText
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Match '\.SYNOPSIS'
            $result.Value | Should -Match '\.DESCRIPTION'
        }

        It 'Works without RegexUtilities module' {
            # Temporarily remove RegexUtilities
            Remove-Module RegexUtilities -ErrorAction SilentlyContinue -Force
            
            $beforeText = @'
<#
.SYNOPSIS
    Test function.
#>
function Test-Function {
}
'@
            $result = Get-CommentBlockBeforeFunction -BeforeText $beforeText
            $result | Should -Not -BeNullOrEmpty
            
            # Re-import RegexUtilities
            $regexPath = Join-Path $script:LibPath 'utilities' 'RegexUtilities.psm1'
            if (Test-Path $regexPath) {
                Import-Module $regexPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
        }
    }

    Context 'Test-CommentBlockHasHelp' {
        It 'Returns true for comment block with .SYNOPSIS' {
            $commentBlock = @'
<#
.SYNOPSIS
    Test function.
#>
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $true
        }

        It 'Returns true for comment block with .DESCRIPTION' {
            $commentBlock = @'
<#
.DESCRIPTION
    Test function description.
#>
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $true
        }

        It 'Returns true for comment block with both .SYNOPSIS and .DESCRIPTION' {
            $commentBlock = @'
<#
.SYNOPSIS
    Test function.

.DESCRIPTION
    Detailed description.
#>
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $true
        }

        It 'Returns false for comment block without help sections' {
            $commentBlock = @'
<#
This is just a regular comment
without any help sections.
#>
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $false
        }

        It 'Returns false for empty comment block' {
            $commentBlock = '<##>'
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $false
        }

        It 'Handles comment block without markers' {
            $commentBlock = @'
.SYNOPSIS
    Test function.

.DESCRIPTION
    Description.
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $true
        }

        It 'Is case sensitive for help sections' {
            $commentBlock = @'
<#
.synopsis
    Lowercase synopsis (should not match)
#>
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $false
        }

        It 'Handles whitespace in help sections' {
            $commentBlock = @'
<#
  .SYNOPSIS
    Test function with indentation.
#>
'@
            $result = Test-CommentBlockHasHelp -CommentBlock $commentBlock
            $result | Should -Be $true
        }
    }

    Context 'Get-HelpContentFromCommentBlock' {
        It 'Extracts help content from comment block' {
            $commentBlock = @'
<#
.SYNOPSIS
    Test function.
#>
'@
            $result = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '\.SYNOPSIS'
            $result | Should -Not -Match '^<#'
            $result | Should -Not -Match '#>$'
        }

        It 'Removes comment markers' {
            $commentBlock = '<# Test #>'
            $result = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock
            $result | Should -Not -Match '^<#'
            $result | Should -Not -Match '#>$'
        }

        It 'Normalizes whitespace' {
            $commentBlock = @'
<#
    .SYNOPSIS
        Test function.
#>
'@
            $result = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Removes carriage returns' {
            $commentBlock = "<#`r`n.SYNOPSIS`r`n    Test`r`n#>"
            $result = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock
            $result | Should -Not -Match '\r'
        }

        It 'Handles multiline help content' {
            $commentBlock = @'
<#
.SYNOPSIS
    Test function.

.DESCRIPTION
    This is a longer description
    that spans multiple lines.
#>
'@
            $result = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock
            $result | Should -Match '\.SYNOPSIS'
            $result | Should -Match '\.DESCRIPTION'
        }

        It 'Normalizes indentation' {
            $commentBlock = @'
<#
    .SYNOPSIS
        Test function with indentation.
    .DESCRIPTION
        Description with indentation.
#>
'@
            $result = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-FunctionHasHelp' {
        It 'Returns true for function with help before definition' {
            $content = @'
<#
.SYNOPSIS
    Test function.
#>
function Test-Function {
    Write-Host 'test'
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
            
            $result = Test-FunctionHasHelp -FuncAst $funcAst -Content $content
            $result | Should -Be $true
        }

        It 'Returns false for function without help' {
            $content = @'
function Test-Function {
    Write-Host 'test'
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
            
            $result = Test-FunctionHasHelp -FuncAst $funcAst -Content $content
            $result | Should -Be $false
        }

        It 'Checks function body when CheckBody specified' {
            $content = @'
function Test-Function {
<#
.SYNOPSIS
    Test function.
#>
    Write-Host 'test'
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
            
            $result = Test-FunctionHasHelp -FuncAst $funcAst -Content $content -CheckBody
            $result | Should -Be $true
        }

        It 'Returns false when CheckBody specified but no help in body' {
            $content = @'
function Test-Function {
    # Regular comment
    Write-Host 'test'
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
            
            $result = Test-FunctionHasHelp -FuncAst $funcAst -Content $content -CheckBody
            $result | Should -Be $false
        }
    }
}

