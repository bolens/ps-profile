<#
tests/unit/library-regex-natural-language.tests.ps1

.SYNOPSIS
    Unit tests for natural language to regex conversion.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'RegexUtilities.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module RegexUtilities -ErrorAction SilentlyContinue -Force
}

Describe 'Natural language regex conversion' {
    Context 'Get-NaturalLanguageRegexCatalog' {
        It 'Returns catalog entries with patterns and aliases' {
            $catalog = Get-NaturalLanguageRegexCatalog

            $catalog | Should -Not -BeNullOrEmpty
            $catalog.Contains('email') | Should -Be $true
            $catalog['email'].Pattern | Should -Not -BeNullOrEmpty
            $catalog['email'].Aliases | Should -Contain 'email address'
        }
    }

    Context 'ConvertTo-RegexFromNaturalLanguage catalog matches' {
        It 'Converts email descriptions' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'email address'

            $result.IsValid | Should -Be $true
            $result.Source | Should -Be 'catalog'
            $result.Pattern | Should -Match '@'
        }

        It 'Converts IPv4 descriptions' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'ipv4'

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Match '25\[0-5\]'
        }

        It 'Converts UUID descriptions' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'uuid'

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Match '0-9A-Fa-f'
        }
    }

    Context 'ConvertTo-RegexFromNaturalLanguage composed phrases' {
        It 'Builds starts-with patterns' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description "starts with 'user-'"

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Be '^user-'
        }

        It 'Builds ends-with patterns' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'ends with .com'

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Be '\.com$'
        }

        It 'Builds contains patterns' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'contains error'

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Be '.*error.*'
        }

        It 'Composes multiple segments' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description "starts with 'ID-' followed by digits"

            $result.IsValid | Should -Be $true
            $result.Source | Should -Be 'composed'
            $result.Pattern | Should -Be '^ID-\d+'
        }

        It 'Supports quantifier phrases' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'exactly 4 digits'

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Be '\d{4}'
        }

        It 'Applies anchoring when requested' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'digits' -Anchored

            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Be '^\d+$'
        }

        It 'Detects case-insensitive intent in description' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'letters case insensitive'

            $result.IgnoreCase | Should -Be $true
            $result.Pattern | Should -Be '[A-Za-z]+'
        }
    }

    Context 'Generated pattern validation' {
        It 'Matches real input for composed patterns' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description "starts with 'user-' followed by digits" -Anchored
            $regex = [regex]::new($result.Pattern)

            $regex.IsMatch('user-42') | Should -Be $true
            $regex.IsMatch('admin-42') | Should -Be $false
        }
    }

    Context 'Extended catalog entries' {
        It 'Converts IBAN descriptions' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'iban'
            $result.IsValid | Should -Be $true
            $result.CatalogName | Should -Be 'iban'
        }

        It 'Converts international phone descriptions' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'e164'
            $result.IsValid | Should -Be $true
            $result.Pattern | Should -Match '\\\+'
        }

        It 'Converts ISO datetime descriptions' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'iso timestamp'
            $result.CatalogName | Should -Be 'iso-datetime'
        }
    }

    Context 'Alternation phrases' {
        It 'Builds one-of patterns from catalog entries' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'either email or ipv4'
            $result.IsValid | Should -Be $true
            $result.Source | Should -Be 'alternation'
            $result.Pattern | Should -Match '@'
            $result.Pattern | Should -Match '25\[0-5\]'
        }
    }

    Context 'Search-NaturalLanguageRegexCatalog' {
        It 'Finds entries by alias fragment' {
            $results = Search-NaturalLanguageRegexCatalog -Query 'phone'
            $results.Name | Should -Contain 'phone-number'
            $results.Name | Should -Contain 'e164-phone'
        }
    }

    Context 'Resolve-RegexPatternFromAiResponse' {
        It 'Extracts regex from fenced code blocks' {
            $resolved = Resolve-RegexPatternFromAiResponse -Response @'
```regex
\d+
```
'@
            $resolved.IsValid | Should -Be $true
            $resolved.Pattern | Should -Be '\d+'
        }

        It 'Strips slash delimiters from AI output' {
            $resolved = Resolve-RegexPatternFromAiResponse -Response '/^foo$/'
            $resolved.IsValid | Should -Be $true
            $resolved.Pattern | Should -Be '^foo$'
        }
    }

    Context 'Sample validation' {
        It 'Validates provided sample matches and non-matches' {
            $result = ConvertTo-RegexFromNaturalLanguage `
                -Description 'email' `
                -SampleMatch 'user@example.com' `
                -SampleNoMatch 'not-an-email'

            $result.SampleResults | Should -Not -BeNullOrEmpty
            ($result.SampleResults | Where-Object { $_.Expected -eq 'match' }).Success | Should -Be $true
            ($result.SampleResults | Where-Object { $_.Expected -eq 'no-match' }).Success | Should -Be $true
        }
    }

    Context 'Get-NaturalLanguageRegexCatalogItems' {
        It 'Returns pipeline-friendly catalog objects' {
            $items = Get-NaturalLanguageRegexCatalogItems
            $items | Should -Not -BeNullOrEmpty
            $items[0].Name | Should -Not -BeNullOrEmpty
            $items[0].Aliases | Should -Not -BeNullOrEmpty
        }
    }

    Context 'ConvertFrom-RegexToNaturalLanguage' {
        It 'Explains catalog patterns by reverse lookup' {
            $emailPattern = (Get-NaturalLanguageRegexCatalog)['email'].Pattern
            $result = ConvertFrom-RegexToNaturalLanguage -Pattern $emailPattern

            $result.CatalogName | Should -Be 'email'
            $result.Confidence | Should -Be 'high'
            $result.Description | Should -Match 'e-mail'
        }

        It 'Decomposes composed patterns' {
            $result = ConvertFrom-RegexToNaturalLanguage -Pattern '^user-\d+$' -Detailed

            $result.Source | Should -Be 'decomposed'
            $result.Description | Should -Match 'user-'
            $result.Description | Should -Match 'digit'
            $result.Components.Count | Should -BeGreaterThan 1
        }

        It 'Explains alternation patterns' {
            $pattern = (ConvertTo-RegexFromNaturalLanguage -Description 'either email or ipv4').Pattern
            $result = ConvertFrom-RegexToNaturalLanguage -Pattern $pattern

            $result.Source | Should -Be 'alternation'
            $result.Description | Should -Match 'either'
        }
    }

    Context 'Format-NaturalLanguageRegexResult' {
        It 'Formats conversion results as plain text' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'email'
            $text = Format-NaturalLanguageRegexResult -Result $result -As Text

            $text | Should -Match 'Pattern:'
            $text | Should -Match 'email'
        }

        It 'Formats conversion results as JSON' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'digits'
            $json = Format-NaturalLanguageRegexResult -Result $result -As Json

            $json | Should -Match '"Pattern"'
            $json | Should -Match '\\d'
        }
    }

    Context 'Build-NaturalLanguageRegexDescription' {
        It 'Joins composed segments' {
            $description = Build-NaturalLanguageRegexDescription -Segments @("starts with 'svc-'", 'digits')
            $description | Should -Be "starts with 'svc-' followed by digits"
        }

        It 'Builds alternation descriptions' {
            $description = Build-NaturalLanguageRegexDescription -Segments @('email', 'ipv4') -Alternation
            $description | Should -Be 'either email or ipv4'
        }
    }

    Context 'Measure-NaturalLanguageRegexSimilarity' {
        It 'Returns identical descriptions as 1.0' {
            Measure-NaturalLanguageRegexSimilarity -Left 'email address' -Right 'email address' |
                Should -Be 1.0
        }

        It 'Returns partial overlap between related phrases' {
            $score = Measure-NaturalLanguageRegexSimilarity -Left 'email address' -Right 'e-mail'
            $score | Should -BeGreaterThan 0
            $score | Should -BeLessThan 1
        }
    }

    Context 'Test-NaturalLanguageRegexRoundTrip' {
        It 'Validates consistent catalog round-trips' {
            $result = Test-NaturalLanguageRegexRoundTrip -Description 'email'
            $result.IsConsistent | Should -Be $true
            $result.Similarity | Should -BeGreaterThan 0
            $result.Pattern | Should -Match '@'
        }

        It 'Reports composed pattern round-trip details' {
            $result = Test-NaturalLanguageRegexRoundTrip -Description "starts with 'user-' followed by digits" -Anchored
            $result.ExplainedDescription | Should -Not -BeNullOrEmpty
            $result.Pattern | Should -Be '^user-\d+$'
        }
    }

    Context 'Export-NaturalLanguageRegexCatalogDocument' {
        It 'Exports JSON catalog documents' {
            $json = Export-NaturalLanguageRegexCatalogDocument -Format Json
            $json | Should -Match '"name":\s*"email"'
            $json | Should -Match '"pattern":'
        }

        It 'Exports Markdown catalog documents' {
            $markdown = Export-NaturalLanguageRegexCatalogDocument -Format Markdown
            $markdown | Should -Match '^# Natural Language Regex Catalog'
            $markdown | Should -Match '## email'
            $markdown | Should -Match '\*\*Pattern:\*\*'
        }

        It 'Writes export content to a file' {
            $exportPath = Join-Path $TestDrive 'regex-catalog.json'
            Export-NaturalLanguageRegexCatalogDocument -Format Json -Path $exportPath | Out-Null
            Test-Path -LiteralPath $exportPath | Should -Be $true
        }
    }

    Context 'Regex session persistence' {
        It 'Creates and exports sessions' {
            $session = New-NaturalLanguageRegexSession `
                -Description 'email' `
                -Pattern (Get-NaturalLanguageRegexCatalog)['email'].Pattern `
                -SampleMatch 'user@example.com'

            $session.Description | Should -Be 'email'
            $session.Version | Should -Be '1.0'
        }

        It 'Exports and imports session files' {
            $sessionPath = Join-Path $TestDrive 'email-session.json'
            $session = New-NaturalLanguageRegexSession -Description 'uuid' -Pattern 'test-pattern'
            Export-NaturalLanguageRegexSession -Session $session -Path $sessionPath | Out-Null

            $imported = Import-NaturalLanguageRegexSession -Path $sessionPath
            $imported.Description | Should -Be 'uuid'
            $imported.Pattern | Should -Be 'test-pattern'
        }
    }

    Context 'Compare-NaturalLanguageRegexDescriptions' {
        It 'Reports token differences and similarity' {
            $result = Compare-NaturalLanguageRegexDescriptions -Left 'email address' -Right 'email'
            $result.Similarity | Should -BeGreaterThan 0
            $result.LeftOnlyTokens | Should -Contain 'address'
            $result.DiffText | Should -Match 'Left:'
        }

        It 'Compares generated patterns when requested' {
            $result = Compare-NaturalLanguageRegexDescriptions -Left 'email' -Right 'email address' -IncludePatterns
            $result.LeftPattern | Should -Match '@'
            $result.RightPattern | Should -Match '@'
        }
    }

    Context 'New-NaturalLanguageRegexPesterStub' {
        It 'Generates a Pester test stub with samples' {
            $stub = New-NaturalLanguageRegexPesterStub `
                -Description 'email' `
                -SampleMatch 'user@example.com' `
                -SampleNoMatch 'invalid'

            $stub | Should -Match "Describe 'NL regex:"
            $stub | Should -Match 'Matches expected samples'
            $stub | Should -Match 'Rejects invalid samples'
        }

        It 'Writes generated Pester stubs to disk' {
            $testPath = Join-Path $TestDrive 'email.tests.ps1'
            New-NaturalLanguageRegexPesterStub -Description 'digits' -Path $testPath | Out-Null
            Test-Path -LiteralPath $testPath | Should -Be $true
        }
    }

    Context 'AI fallback detection' {
        It 'Flags unrecognized descriptions for AI fallback' {
            $result = ConvertTo-RegexFromNaturalLanguage -Description 'match widgets with nested braces'
            $result.NeedsAiFallback | Should -Be $true
        }

        It 'Applies supplied AI patterns' {
            $result = ConvertTo-RegexFromNaturalLanguage `
                -Description 'match widgets with nested braces' `
                -AiPattern 'widget\{.*\}'

            $result.Source | Should -Be 'ai'
            $result.NeedsAiFallback | Should -Be $false
            $result.Pattern | Should -Be 'widget\{.*\}'
        }
    }
}
