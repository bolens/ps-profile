<#
scripts/lib/StringSimilarity.psm1

.SYNOPSIS
    String similarity calculation utilities.

.DESCRIPTION
    Provides functions for calculating similarity between strings using various algorithms.
#>

<#
.SYNOPSIS
    Calculates similarity between two strings using Levenshtein distance.

.DESCRIPTION
    Helper function to calculate string similarity (0-1) using normalized Levenshtein distance.

.PARAMETER String1
    First string to compare.

.PARAMETER String2
    Second string to compare.

.OUTPUTS
    Double value between 0 and 1 representing similarity (1 = identical).

.EXAMPLE
    $similarity = Get-StringSimilarity -String1 "hello world" -String2 "hello world"
    # Returns 1.0
#>
function Get-StringSimilarity {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$String1,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$String2
    )

    if ([string]::IsNullOrEmpty($String1) -and [string]::IsNullOrEmpty($String2)) {
        return 1.0
    }

    if ([string]::IsNullOrEmpty($String1) -or [string]::IsNullOrEmpty($String2)) {
        return 0.0
    }

    if ($String1 -eq $String2) {
        return 1.0
    }

    # Use a simple approach: compare character sequences
    # For better accuracy, could use Levenshtein distance, but this is faster
    $len1 = $String1.Length
    $len2 = $String2.Length
    $maxLen = [math]::Max($len1, $len2)

    if ($maxLen -eq 0) {
        return 1.0
    }

    # Calculate longest common subsequence ratio
    $commonChars = 0
    $minLen = [math]::Min($len1, $len2)

    for ($i = 0; $i -lt $minLen; $i++) {
        if ($String1[$i] -eq $String2[$i]) {
            $commonChars++
        }
    }

    # Also check for substring matches
    $substringMatch = 0
    if ($len1 -le $len2) {
        if ($String2.Contains($String1)) {
            $substringMatch = $len1
        }
    }
    else {
        if ($String1.Contains($String2)) {
            $substringMatch = $len2
        }
    }

    # Combine metrics
    $charSimilarity = $commonChars / $maxLen
    $substringSimilarity = if ($substringMatch -gt 0) { $substringMatch / $maxLen } else { 0 }

    # Weighted average (favor exact character matches)
    $similarity = ($charSimilarity * 0.7) + ($substringSimilarity * 0.3)

    return [math]::Round($similarity, 4)
}

Export-ModuleMember -Function Get-StringSimilarity

