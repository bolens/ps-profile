<#
scripts/lib/utilities/RequirementsLoader.psm1

.SYNOPSIS
    Requirements file loader with support for modular requirements structure.

.DESCRIPTION
    Provides functions for loading requirements configuration files.
    Loads requirements from the modular structure in requirements/ directory.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Cache module for caching support
$cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $cacheModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($cacheModulePath -and -not [string]::IsNullOrWhiteSpace($cacheModulePath) -and (Test-Path -LiteralPath $cacheModulePath)) {
        Import-Module $cacheModulePath -ErrorAction SilentlyContinue
    }
}

# Import DataFile module for Import-CachedPowerShellDataFile
$dataFileModulePath = Join-Path $PSScriptRoot 'DataFile.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $dataFileModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($dataFileModulePath -and -not [string]::IsNullOrWhiteSpace($dataFileModulePath) -and (Test-Path -LiteralPath $dataFileModulePath)) {
        Import-Module $dataFileModulePath -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Loads requirements configuration from modular or legacy format.

.DESCRIPTION
    Loads requirements configuration from the modular structure in
    requirements/load-requirements.ps1.

.PARAMETER RepoRoot
    Path to repository root. If not specified, attempts to detect from current location.

.PARAMETER UseCache
    If specified, uses caching to avoid re-loading requirements multiple times.
    Defaults to $true.

.OUTPUTS
    Hashtable containing requirements configuration with:
    - PowerShellVersion
    - Modules
    - ExternalTools
    - PlatformRequirements

.EXAMPLE
    $requirements = Import-Requirements -RepoRoot $repoRoot
    
    Loads requirements configuration from modular or legacy format.
#>
function Import-Requirements {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$RepoRoot,
        
        [switch]$UseCache = $true
    )

    # Detect repository root if not provided
    if (-not $RepoRoot) {
        # Try to get from current location
        $currentPath = Get-Location
        $testPath = $currentPath.Path
        
        # Walk up directory tree to find repository root
        # Look for requirements directory (modular structure)
        # Use Validation module if available
        $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
        
        while ($testPath -and $testPath -ne (Split-Path -Parent $testPath)) {
            $requirementsDir = Join-Path $testPath 'requirements'
            $exists = if ($useValidation) {
                Test-ValidPath -Path $requirementsDir -PathType Directory
            }
            else {
                $requirementsDir -and -not [string]::IsNullOrWhiteSpace($requirementsDir) -and (Test-Path -LiteralPath $requirementsDir -PathType Container)
            }
            if ($exists) {
                $RepoRoot = $testPath
                break
            }
            $testPath = Split-Path -Parent $testPath
        }
        
        if (-not $RepoRoot) {
            throw "Could not detect repository root. Please specify -RepoRoot parameter."
        }
    }

    # Check cache if enabled
    if ($UseCache -and (Get-Command Get-CachedValue -ErrorAction SilentlyContinue)) {
        # Use CacheKey module if available for consistent key generation
        $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
            # New-CacheKey expects Components to be an array, wrap single string in array
            New-CacheKey -Prefix 'Requirements' -Components @($RepoRoot)
        }
        else {
            "Requirements_$RepoRoot"
        }
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            Write-Verbose "Using cached requirements from $RepoRoot"
            return $cachedResult
        }
    }

    # Try modular loader first
    $requirementsLoaderPath = Join-Path $RepoRoot 'requirements' 'load-requirements.ps1'
    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    $loaderExists = if ($useValidation) {
        Test-ValidPath -Path $requirementsLoaderPath -PathType File
    }
    else {
        $requirementsLoaderPath -and -not [string]::IsNullOrWhiteSpace($requirementsLoaderPath) -and (Test-Path -LiteralPath $requirementsLoaderPath)
    }
    if ($loaderExists) {
        try {
            Write-Verbose "Loading requirements from modular structure: $requirementsLoaderPath"
            $requirements = & $requirementsLoaderPath
            
            # Cache result if enabled
            if ($UseCache -and (Get-Command Set-CachedValue -ErrorAction SilentlyContinue)) {
                Set-CachedValue -Key $cacheKey -Value $requirements -ExpirationSeconds 300
            }
            
            return $requirements
        }
        catch {
            Write-Warning "Failed to load modular requirements: $($_.Exception.Message). Falling back to legacy format."
        }
    }

    # No fallback - modular structure is required
    throw "Requirements loader not found at: $requirementsLoaderPath. Please ensure the modular requirements structure exists in the requirements/ directory."
}

# Export functions
Export-ModuleMember -Function 'Import-Requirements'

Export-ModuleMember -Function 'Import-Requirements'

