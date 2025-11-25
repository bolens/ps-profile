<#
scripts/utils/code-quality/modules/OutputSanitizer.psm1

.SYNOPSIS
    Output sanitization utilities.

.DESCRIPTION
    Provides functions for sanitizing test output by replacing repository roots with relative paths.
#>

# Import path utilities
$pathUtilsModulePath = Join-Path $PSScriptRoot 'OutputPathUtils.psm1'
if (Test-Path $pathUtilsModulePath) {
    Import-Module $pathUtilsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Sanitizes test runner output by replacing repository roots with relative paths.

.DESCRIPTION
    Rewrites occurrences of the repository root (with either separator style) and
    any quoted paths within a text line, returning an updated string without
    sensitive absolute information.

.PARAMETER Text
    The text to inspect and rewrite.

.OUTPUTS
    System.String
#>
function Convert-TestOutputLine {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    $converted = [string]$Text

    # Get RepoRootPattern from OutputPathUtils module
    $repoRootPattern = Get-RepoRootPattern

    if ($repoRootPattern) {
        $converted = [System.Text.RegularExpressions.Regex]::Replace(
            $converted,
            "${repoRootPattern}(?:[\\/]+)",
            '',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        $converted = [System.Text.RegularExpressions.Regex]::Replace(
            $converted,
            $repoRootPattern,
            '.',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }

    $converted = [System.Text.RegularExpressions.Regex]::Replace(
        $converted,
        "'([^']+)'",
        {
            param($match)
            $candidate = $match.Groups[1].Value
            $relative = ConvertTo-RepoRelativePath -PathString $candidate
            if ($relative -ne $candidate) {
                return "'$relative'"
            }
            return $match.Value
        },
        [System.Text.RegularExpressions.RegexOptions]::None
    )

    return $converted
}

Export-ModuleMember -Function Convert-TestOutputLine

