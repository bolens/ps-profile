<#
tests/unit/library-regex-utilities-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for RegexUtilities pattern matching edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'RegexUtilities.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module RegexUtilities -ErrorAction SilentlyContinue -Force
}

Describe 'RegexUtilities extended scenarios' {
    Context 'Get-CommonRegexPatterns' {
        It 'Matches exit statements that use the EXIT variable' {
            $patterns = Get-CommonRegexPatterns
            $patterns['ExitVariable'].IsMatch('exit $EXIT_RUNTIME_ERROR') | Should -Be $true
        }

        It 'Matches hyphenated function names in definitions' {
            $patterns = Get-CommonRegexPatterns
            $content = 'function Set-AgentModeFunction {'
            $matches = $patterns['FunctionDefinition'].Matches($content)

            $matches.Count | Should -Be 1
            $matches[0].Groups[1].Value | Should -Be 'Set-AgentModeFunction'
        }

        It 'Returns independent hashtable instances on each call' {
            $first = Get-CommonRegexPatterns
            $second = Get-CommonRegexPatterns

            [object]::ReferenceEquals($first, $second) | Should -Be $false
            $first.Keys.Count | Should -Be $second.Keys.Count
        }
    }

    Context 'New-CompiledRegex' {
        It 'Honors Singleline option for dot-all matching' {
            $regex = New-CompiledRegex -Pattern 'start.*end' -Options ([System.Text.RegularExpressions.RegexOptions]::Singleline)

            $regex.IsMatch("start`nmiddle`nend") | Should -Be $true
        }

        It 'Matches multiline comment blocks at the start of content' {
            $patterns = Get-CommonRegexPatterns
            $content = @"
<# header comment #>
Write-Host 'code'
"@
            $patterns['CommentBlockMultiline'].IsMatch($content) | Should -Be $true
        }
    }
}
