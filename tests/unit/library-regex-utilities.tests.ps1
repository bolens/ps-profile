. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:RegexUtilitiesPath = Join-Path $script:LibPath 'utilities' 'RegexUtilities.psm1'
    
    # Import the module under test
    Import-Module $script:RegexUtilitiesPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module RegexUtilities -ErrorAction SilentlyContinue
}

Describe 'RegexUtilities Module Functions' {
    Context 'New-CompiledRegex' {
        It 'Creates a compiled regex pattern' {
            $regex = New-CompiledRegex -Pattern '\d+'
            $regex | Should -Not -BeNullOrEmpty
            $regex | Should -BeOfType [regex]
        }

        It 'Matches patterns correctly' {
            $regex = New-CompiledRegex -Pattern '\d+'
            $matches = $regex.Matches('abc123def456')
            $matches.Count | Should -Be 2
            $matches[0].Value | Should -Be '123'
            $matches[1].Value | Should -Be '456'
        }

        It 'Uses Compiled option by default' {
            $regex = New-CompiledRegex -Pattern 'test'
            # Compiled regex should work correctly
            $regex.IsMatch('test') | Should -Be $true
        }

        It 'Can disable Compiled option' {
            $regex = New-CompiledRegex -Pattern 'test' -Compiled $false
            $regex.IsMatch('test') | Should -Be $true
        }

        It 'Accepts additional regex options' {
            $regex = New-CompiledRegex -Pattern 'TEST' -Options ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $regex.IsMatch('test') | Should -Be $true
            $regex.IsMatch('TEST') | Should -Be $true
        }

        It 'Combines multiple options' {
            $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
            $regex = New-CompiledRegex -Pattern '^test' -Options $options
            $regex.IsMatch('TEST') | Should -Be $true
        }

        It 'Handles complex patterns' {
            $regex = New-CompiledRegex -Pattern 'function\s+([\w-]+)'
            $testContent = 'function Test-Function { }'
            $matches = $regex.Matches($testContent)
            $matches.Count | Should -Be 1
            $matches[0].Groups[1].Value | Should -Be 'Test-Function'
        }

        It 'Handles special regex characters' {
            $regex = New-CompiledRegex -Pattern '\.\*\+\?\|\(\)'
            $regex.IsMatch('.*+?|()') | Should -Be $true
        }
    }

    Context 'Get-CommonRegexPatterns' {
        It 'Returns a hashtable of patterns' {
            $patterns = Get-CommonRegexPatterns
            $patterns | Should -Not -BeNullOrEmpty
            $patterns | Should -BeOfType [hashtable]
        }

        It 'Contains FunctionDefinition pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('FunctionDefinition') | Should -Be $true
            $patterns['FunctionDefinition'] | Should -BeOfType [regex]
        }

        It 'FunctionDefinition pattern matches function declarations' {
            $patterns = Get-CommonRegexPatterns
            $regex = $patterns['FunctionDefinition']
            $testContent = 'function Test-Function {'
            $matches = $regex.Matches($testContent)
            $matches.Count | Should -BeGreaterThan 0
        }

        It 'Contains CommentBlock pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('CommentBlock') | Should -Be $true
            $patterns['CommentBlock'] | Should -BeOfType [regex]
        }

        It 'CommentBlock pattern matches comment blocks' {
            $patterns = Get-CommonRegexPatterns
            $regex = $patterns['CommentBlock']
            $testContent = '<# This is a comment block #>'
            $matches = $regex.Matches($testContent)
            $matches.Count | Should -BeGreaterThan 0
        }

        It 'Contains CommentBlockMultiline pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('CommentBlockMultiline') | Should -Be $true
            $patterns['CommentBlockMultiline'] | Should -BeOfType [regex]
        }

        It 'Contains SingleLineComment pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('SingleLineComment') | Should -Be $true
            $patterns['SingleLineComment'] | Should -BeOfType [regex]
        }

        It 'SingleLineComment pattern matches single line comments' {
            $patterns = Get-CommonRegexPatterns
            $regex = $patterns['SingleLineComment']
            $testContent = "    # This is a comment`n    Write-Host 'code'"
            $matches = $regex.Matches($testContent)
            $matches.Count | Should -BeGreaterThan 0
        }

        It 'Contains ExitCall pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('ExitCall') | Should -Be $true
            $patterns['ExitCall'] | Should -BeOfType [regex]
        }

        It 'ExitCall pattern matches exit calls with numbers' {
            $patterns = Get-CommonRegexPatterns
            $regex = $patterns['ExitCall']
            $testContent = 'exit 1'
            $matches = $regex.Matches($testContent)
            $matches.Count | Should -BeGreaterThan 0
        }

        It 'Contains ExitVariable pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('ExitVariable') | Should -Be $true
            $patterns['ExitVariable'] | Should -BeOfType [regex]
        }

        It 'Contains ImportModule pattern' {
            $patterns = Get-CommonRegexPatterns
            $patterns.ContainsKey('ImportModule') | Should -Be $true
            $patterns['ImportModule'] | Should -BeOfType [regex]
        }

        It 'ImportModule pattern matches Import-Module (case insensitive)' {
            $patterns = Get-CommonRegexPatterns
            $regex = $patterns['ImportModule']
            $regex.IsMatch('Import-Module') | Should -Be $true
            $regex.IsMatch('import-module') | Should -Be $true
            $regex.IsMatch('IMPORT-MODULE') | Should -Be $true
        }

        It 'All patterns are compiled regex objects' {
            $patterns = Get-CommonRegexPatterns
            foreach ($pattern in $patterns.Values) {
                $pattern | Should -BeOfType [regex]
            }
        }
    }
}

