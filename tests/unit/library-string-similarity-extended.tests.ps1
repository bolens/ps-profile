<#
tests/unit/library-string-similarity-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-StringSimilarity scoring nuances.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'StringSimilarity.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module StringSimilarity -ErrorAction SilentlyContinue -Force
}

Describe 'StringSimilarity extended scenarios' {
    Context 'Get-StringSimilarity' {
        It 'Scores contained substrings higher than unrelated strings' {
            $contained = Get-StringSimilarity -String1 'hello' -String2 'hello world'
            $unrelated = Get-StringSimilarity -String1 'hello' -String2 'zzzzzz'

            $contained | Should -BeGreaterThan $unrelated
        }

        It 'Returns high but imperfect similarity for one-character substitutions' {
            $similarity = Get-StringSimilarity -String1 'cat' -String2 'car'

            $similarity | Should -BeGreaterThan 0.4
            $similarity | Should -BeLessThan 1.0
        }

        It 'Rounds results to four decimal places' {
            $similarity = Get-StringSimilarity -String1 'abcd' -String2 'abce'
            $text = $similarity.ToString([System.Globalization.CultureInfo]::InvariantCulture)

            ($text.Split('.')[1].Length) | Should -BeLessOrEqual 4
        }

        It 'Scores prefix matches higher than completely different strings' {
            $prefixMatch = Get-StringSimilarity -String1 'profile' -String2 'profile-loader'
            $different = Get-StringSimilarity -String1 'profile' -String2 'container'

            $prefixMatch | Should -BeGreaterThan $different
        }
    }
}
