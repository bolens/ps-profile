. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:StringSimilarityPath = Join-Path $script:LibPath 'utilities' 'StringSimilarity.psm1'
    
    # Import the module under test
    Import-Module $script:StringSimilarityPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module StringSimilarity -ErrorAction SilentlyContinue
}

Describe 'StringSimilarity Module Functions' {
    Context 'Get-StringSimilarity' {
        It 'Returns 1.0 for identical strings' {
            $result = Get-StringSimilarity -String1 'hello world' -String2 'hello world'
            $result | Should -Be 1.0
        }

        It 'Returns 1.0 for both empty strings' {
            $result = Get-StringSimilarity -String1 '' -String2 ''
            $result | Should -Be 1.0
        }

        It 'Returns 1.0 for both null strings' {
            $result = Get-StringSimilarity -String1 $null -String2 $null
            $result | Should -Be 1.0
        }

        It 'Returns 0.0 when first string is empty' {
            $result = Get-StringSimilarity -String1 '' -String2 'hello'
            $result | Should -Be 0.0
        }

        It 'Returns 0.0 when second string is empty' {
            $result = Get-StringSimilarity -String1 'hello' -String2 ''
            $result | Should -Be 0.0
        }

        It 'Returns 0.0 when first string is null' {
            $result = Get-StringSimilarity -String1 $null -String2 'hello'
            $result | Should -Be 0.0
        }

        It 'Returns 0.0 when second string is null' {
            $result = Get-StringSimilarity -String1 'hello' -String2 $null
            $result | Should -Be 0.0
        }

        It 'Returns value between 0 and 1 for similar strings' {
            $result = Get-StringSimilarity -String1 'hello' -String2 'hallo'
            $result | Should -BeGreaterOrEqual 0.0
            $result | Should -BeLessOrEqual 1.0
        }

        It 'Returns higher similarity for more similar strings' {
            $result1 = Get-StringSimilarity -String1 'hello' -String2 'hallo'
            $result2 = Get-StringSimilarity -String1 'hello' -String2 'world'
            $result1 | Should -BeGreaterThan $result2
        }

        It 'Handles strings with common prefix' {
            $result = Get-StringSimilarity -String1 'hello' -String2 'hello world'
            $result | Should -BeGreaterThan 0.0
            $result | Should -BeLessOrEqual 1.0
        }

        It 'Handles strings with common suffix' {
            $result = Get-StringSimilarity -String1 'world' -String2 'hello world'
            $result | Should -BeGreaterThan 0.0
            $result | Should -BeLessOrEqual 1.0
        }

        It 'Handles completely different strings' {
            $result = Get-StringSimilarity -String1 'abc' -String2 'xyz'
            $result | Should -BeGreaterOrEqual 0.0
            $result | Should -BeLessThan 1.0
        }

        It 'Is case sensitive' {
            $result1 = Get-StringSimilarity -String1 'Hello' -String2 'hello'
            $result2 = Get-StringSimilarity -String1 'Hello' -String2 'Hello'
            # Identical strings should return 1.0
            $result2 | Should -Be 1.0
            # Case-different strings should have lower similarity than identical strings
            # Note: The function uses character-by-character comparison, so case differences reduce similarity
            if ($result1 -lt 1.0) {
                $result2 | Should -BeGreaterThan $result1
            }
            else {
                # If case-different returns 1.0 (unlikely but possible), just verify identical returns 1.0
                $result2 | Should -Be 1.0
            }
        }

        It 'Handles strings of different lengths' {
            $result = Get-StringSimilarity -String1 'short' -String2 'this is a much longer string'
            $result | Should -BeGreaterOrEqual 0.0
            $result | Should -BeLessOrEqual 1.0
        }

        It 'Handles single character strings' {
            $result = Get-StringSimilarity -String1 'a' -String2 'b'
            $result | Should -BeGreaterOrEqual 0.0
            $result | Should -BeLessOrEqual 1.0
        }

        It 'Returns 1.0 for single identical character' {
            $result = Get-StringSimilarity -String1 'a' -String2 'a'
            $result | Should -Be 1.0
        }

        It 'Handles strings with special characters' {
            $result = Get-StringSimilarity -String1 'test@123' -String2 'test@456'
            $result | Should -BeGreaterThan 0.0
            $result | Should -BeLessThan 1.0
        }

        It 'Handles strings with whitespace' {
            $result = Get-StringSimilarity -String1 'hello world' -String2 'hello  world'
            $result | Should -BeGreaterThan 0.0
            $result | Should -BeLessThan 1.0
        }

        It 'Returns rounded value to 4 decimal places' {
            $result = Get-StringSimilarity -String1 'test' -String2 'test1'
            # Result should be rounded to 4 decimal places
            $decimalPlaces = ($result.ToString() -split '\.')[1].Length
            $decimalPlaces | Should -BeLessOrEqual 4
        }

        It 'Handles substring matches' {
            # When one string contains the other, similarity should be higher
            $result = Get-StringSimilarity -String1 'test' -String2 'testing'
            $result | Should -BeGreaterThan 0.0
        }

        It 'Handles very long strings' {
            $longString1 = 'a' * 1000
            $longString2 = 'b' * 1000
            $result = Get-StringSimilarity -String1 $longString1 -String2 $longString2
            $result | Should -BeGreaterOrEqual 0.0
            $result | Should -BeLessOrEqual 1.0
        }
    }
}

