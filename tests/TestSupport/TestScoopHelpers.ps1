# ===============================================
# TestScoopHelpers.ps1
# Scoop package availability testing utilities
# ===============================================

<#
.SYNOPSIS
    Checks if a Scoop package is available for use.
.DESCRIPTION
    Tests whether a specified Scoop package is installed.
    Uses Scoop's list command to check for package availability.
.PARAMETER PackageName
    The name of the Scoop package to check (e.g., 'bat', 'fd', 'docker').
.EXAMPLE
    Test-ScoopPackageAvailable -PackageName 'bat'
    Checks if the bat package is installed via Scoop.
.OUTPUTS
    System.Boolean
    Returns $true if the package is available, $false otherwise.
.NOTES
    This function is used by test files to determine if Scoop packages are installed
    before running tests that depend on them. It requires Scoop to be installed.
#>
function Test-ScoopPackageAvailable {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # Check if Scoop is available
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        return $false
    }
    
    # Use ScoopDetection module if available
    if (Get-Command Test-ScoopInstalled -ErrorAction SilentlyContinue) {
        if (-not (Test-ScoopInstalled)) {
            return $false
        }
    }
    
    # Check if package is installed using scoop list
    try {
        $scoopList = & scoop list $PackageName 2>&1
        if ($LASTEXITCODE -eq 0 -and $scoopList) {
            # Check if the package name appears in the output
            # Scoop list output format: "  package-name version [bucket]"
            # The package name appears after whitespace at the start of a line
            $packageFound = $scoopList | Where-Object { 
                $_ -match "^\s+$([regex]::Escape($PackageName))(\s|$)"
            }
            return ($null -ne $packageFound -and $packageFound.Count -gt 0)
        }
        return $false
    }
    catch {
        return $false
    }
}

