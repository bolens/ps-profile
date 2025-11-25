# ===============================================
# Security utility functions
# Path validation and password generation
# ===============================================

# Security helper for path validation
<#
.SYNOPSIS
    Validates that a path is safe and within a base directory.
.DESCRIPTION
    Checks if a resolved path is within a specified base directory to prevent
    path traversal attacks. Useful for validating user input before file operations.
.PARAMETER Path
    The path to validate.
.PARAMETER BasePath
    The base directory that the path must be within.
.OUTPUTS
    System.Boolean. Returns $true if path is safe, $false otherwise.
.EXAMPLE
    if (Test-SafePath -Path $userPath -BasePath $homeDir) {
        # Safe to use the path
    }
#>
function Test-SafePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$BasePath
    )

    try {
        # Try to resolve the path if it exists
        try {
            $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop | Select-Object -ExpandProperty Path
        }
        catch {
            # If path doesn't exist, get the unresolved provider path and normalize it
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)
        }

        # Try to resolve the base path if it exists
        try {
            $resolvedBase = Resolve-Path -Path $BasePath -ErrorAction Stop | Select-Object -ExpandProperty Path
        }
        catch {
            # If base path doesn't exist, get the unresolved provider path and normalize it
            $resolvedBase = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BasePath)
            $resolvedBase = [System.IO.Path]::GetFullPath($resolvedBase)
        }

        # Ensure base path ends with directory separator for proper comparison
        if (-not $resolvedBase.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
            $resolvedBase += [System.IO.Path]::DirectorySeparatorChar
        }

        return $resolvedPath.StartsWith($resolvedBase, [System.StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        # If path resolution fails, consider it unsafe
        return $false
    }
}

# Generate random password
<#
.SYNOPSIS
    Generates a random password.
.DESCRIPTION
    Creates a 16-character random password using alphanumeric characters.
#>
function New-RandomPassword { -join ((1..16) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) }) }
Set-Alias -Name pwgen -Value New-RandomPassword -ErrorAction SilentlyContinue

