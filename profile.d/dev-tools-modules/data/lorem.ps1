# ===============================================
# Lorem Ipsum text generation utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Lorem Ipsum generator utility functions.
.DESCRIPTION
    Sets up internal functions for generating Lorem Ipsum placeholder text.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Lorem {
    # Lorem Ipsum Generator
    Set-Item -Path Function:Global:_Get-LoremIpsum -Value {
        param(
            [int]$Words = 50,
            [int]$Paragraphs = 1,
            [switch]$StartWithLorem
        )
        $loremWords = @('lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing', 'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore', 'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam', 'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'ut', 'aliquip', 'ex', 'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure', 'dolor', 'in', 'reprehenderit', 'in', 'voluptate', 'velit', 'esse', 'cillum', 'dolore', 'eu', 'fugiat', 'nulla', 'pariatur', 'excepteur', 'sint', 'occaecat', 'cupidatat', 'non', 'proident', 'sunt', 'in', 'culpa', 'qui', 'officia', 'deserunt', 'mollit', 'anim', 'id', 'est', 'laborum')
        $result = @()
        for ($p = 0; $p -lt $Paragraphs; $p++) {
            $paragraph = @()
            $wordCount = 0
            if ($StartWithLorem -and $p -eq 0) {
                $paragraph += 'Lorem'
                $paragraph += 'ipsum'
                $wordCount = 2
            }
            while ($wordCount -lt $Words) {
                $paragraph += $loremWords | Get-Random
                $wordCount++
            }
            $result += ($paragraph -join ' ')
        }
        $result -join "`n`n"
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Generates Lorem Ipsum placeholder text.
.DESCRIPTION
    Generates Lorem Ipsum placeholder text with specified number of words or paragraphs.
.PARAMETER Words
    Number of words to generate. Default is 50.
.PARAMETER Paragraphs
    Number of paragraphs to generate. Default is 1.
.PARAMETER StartWithLorem
    If specified, starts the first paragraph with "Lorem ipsum".
.EXAMPLE
    Get-LoremIpsum -Words 100
    Generates 100 words of Lorem Ipsum text.
.EXAMPLE
    Get-LoremIpsum -Paragraphs 3 -StartWithLorem
    Generates 3 paragraphs starting with "Lorem ipsum".
.OUTPUTS
    System.String
    The generated Lorem Ipsum text.
#>
function Get-LoremIpsum {
    param(
        [int]$Words = 50,
        [int]$Paragraphs = 1,
        [switch]$StartWithLorem
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Get-LoremIpsum @PSBoundParameters
}
Set-Alias -Name lorem -Value Get-LoremIpsum -ErrorAction SilentlyContinue

