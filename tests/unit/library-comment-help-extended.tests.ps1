<#
tests/unit/library-comment-help-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CommentHelp extraction edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'utilities' 'RegexUtilities.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $libPath 'code-analysis' 'CommentHelp.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module CommentHelp, RegexUtilities -ErrorAction SilentlyContinue -Force
}

Describe 'CommentHelp extended scenarios' {
    Context 'Get-HelpContentFromCommentBlock' {
        It 'Preserves .EXAMPLE sections after normalization' {
            $commentBlock = @'
<#
.SYNOPSIS
    Sample command.

.EXAMPLE
    Get-Sample -Name test
#>
'@

            $content = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock

            $content | Should -Match '\.EXAMPLE'
            $content | Should -Match 'Get-Sample -Name test'
        }

        It 'Normalizes single-line comment blocks' {
            $content = Get-HelpContentFromCommentBlock -CommentBlock '<# inline help #>'

            $content | Should -Be 'inline help'
        }
    }

    Context 'Test-CommentBlockHasHelp' {
        It 'Returns false when only .PARAMETER sections are present' {
            $commentBlock = @'
<#
.PARAMETER Name
    The resource name.
#>
'@

            Test-CommentBlockHasHelp -CommentBlock $commentBlock | Should -Be $false
        }
    }

    Context 'Test-FunctionHasHelp' {
        It 'Returns false when only single-line comments precede the function' {
            $content = @'
# Regular comment only
function Test-NoBlockHelp {
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]

            Test-FunctionHasHelp -FuncAst $funcAst -Content $content | Should -Be $false
        }

        It 'Detects help blocks inside function bodies when CheckBody is enabled' {
            $content = @'
function Test-BodyHelp {
<#
.SYNOPSIS
    Body help content.
#>
    return 1
}
'@
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $funcAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]

            Test-FunctionHasHelp -FuncAst $funcAst -Content $content -CheckBody | Should -Be $true
        }
    }
}
