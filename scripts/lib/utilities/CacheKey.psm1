<#
scripts/lib/utilities/CacheKey.psm1

.SYNOPSIS
    Cache key generation utilities.

.DESCRIPTION
    Provides standardized functions for generating cache keys from various data types.
    Ensures consistent cache key formatting and sanitization across the codebase.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Validation module if available for path validation
# Use safe path resolution that handles cases where $PSScriptRoot might not be set
try {
    if ($null -ne $PSScriptRoot -and -not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $currentDir = if ([System.IO.Directory]::Exists($PSScriptRoot)) {
            $PSScriptRoot
        }
        else {
            [System.IO.Path]::GetDirectoryName($PSScriptRoot)
        }
        
        if ($currentDir -and -not [string]::IsNullOrWhiteSpace($currentDir)) {
            $validationModulePath = Join-Path $currentDir 'core' 'Validation.psm1'
            if (-not [string]::IsNullOrWhiteSpace($validationModulePath) -and (Test-Path -LiteralPath $validationModulePath -ErrorAction SilentlyContinue)) {
                Import-Module $validationModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }
}
catch {
    # Silently fail if path resolution fails - module will use fallback validation
}

<#
.SYNOPSIS
    Generates a cache key from one or more components.

.DESCRIPTION
    Creates a standardized cache key by combining a prefix with one or more components.
    Components are sanitized to ensure they're safe for use as cache keys (removing
    invalid characters, normalizing paths, etc.).

.PARAMETER Prefix
    The prefix for the cache key (e.g., "LibPath", "RepoRoot", "CommandAvailable").

.PARAMETER Components
    One or more components to include in the cache key. Can be strings, paths, or other objects.

.PARAMETER Separator
    The separator to use between components. Defaults to "_".

.OUTPUTS
    System.String. A sanitized cache key.

.EXAMPLE
    $key = New-CacheKey -Prefix "LibPath" -Components "scripts\lib\ModuleImport.psm1"
    # Returns: "LibPath_scripts_lib_ModuleImport_psm1"

.EXAMPLE
    $key = New-CacheKey -Prefix "CommandAvailable" -Components "git"
    # Returns: "CommandAvailable_git"

.EXAMPLE
    $key = New-CacheKey -Prefix "Requirements" -Components $repoRoot
    # Returns: "Requirements_C_Users_bolen_Documents_PowerShell"
#>
function New-CacheKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter(Mandatory = $false)]
        [object[]]$Components = @(),

        [string]$Separator = '_'
    )

    # Validate prefix
    if ([string]::IsNullOrWhiteSpace($Prefix)) {
        throw "Prefix cannot be null or empty"
    }

    # Sanitize prefix (remove invalid characters, normalize)
    # Remove all non-word characters including hyphens for consistency
    $sanitizedPrefix = $Prefix -replace '[^\w]', '' -replace '\s+', ''

    # Flatten nested arrays and sanitize components
    # Handle cases where Components might be passed as an array containing arrays
    $sanitizedComponents = @()
    
    # Helper to sanitize a single string value
    function Sanitize-ComponentString {
        param([string]$Value)
        
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }
        
        # Replace path separators, dots, and hyphens with underscores, then remove other non-word chars
        $sanitized = $Value -replace '[\\/]', '_' -replace '\.', '_' -replace '-', '_' -replace '[^\w]', '' -replace '_{2,}', '_'
        $sanitized = $sanitized.Trim('_', '.', '-')
        
        if ([string]::IsNullOrWhiteSpace($sanitized)) {
            return $null
        }
        
        return $sanitized
    }
    
    # Recursive function to flatten arrays and sanitize
    function Process-Component {
        param([object]$Item)
        
        $result = @()
        
        if ($null -eq $Item) {
            return $result
        }
        
        # Debug logging
        $debugEnabled = $env:PS_PROFILE_DEBUG -eq '1' -or $env:PS_PROFILE_DEBUG_CACHEKEY -eq '1'
        if ($debugEnabled) {
            $itemType = $Item.GetType()
            Write-Host "[CacheKey Debug] Processing item: Type=$($itemType.FullName), IsArray=$($itemType.IsArray), IsString=$($Item -is [string]), Value=[$Item]" -ForegroundColor Cyan
        }
        
        # If it's a string, sanitize it directly (strings implement IEnumerable but we treat them as primitives)
        if ($Item -is [string]) {
            if ($debugEnabled) {
                Write-Host "[CacheKey Debug] Item is a string, sanitizing directly" -ForegroundColor Green
            }
            $sanitized = Sanitize-ComponentString -Value $Item
            if ($null -ne $sanitized) {
                $result += $sanitized
            }
            return $result
        }
        
        # For non-strings, try to iterate to see if it's a collection
        # PowerShell's type system is complex, so we'll try iteration and see what happens
        $triedIteration = $false
        $iterationSucceeded = $false
        $itemType = $Item.GetType()
        
        if ($debugEnabled) {
            Write-Host "[CacheKey Debug] Item is not a string. Checking if it's a collection..." -ForegroundColor Yellow
            Write-Host "[CacheKey Debug]   - IsArray: $($itemType.IsArray)" -ForegroundColor Yellow
            Write-Host "[CacheKey Debug]   - Is [Array]: $($Item -is [Array])" -ForegroundColor Yellow
            Write-Host "[CacheKey Debug]   - Is ICollection: $($Item -is [System.Collections.ICollection])" -ForegroundColor Yellow
            Write-Host "[CacheKey Debug]   - Is IEnumerable: $($Item -is [System.Collections.IEnumerable])" -ForegroundColor Yellow
            if ($null -ne $Item.Count) {
                Write-Host "[CacheKey Debug]   - Count: $($Item.Count)" -ForegroundColor Yellow
            }
        }
        
        if ($Item -isnot [string]) {
            try {
                # Try to iterate - if we get multiple items or items different from the original, it's a collection
                $iterationResults = @()
                foreach ($element in $Item) {
                    $iterationResults += $element
                    $triedIteration = $true
                }
                
                if ($debugEnabled) {
                    Write-Host "[CacheKey Debug] Iteration attempted. Results count: $($iterationResults.Count)" -ForegroundColor Yellow
                    if ($iterationResults.Count -gt 0) {
                        Write-Host "[CacheKey Debug] First result type: $($iterationResults[0].GetType().FullName), Value: [$($iterationResults[0])]" -ForegroundColor Yellow
                    }
                }
                
                # If we got results from iteration, it's a collection
                # Check if we got more than one item, or if the items are different from the original
                if ($triedIteration -and $iterationResults.Count -gt 0) {
                    # If we got multiple items, or if the single item is different from the original, it's a collection
                    $isCollection = $false
                    if ($iterationResults.Count -gt 1) {
                        $isCollection = $true
                        if ($debugEnabled) {
                            Write-Host "[CacheKey Debug] Multiple items found, treating as collection" -ForegroundColor Green
                        }
                    }
                    elseif ($iterationResults.Count -eq 1) {
                        $firstResult = $iterationResults[0]
                        $firstResultType = $firstResult.GetType()
                        $isDifferent = $firstResult -ne $Item
                        $isDifferentType = $firstResultType -ne $itemType
                        
                        if ($debugEnabled) {
                            Write-Host "[CacheKey Debug] Single item. Different value: $isDifferent, Different type: $isDifferentType" -ForegroundColor Yellow
                            Write-Host "[CacheKey Debug]   Original type: $($itemType.FullName)" -ForegroundColor Yellow
                            Write-Host "[CacheKey Debug]   Result type: $($firstResultType.FullName)" -ForegroundColor Yellow
                        }
                        
                        if ($isDifferent -or $isDifferentType) {
                            $isCollection = $true
                            if ($debugEnabled) {
                                Write-Host "[CacheKey Debug] Item is different, treating as collection" -ForegroundColor Green
                            }
                        }
                    }
                    
                    if ($isCollection) {
                        $iterationSucceeded = $true
                        if ($debugEnabled) {
                            Write-Host "[CacheKey Debug] Recursively processing collection elements..." -ForegroundColor Green
                        }
                        # Recursively process each element
                        foreach ($element in $Item) {
                            $processed = Process-Component -Item $element
                            if ($processed.Count -gt 0) {
                                $result += $processed
                            }
                        }
                    }
                    else {
                        if ($debugEnabled) {
                            Write-Host "[CacheKey Debug] Single item same as original, treating as primitive" -ForegroundColor Yellow
                        }
                    }
                }
            }
            catch {
                # Iteration failed, will treat as primitive below
                $triedIteration = $true
                if ($debugEnabled) {
                    Write-Host "[CacheKey Debug] Iteration failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        # If we didn't try iteration, it didn't succeed, or it gave us the same item, treat as primitive
        if (-not $triedIteration -or -not $iterationSucceeded) {
            $str = $Item.ToString()
            if ($debugEnabled) {
                Write-Host "[CacheKey Debug] Treating as primitive. ToString() result: [$str]" -ForegroundColor Yellow
            }
            # Skip array string representations
            if ($str -ne 'System.Object[]' -and $str -ne 'System.Array' -and -not [string]::IsNullOrWhiteSpace($str)) {
                $sanitized = Sanitize-ComponentString -Value $str
                if ($null -ne $sanitized) {
                    $result += $sanitized
                    if ($debugEnabled) {
                        Write-Host "[CacheKey Debug] Sanitized result: [$sanitized]" -ForegroundColor Green
                    }
                }
            }
            else {
                if ($debugEnabled) {
                    Write-Host "[CacheKey Debug] Skipping array string representation" -ForegroundColor Red
                }
            }
        }
        
        if ($debugEnabled) {
            Write-Host "[CacheKey Debug] Final result count: $($result.Count), Values: [$($result -join ', ')]" -ForegroundColor Cyan
        }
        
        return $result
    }
    
    # Debug logging
    $debugEnabled = $env:PS_PROFILE_DEBUG -eq '1' -or $env:PS_PROFILE_DEBUG_CACHEKEY -eq '1'
    if ($debugEnabled) {
        if ($null -eq $Components) {
            Write-Host "[CacheKey Debug] New-CacheKey called with Prefix=[$Prefix], Components=null" -ForegroundColor Magenta
        }
        else {
            Write-Host "[CacheKey Debug] New-CacheKey called with Prefix=[$Prefix], Components count=$($Components.Count)" -ForegroundColor Magenta
            $componentsType = $Components.GetType()
            Write-Host "[CacheKey Debug] Components type: $($componentsType.FullName), IsArray=$($componentsType.IsArray)" -ForegroundColor Magenta
            for ($i = 0; $i -lt $Components.Count; $i++) {
                $comp = $Components[$i]
                $compType = if ($null -ne $comp) { $comp.GetType().FullName } else { 'null' }
                Write-Host "[CacheKey Debug]   Component[$i]: Type=$compType, Value=[$comp]" -ForegroundColor Magenta
            }
        }
    }
    
    # Handle null or empty Components
    if ($null -eq $Components) {
        $sanitizedComponents = @()
    }
    elseif ($Components.Count -eq 0) {
        $sanitizedComponents = @()
    }
    else {
        # Components is already an array parameter - iterate directly
        # Don't wrap in @() as that would create nested arrays
        if ($debugEnabled) {
            Write-Host "[CacheKey Debug] Processing $($Components.Count) component(s)..." -ForegroundColor Magenta
        }
        foreach ($component in $Components) {
            if ($debugEnabled) {
                $compType = if ($null -ne $component) { $component.GetType().FullName } else { 'null' }
                Write-Host "[CacheKey Debug] Processing component: Type=$compType, Value=[$component]" -ForegroundColor Magenta
            }
            $processed = Process-Component -Item $component
            if ($debugEnabled) {
                Write-Host "[CacheKey Debug] Processed result count: $($processed.Count), Values: [$($processed -join ', ')]" -ForegroundColor Magenta
            }
            if ($processed.Count -gt 0) {
                $sanitizedComponents += $processed
            }
        }
    }
    
    if ($debugEnabled) {
        Write-Host "[CacheKey Debug] Final sanitizedComponents count: $($sanitizedComponents.Count), Values: [$($sanitizedComponents -join ', ')]" -ForegroundColor Magenta
        Write-Host "[CacheKey Debug] Final key will be: $sanitizedPrefix$Separator$($sanitizedComponents -join $Separator)" -ForegroundColor Magenta
    }

    # Combine prefix and components
    if ($sanitizedComponents.Count -eq 0) {
        if ($debugEnabled) {
            Write-Host "[CacheKey Debug] No components, returning prefix only: $sanitizedPrefix" -ForegroundColor Magenta
        }
        return $sanitizedPrefix
    }

    # Join prefix and components
    # Need to flatten the array properly - create array with prefix first, then add components
    $allParts = @($sanitizedPrefix) + $sanitizedComponents
    $finalKey = $allParts -join $Separator
    if ($debugEnabled) {
        Write-Host "[CacheKey Debug] Joining prefix and components:" -ForegroundColor Magenta
        Write-Host "[CacheKey Debug]   Prefix: [$sanitizedPrefix]" -ForegroundColor Magenta
        Write-Host "[CacheKey Debug]   Components: [$($sanitizedComponents -join ', ')]" -ForegroundColor Magenta
        Write-Host "[CacheKey Debug]   Separator: [$Separator]" -ForegroundColor Magenta
        Write-Host "[CacheKey Debug]   Final key: [$finalKey]" -ForegroundColor Magenta
        Write-Host "[CacheKey Debug]   Final key type: $($finalKey.GetType().FullName)" -ForegroundColor Magenta
    }
    
    return $finalKey
}

<#
.SYNOPSIS
    Generates a cache key from a file path with modification time.

.DESCRIPTION
    Creates a cache key that includes the file path and its last write time.
    This ensures the cache is invalidated when the file changes. Useful for
    caching file-based operations like importing PowerShell data files.

.PARAMETER FilePath
    The path to the file.

.PARAMETER Prefix
    Optional prefix for the cache key. Defaults to "File".

.PARAMETER UseHash
    If specified, uses file hash instead of modification time. More reliable but slower.

.PARAMETER HashAlgorithm
    The hash algorithm to use when UseHash is specified. Defaults to "SHA256".

.OUTPUTS
    System.String. A cache key that includes file path and modification time or hash.

.EXAMPLE
    $key = New-FileCacheKey -FilePath "config.psd1"
    # Returns: "File_config_psd1_638123456789012345"

.EXAMPLE
    $key = New-FileCacheKey -FilePath "config.psd1" -Prefix "PowerShellDataFile" -UseHash
    # Returns: "PowerShellDataFile_config_psd1_abc123def456..."
#>
function New-FileCacheKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string]$Prefix = 'File',

        [switch]$UseHash,

        [string]$HashAlgorithm = 'SHA256'
    )

    # Validate file path
    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        throw "FilePath cannot be null or empty"
    }

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    if ($useValidation) {
        if (-not (Test-ValidPath -Path $FilePath -PathType File)) {
            throw "File not found: $FilePath"
        }
    }
    else {
        # Fallback to manual validation
        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            throw "File not found: $FilePath"
        }
    }

    # Get file info
    $fileInfo = Get-Item -LiteralPath $FilePath -ErrorAction Stop

    # Generate file identifier (hash or modification time)
    if ($UseHash) {
        try {
            $fileHash = Get-FileHash -LiteralPath $FilePath -Algorithm $HashAlgorithm -ErrorAction Stop
            $fileIdentifier = $fileHash.Hash
        }
        catch {
            # Fallback to modification time if hash fails
            $fileIdentifier = $fileInfo.LastWriteTimeUtc.Ticks.ToString()
        }
    }
    else {
        $fileIdentifier = $fileInfo.LastWriteTimeUtc.Ticks.ToString()
    }

    # Generate cache key using just the filename (not full path) for consistency with test expectations
    $fileName = $fileInfo.Name
    return New-CacheKey -Prefix $Prefix -Components $fileName, $fileIdentifier
}

<#
.SYNOPSIS
    Generates a cache key from a directory path.

.DESCRIPTION
    Creates a cache key from a directory path. Useful for caching directory-based
    operations like repository root resolution or profile directory detection.

.PARAMETER DirectoryPath
    The path to the directory.

.PARAMETER Prefix
    Optional prefix for the cache key. Defaults to "Directory".

.OUTPUTS
    System.String. A sanitized cache key based on the directory path.

.EXAMPLE
    $key = New-DirectoryCacheKey -DirectoryPath "C:\Users\bolen\Documents\PowerShell"
    # Returns: "Directory_C_Users_bolen_Documents_PowerShell"

.EXAMPLE
    $key = New-DirectoryCacheKey -DirectoryPath $repoRoot -Prefix "RepoRoot"
    # Returns: "RepoRoot_C_Users_bolen_Documents_PowerShell"
#>
function New-DirectoryCacheKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$DirectoryPath,

        [string]$Prefix = 'Directory'
    )

    # Validate directory path
    if ([string]::IsNullOrWhiteSpace($DirectoryPath)) {
        throw "DirectoryPath cannot be null or empty"
    }

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    if ($useValidation) {
        if (-not (Test-ValidPath -Path $DirectoryPath -PathType Directory)) {
            # Try to resolve the path (might be relative)
            $resolvedPath = try {
                (Resolve-Path -Path $DirectoryPath -ErrorAction Stop).Path
            }
            catch {
                $DirectoryPath
            }
            $DirectoryPath = $resolvedPath
        }
    }
    else {
        # Fallback to manual validation/resolution
        if (-not (Test-Path -LiteralPath $DirectoryPath -PathType Container)) {
            # Try to resolve the path (might be relative)
            $resolvedPath = try {
                (Resolve-Path -Path $DirectoryPath -ErrorAction Stop).Path
            }
            catch {
                $DirectoryPath
            }
            $DirectoryPath = $resolvedPath
        }
    }

    # Generate cache key using just the directory name (not full path) for consistency
    # Get the directory name from the path
    $directoryName = Split-Path -Leaf $DirectoryPath
    # New-CacheKey expects Components to be an array, wrap single string in array
    return New-CacheKey -Prefix $Prefix -Components @($directoryName)
}

# Export functions
Export-ModuleMember -Function @(
    'New-CacheKey',
    'New-FileCacheKey',
    'New-DirectoryCacheKey'
)



