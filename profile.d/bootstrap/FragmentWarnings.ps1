# ===============================================
# FragmentWarnings.ps1
# Fragment warning suppression utilities
# ===============================================

# Initializes fragment warning suppression from PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS environment variable.
# Supports comma/semicolon/space-separated fragment names or 'all'/'*'/'1'/'true' to suppress all warnings.
function Initialize-FragmentWarningSuppression {
    if (-not (Get-Variable -Name 'FragmentWarningPatternSet' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:FragmentWarningPatternSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    else {
        $global:FragmentWarningPatternSet.Clear()
    }

    $global:SuppressAllFragmentWarnings = $false

    $rawValue = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS
    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return
    }

    # Parse comma/semicolon/space-separated values
    $tokens = $rawValue -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($token in $tokens) {
        $normalized = $token.Trim()
        if ([string]::IsNullOrWhiteSpace($normalized)) {
            continue
        }

        switch -Regex ($normalized.ToLowerInvariant()) {
            '^(1|true|all|\*)$' {
                # Special value: suppress all fragment warnings
                $global:SuppressAllFragmentWarnings = $true
                continue
            }
            default {
                # Add fragment name pattern to suppression list
                [void]$global:FragmentWarningPatternSet.Add($normalized)
            }
        }
    }
}

<#
.SYNOPSIS
    Tests whether a fragment warning should be suppressed.
.DESCRIPTION
    Checks if warnings for the specified fragment should be suppressed based on
    environment variable configuration and pattern matching.
.PARAMETER FragmentName
    The name of the fragment to check.
.OUTPUTS
    System.Boolean
    Returns $true if warnings should be suppressed, $false otherwise.
#>
function global:Test-FragmentWarningSuppressed {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$FragmentName
    )

    if ($global:SuppressAllFragmentWarnings) {
        return $true
    }

    if (-not $global:FragmentWarningPatternSet -or $global:FragmentWarningPatternSet.Count -eq 0) {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return $false
    }

    # Extract multiple name variants for flexible matching (full path, filename, basename)
    $candidateFull = $FragmentName.Trim()
    $candidateName = [System.IO.Path]::GetFileName($candidateFull)
    $candidateBase = [System.IO.Path]::GetFileNameWithoutExtension($candidateFull)

    foreach ($pattern in $global:FragmentWarningPatternSet) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        # Extract pattern variants to match against fragment name variants
        $normalizedPattern = $pattern.Trim()
        $patternName = [System.IO.Path]::GetFileName($normalizedPattern)
        $patternBase = [System.IO.Path]::GetFileNameWithoutExtension($normalizedPattern)

        $candidates = @($candidateFull, $candidateName, $candidateBase)
        $patterns = @($normalizedPattern, $patternName, $patternBase)

        # Try all combinations of candidate and pattern variants (supports wildcards via -like)
        foreach ($candidate in $candidates) {
            foreach ($patternVariant in $patterns) {
                if ([string]::IsNullOrWhiteSpace($candidate) -or [string]::IsNullOrWhiteSpace($patternVariant)) {
                    continue
                }

                if ($candidate -like $patternVariant) {
                    return $true
                }
            }
        }
    }

    return $false
}

# Initialize fragment warning suppression from environment variable
Initialize-FragmentWarningSuppression

