<#
scripts/lib/utilities/EnvFile.psm1

.SYNOPSIS
    Environment file (.env) loading utilities.

.DESCRIPTION
    Provides functions for loading environment variables from .env files.
    Supports standard .env file format with comments, quoted values, and variable expansion.
#>

<#
.SYNOPSIS
    Loads environment variables from a .env file.

.DESCRIPTION
    Parses a .env file and sets environment variables. Supports:
    - Comments (lines starting with #)
    - Quoted values (single or double quotes)
    - Variable expansion ($VAR or ${VAR})
    - Empty lines (ignored)
    - Whitespace trimming
    
    By default, does not overwrite existing environment variables unless Overwrite is specified.

.PARAMETER EnvFilePath
    Path to the .env file to load.

.PARAMETER Overwrite
    If specified, overwrites existing environment variables. Default is to preserve existing values.

.PARAMETER ErrorAction
    Action to take if file is not found or parsing fails. Default is 'SilentlyContinue'.

.EXAMPLE
    Load-EnvFile -EnvFilePath '.env'
    
.EXAMPLE
    Load-EnvFile -EnvFilePath '.env.local' -Overwrite
#>
function Load-EnvFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvFilePath,
        
        [switch]$Overwrite
    )
    
    # Get ErrorAction preference from common parameter
    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'SilentlyContinue'
    }
    
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $EnvFilePath -PathType File)) {
            if ($errorActionPreference -eq 'Stop') {
                throw "Environment file not found: $EnvFilePath"
            }
            return
        }
    }
    else {
        # Fallback to manual validation
        if (-not (Test-Path -LiteralPath $EnvFilePath)) {
            if ($errorActionPreference -eq 'Stop') {
                throw "Environment file not found: $EnvFilePath"
            }
            return
        }
    }
    
    try {
        $lines = Get-Content -LiteralPath $EnvFilePath -Raw
        if (-not $lines) {
            return
        }
        
        # Split by newlines, handling both Windows (\r\n) and Unix (\n) line endings
        $lineArray = $lines -split '\r?\n'
        
        foreach ($line in $lineArray) {
            # Trim whitespace
            $line = $line.Trim()
            
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                continue
            }
            
            # Skip lines that don't contain '=' (not a valid env var assignment)
            if ($line -notmatch '=') {
                continue
            }
            
            # Parse key=value
            $equalsIndex = $line.IndexOf('=')
            $key = $line.Substring(0, $equalsIndex).Trim()
            $value = $line.Substring($equalsIndex + 1).Trim()
            
            # Skip if key is empty
            if ([string]::IsNullOrWhiteSpace($key)) {
                continue
            }
            
            # Handle quoted values
            if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                $value = $value.Substring(1, $value.Length - 2)
                # Unescape quotes
                $value = $value -replace '\\"', '"'
            }
            elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
                $value = $value.Substring(1, $value.Length - 2)
                # Unescape single quotes
                $value = $value -replace "\\'", "'"
            }
            
            # Handle variable expansion: $VAR or ${VAR}
            if ($value -match '\$\{?(\w+)\}?') {
                $expandedValue = $value
                $matches = [regex]::Matches($value, '\$\{?(\w+)\}?')
                foreach ($match in $matches) {
                    $varName = $match.Groups[1].Value
                    $varValue = (Get-Item -Path "env:$varName" -ErrorAction SilentlyContinue).Value
                    if ($null -ne $varValue) {
                        $expandedValue = $expandedValue -replace [regex]::Escape($match.Value), $varValue
                    }
                }
                $value = $expandedValue
            }
            
            # Set environment variable (only if not exists or Overwrite is specified)
            if ($Overwrite -or -not (Get-Item -Path "env:$key" -ErrorAction SilentlyContinue)) {
                Set-Item -Path "env:$key" -Value $value
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Loaded env var: $key = $value"
                }
            }
            elseif ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Skipped env var (already set): $key"
            }
        }
    }
    catch {
        $errorMessage = "Failed to load environment file '$EnvFilePath': $($_.Exception.Message)"
        if ($errorActionPreference -eq 'Stop') {
            throw $errorMessage
        }
        elseif ($errorActionPreference -eq 'Continue') {
            Write-Warning $errorMessage
        }
    }
}

<#
.SYNOPSIS
    Loads environment variables from .env files in the repository root.

.DESCRIPTION
    Automatically loads .env and .env.local files from the repository root.
    Loads .env first, then .env.local (which can override .env values).
    Only sets environment variables that don't already exist unless Overwrite is specified.

.PARAMETER RepoRoot
    Repository root directory. If not provided, attempts to detect it.

.PARAMETER Overwrite
    If specified, overwrites existing environment variables. Default is to preserve existing values.

.EXAMPLE
    Initialize-EnvFiles
    
.EXAMPLE
    Initialize-EnvFiles -RepoRoot 'C:\Projects\MyRepo' -Overwrite
#>
function Initialize-EnvFiles {
    [CmdletBinding()]
    param(
        [string]$RepoRoot,
        
        [switch]$Overwrite
    )
    
    # Try to get repo root if not provided
    if (-not $RepoRoot) {
        # Try to use Get-RepoRoot if available (requires a script path)
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            # Try to get script path from caller
            $callerScript = if ($MyInvocation.ScriptName) {
                $MyInvocation.ScriptName
            }
            elseif ($PSCommandPath) {
                $PSCommandPath
            }
            else {
                # Fallback: use profile path if available
                if (Get-Variable -Name 'Profile' -Scope Global -ErrorAction SilentlyContinue) {
                    $global:Profile
                }
            }
            
            if ($callerScript) {
                try {
                    $RepoRoot = Get-RepoRoot -ScriptPath $callerScript
                }
                catch {
                    # Get-RepoRoot failed, try other methods
                }
            }
        }
        
        # Fallback: try to detect from profile location
        if (-not $RepoRoot) {
            if (Get-Variable -Name 'Profile' -Scope Global -ErrorAction SilentlyContinue) {
                $profilePath = $global:Profile
                if ($profilePath) {
                    $profileDir = Split-Path -Parent $profilePath
                    # Check if we're in the profile repository
                    if (Test-Path (Join-Path $profileDir '.git')) {
                        $RepoRoot = $profileDir
                    }
                    else {
                        # Try parent directory
                        $parentDir = Split-Path -Parent $profileDir
                        if (Test-Path (Join-Path $parentDir '.git')) {
                            $RepoRoot = $parentDir
                        }
                    }
                }
            }
        }
        
        # Fallback: try current directory
        if (-not $RepoRoot) {
            $current = Get-Location
            $currentPath = if ($current -is [System.Management.Automation.PathInfo]) {
                $current.Path
            }
            else {
                $current.ToString()
            }
            $driveRoot = if ($currentPath) {
                $qualifier = Split-Path -Qualifier $currentPath -ErrorAction SilentlyContinue
                if ($qualifier) {
                    "$qualifier\"
                }
                else {
                    $null
                }
            }
            else {
                $null
            }
            while ($currentPath -and $currentPath -ne $driveRoot) {
                if (Test-Path (Join-Path $currentPath '.git')) {
                    $RepoRoot = $currentPath
                    break
                }
                $parent = Split-Path -Parent $currentPath
                if (-not $parent -or $parent -eq $currentPath) {
                    # Reached root or can't go further, stop
                    break
                }
                $currentPath = $parent
            }
        }
    }
    
    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    
    $repoRootValid = if ($useValidation) {
        Test-ValidPath -Path $RepoRoot -PathType Directory
    }
    else {
        $RepoRoot -and -not [string]::IsNullOrWhiteSpace($RepoRoot) -and (Test-Path -LiteralPath $RepoRoot)
    }
    
    if (-not $repoRootValid) {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Could not determine repository root for .env file loading"
        }
        return
    }
    
    # Load .env first (base configuration)
    $envFile = Join-Path $RepoRoot '.env'
    $envFileExists = if ($useValidation) {
        Test-ValidPath -Path $envFile -PathType File
    }
    else {
        $envFile -and -not [string]::IsNullOrWhiteSpace($envFile) -and (Test-Path -LiteralPath $envFile)
    }
    if ($envFileExists) {
        Load-EnvFile -EnvFilePath $envFile -Overwrite:$Overwrite -ErrorAction SilentlyContinue
    }
    
    # Load .env.local second (local overrides, can override .env)
    $envLocalFile = Join-Path $RepoRoot '.env.local'
    $envLocalFileExists = if ($useValidation) {
        Test-ValidPath -Path $envLocalFile -PathType File
    }
    else {
        $envLocalFile -and -not [string]::IsNullOrWhiteSpace($envLocalFile) -and (Test-Path -LiteralPath $envLocalFile)
    }
    if ($envLocalFileExists) {
        Load-EnvFile -EnvFilePath $envLocalFile -Overwrite -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function 'Load-EnvFile', 'Initialize-EnvFiles'

