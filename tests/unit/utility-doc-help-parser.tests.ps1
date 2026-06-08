<#
tests/unit/utility-doc-help-parser.tests.ps1

.SYNOPSIS
    Unit tests for DocHelpParser.psm1 comment-help normalization and parsing.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:DocHelpParserPath = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'modules' 'DocHelpParser.psm1'
    Import-Module $script:DocHelpParserPath -DisableNameChecking -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module DocHelpParser -ErrorAction SilentlyContinue -Force
}

Describe 'DocHelpParser.psm1' {
    Context 'Normalize-CommentHelpBlock' {
        It 'Strips comment markers and preserves structured help sections' {
            $block = @'
<#
    .SYNOPSIS
        Example help block.
    .DESCRIPTION
        Detailed description text.
#>
'@

            $result = Normalize-CommentHelpBlock -CommentBlock $block

            $result | Should -Match '(?m)^\s*\.SYNOPSIS\s*$'
            $result | Should -Match 'Example help block'
            $result | Should -Not -Match '<#'
            $result | Should -Not -Match '#>'
        }

        It 'Does not corrupt regex-like comment delimiter sequences in output' {
            $block = '<# .SYNOPSIS Test #>'
            $result = Normalize-CommentHelpBlock -CommentBlock $block

            $result | Should -Be '.SYNOPSIS Test'
        }
    }

    Context 'ConvertFrom-CommentHelpContent' {
        It 'Extracts synopsis, description, parameters, and examples' {
            $help = @'
.SYNOPSIS
    Parses help content.
.DESCRIPTION
    Converts structured help into documentation fields.
.PARAMETER Name
    Item name.
.EXAMPLE
    Get-Example -Name test
'@

            $parsed = ConvertFrom-CommentHelpContent -HelpContent $help

            $parsed.Synopsis | Should -Be 'Parses help content.'
            $parsed.Description | Should -Match 'documentation fields'
            $parsed.Parameters.Count | Should -Be 1
            $parsed.Parameters[0].Name | Should -Be 'Name'
            $parsed.Examples.Count | Should -Be 1
            $parsed.Examples[0] | Should -Match 'Get-Example -Name test'
        }
    }

    Context 'Test-DecorativeCommentText' {
        It 'Treats separator and label comments as decorative' {
            Test-DecorativeCommentText -Text '---' | Should -Be $true
            Test-DecorativeCommentText -Text 'Section:' | Should -Be $true
            Test-DecorativeCommentText -Text 'Git clone helper' | Should -Be $false
        }
    }

    Context 'Get-RegistrationHelpContent' {
        It 'Resolves single-line caption comments above block help' {
            $content = @'
# Git clone - clone a repository
<#
.SYNOPSIS
    Shows commit history.
.DESCRIPTION
    Displays the commit log for the repository.
#>
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { $null } -Alias 'gcl'
'@
            $lines = [string[]]@($content -split "\r?\n")
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $cmd = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                    $args[0].GetCommandName() -ieq 'Register-LazyFunction'
                }, $true) | Select-Object -First 1

            $help = Get-RegistrationHelpContent `
                -FileContent $content `
                -SourceFileLines $lines `
                -RegistrationCommandAst $cmd `
                -FunctionName 'Invoke-GitClone'

            $help | Should -Match 'Shows commit history'
            $help | Should -Not -Match 'Git clone - clone a repository'
        }
    }
}
