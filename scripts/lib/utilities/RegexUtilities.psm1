<#
scripts/lib/RegexUtilities.psm1

.SYNOPSIS
    Regex utilities for creating compiled regex patterns.

.DESCRIPTION
    Provides functions for creating compiled regex patterns with consistent options.
    Compiled regex patterns offer better performance for repeated matching operations.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Creates a compiled regex pattern.

.DESCRIPTION
    Creates a compiled regex pattern with consistent options for better performance.
    Compiled regex patterns are cached by the .NET runtime and offer significant
    performance improvements for repeated matching operations.

.PARAMETER Pattern
    The regex pattern string.

.PARAMETER Options
    Additional regex options. Can be combined with bitwise OR (e.g., IgnoreCase -bor Multiline).
    Common options: IgnoreCase, Multiline, Singleline, Compiled.

.PARAMETER Compiled
    If specified, includes Compiled option for better performance. Defaults to true.

.OUTPUTS
    System.Text.RegularExpressions.Regex. A compiled regex object.

.EXAMPLE
    $regex = New-CompiledRegex -Pattern 'function\s+(\w+)'
    $matches = $regex.Matches($content)

.EXAMPLE
    $regex = New-CompiledRegex -Pattern '^#.*' -Options ([System.Text.RegularExpressions.RegexOptions]::Multiline)
    $commentLines = $regex.Matches($content)
#>
function New-CompiledRegex {
    [CmdletBinding()]
    [OutputType([System.Text.RegularExpressions.Regex])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern,

        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None,

        [bool]$Compiled = $true
    )

    $finalOptions = $Options
    if ($Compiled) {
        $finalOptions = $finalOptions -bor [System.Text.RegularExpressions.RegexOptions]::Compiled
    }

    return [regex]::new($Pattern, $finalOptions)
}

<#
.SYNOPSIS
    Gets common compiled regex patterns for PowerShell code analysis.

.DESCRIPTION
    Returns a hashtable of commonly used compiled regex patterns for analyzing
    PowerShell code, including function definitions, comment blocks, and common patterns.

.OUTPUTS
    Hashtable with pattern names as keys and compiled regex objects as values.

.EXAMPLE
    $patterns = Get-CommonRegexPatterns
    $functionMatches = $patterns['FunctionDefinition'].Matches($content)
    $commentMatches = $patterns['CommentBlock'].Matches($content)
#>
function Get-CommonRegexPatterns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        'FunctionDefinition'    = New-CompiledRegex -Pattern 'function\s+([A-Za-z0-9_-]+)\s*\{'
        'CommentBlock'          = New-CompiledRegex -Pattern '<#[\s\S]*?#>'
        'CommentBlockMultiline' = New-CompiledRegex -Pattern '^[\s]*<#[\s\S]*?#>' -Options ([System.Text.RegularExpressions.RegexOptions]::Multiline)
        'SingleLineComment'     = New-CompiledRegex -Pattern '^\s*#.*$' -Options ([System.Text.RegularExpressions.RegexOptions]::Multiline)
        'ExitCall'              = New-CompiledRegex -Pattern '\bexit\s+(\d+)\b'
        'ExitVariable'          = New-CompiledRegex -Pattern '\bexit\s+\$EXIT'
        'ImportModule'          = New-CompiledRegex -Pattern 'Import-Module' -Options ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
}

Export-ModuleMember -Function @(
    'New-CompiledRegex',
    'Get-CommonRegexPatterns'
)

