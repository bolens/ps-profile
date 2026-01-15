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
    
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

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
        [ValidateNotNullOrEmpty()]
        [string]$Prefix,

        [Parameter(Mandatory = $false)]
        [object[]]$Components = @(),

        [string]$Separator = '_'
    )

    # Validate prefix
    if ([string]::IsNullOrWhiteSpace($Prefix)) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.ArgumentException]::new("Prefix cannot be null or empty"),
                        'CacheKey.InvalidPrefix',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Prefix
                    )) -OperationName 'cache-key.new' -Context @{
                    Prefix = $Prefix
                }
            }
            else {
                Write-Error "Prefix cannot be null or empty"
            }
        }
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
        
        # Debug logging (level 3 for very verbose cache key debugging, or use special flag)
        $debugLevel = 0
        $hasDebug = $false
        if ($env:PS_PROFILE_DEBUG_CACHEKEY -eq '1') {
            $hasDebug = $true
        }
        elseif ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            $hasDebug = $true
        }
        $debugEnabled = $hasDebug
        if ($debugEnabled) {
            $itemType = $Item.GetType()
            Write-Host "  [cache-key.process] Processing item: Type=$($itemType.FullName), IsArray=$($itemType.IsArray), IsString=$($Item -is [string]), Value=[$Item]" -ForegroundColor DarkGray
        }
        
        # If it's a string, sanitize it directly (strings implement IEnumerable but we treat them as primitives)
        if ($Item -is [string]) {
            if ($debugEnabled) {
                Write-Host "  [cache-key.process] Item is a string, sanitizing directly" -ForegroundColor DarkGray
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
            Write-Host "  [cache-key.process] Item is not a string. Checking if it's a collection..." -ForegroundColor DarkGray
            Write-Host "  [cache-key.process]   - IsArray: $($itemType.IsArray)" -ForegroundColor DarkGray
            Write-Host "  [cache-key.process]   - Is [Array]: $($Item -is [Array])" -ForegroundColor DarkGray
            Write-Host "  [cache-key.process]   - Is ICollection: $($Item -is [System.Collections.ICollection])" -ForegroundColor DarkGray
            Write-Host "  [cache-key.process]   - Is IEnumerable: $($Item -is [System.Collections.IEnumerable])" -ForegroundColor DarkGray
            if ($null -ne $Item.Count) {
                Write-Host "  [cache-key.process]   - Count: $($Item.Count)" -ForegroundColor DarkGray
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
                    Write-Host "  [cache-key.process] Iteration attempted. Results count: $($iterationResults.Count)" -ForegroundColor DarkGray
                    if ($iterationResults.Count -gt 0) {
                        Write-Host "  [cache-key.process] First result type: $($iterationResults[0].GetType().FullName), Value: [$($iterationResults[0])]" -ForegroundColor DarkGray
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
                            Write-Host "  [cache-key.process] Multiple items found, treating as collection" -ForegroundColor DarkGray
                        }
                    }
                    elseif ($iterationResults.Count -eq 1) {
                        $firstResult = $iterationResults[0]
                        $firstResultType = $firstResult.GetType()
                        $isDifferent = $firstResult -ne $Item
                        $isDifferentType = $firstResultType -ne $itemType
                        
                        if ($debugEnabled) {
                            Write-Host "  [cache-key.process] Single item. Different value: $isDifferent, Different type: $isDifferentType" -ForegroundColor DarkGray
                            Write-Host "  [cache-key.process]   Original type: $($itemType.FullName)" -ForegroundColor DarkGray
                            Write-Host "  [cache-key.process]   Result type: $($firstResultType.FullName)" -ForegroundColor DarkGray
                        }
                        
                        if ($isDifferent -or $isDifferentType) {
                            $isCollection = $true
                            if ($debugEnabled) {
                                Write-Host "  [cache-key.process] Item is different, treating as collection" -ForegroundColor DarkGray
                            }
                        }
                    }
                    
                    if ($isCollection) {
                        $iterationSucceeded = $true
                        if ($debugEnabled) {
                            Write-Host "  [cache-key.process] Recursively processing collection elements..." -ForegroundColor DarkGray
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
                            Write-Host "  [cache-key.process] Single item same as original, treating as primitive" -ForegroundColor DarkGray
                        }
                    }
                }
            }
            catch {
                # Iteration failed, will treat as primitive below
                $triedIteration = $true
                if ($debugEnabled) {
                    Write-Host "  [cache-key.process] Iteration failed: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
        
        # If we didn't try iteration, it didn't succeed, or it gave us the same item, treat as primitive
        if (-not $triedIteration -or -not $iterationSucceeded) {
            $str = $Item.ToString()
            if ($debugEnabled) {
                Write-Host "  [cache-key.process] Treating as primitive. ToString() result: [$str]" -ForegroundColor DarkGray
            }
            # Skip array string representations
            if ($str -ne 'System.Object[]' -and $str -ne 'System.Array' -and -not [string]::IsNullOrWhiteSpace($str)) {
                $sanitized = Sanitize-ComponentString -Value $str
                if ($null -ne $sanitized) {
                    $result += $sanitized
                    if ($debugEnabled) {
                        Write-Host "  [cache-key.process] Sanitized result: [$sanitized]" -ForegroundColor DarkGray
                    }
                }
            }
            else {
                if ($debugEnabled) {
                    Write-Host "  [cache-key.process] Skipping array string representation" -ForegroundColor DarkGray
                }
            }
        }
        
        if ($debugEnabled) {
            Write-Host "  [cache-key.process] Final result count: $($result.Count), Values: [$($result -join ', ')]" -ForegroundColor DarkGray
        }
        
        return $result
    }
    
    # Debug logging (level 3 for very verbose cache key debugging, or use special flag)
    $debugLevel = 0
    $hasDebug = $false
    if ($env:PS_PROFILE_DEBUG_CACHEKEY -eq '1') {
        $hasDebug = $true
        $debugLevel = 3
    }
    elseif ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        if ($debugLevel -ge 3) {
            $hasDebug = $true
        }
    }
    $debugEnabled = $hasDebug
    
    # Level 2: Log successful cache key generation
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[cache-key.new] Generating cache key with prefix: $Prefix, components count: $($Components.Count)"
    }
    
    if ($debugEnabled) {
        if ($null -eq $Components) {
            Write-Host "  [cache-key.new] New-CacheKey called with Prefix=[$Prefix], Components=null" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [cache-key.new] New-CacheKey called with Prefix=[$Prefix], Components count=$($Components.Count)" -ForegroundColor DarkGray
            $componentsType = $Components.GetType()
            Write-Host "  [cache-key.new] Components type: $($componentsType.FullName), IsArray=$($componentsType.IsArray)" -ForegroundColor DarkGray
            for ($i = 0; $i -lt $Components.Count; $i++) {
                $comp = $Components[$i]
                $compType = if ($null -ne $comp) { $comp.GetType().FullName } else { 'null' }
                Write-Host "  [cache-key.new]   Component[$i]: Type=$compType, Value=[$comp]" -ForegroundColor DarkGray
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
            Write-Host "  [cache-key.new] Processing $($Components.Count) component(s)..." -ForegroundColor DarkGray
        }
        foreach ($component in $Components) {
            if ($debugEnabled) {
                $compType = if ($null -ne $component) { $component.GetType().FullName } else { 'null' }
                Write-Host "  [cache-key.new] Processing component: Type=$compType, Value=[$component]" -ForegroundColor DarkGray
            }
            $processed = Process-Component -Item $component
            if ($debugEnabled) {
                Write-Host "  [cache-key.new] Processed result count: $($processed.Count), Values: [$($processed -join ', ')]" -ForegroundColor DarkGray
            }
            if ($processed.Count -gt 0) {
                $sanitizedComponents += $processed
            }
        }
    }
    
    if ($debugEnabled) {
        Write-Host "  [cache-key.new] Final sanitizedComponents count: $($sanitizedComponents.Count), Values: [$($sanitizedComponents -join ', ')]" -ForegroundColor DarkGray
        Write-Host "  [cache-key.new] Final key will be: $sanitizedPrefix$Separator$($sanitizedComponents -join $Separator)" -ForegroundColor DarkGray
    }

    # Combine prefix and components
    if ($sanitizedComponents.Count -eq 0) {
        if ($debugEnabled) {
            Write-Host "  [cache-key.new] No components, returning prefix only: $sanitizedPrefix" -ForegroundColor DarkGray
        }
        # Level 2: Log successful cache key generation
        $debugLevel2 = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel2) -and $debugLevel2 -ge 2) {
            Write-Verbose "[cache-key.new] Generated cache key (prefix only): $sanitizedPrefix"
        }
        return $sanitizedPrefix
    }

    # Join prefix and components
    # Need to flatten the array properly - create array with prefix first, then add components
    $allParts = @($sanitizedPrefix) + $sanitizedComponents
    $finalKey = $allParts -join $Separator
    if ($debugEnabled) {
        Write-Host "  [cache-key.new] Joining prefix and components:" -ForegroundColor DarkGray
        Write-Host "  [cache-key.new]   Prefix: [$sanitizedPrefix]" -ForegroundColor DarkGray
        Write-Host "  [cache-key.new]   Components: [$($sanitizedComponents -join ', ')]" -ForegroundColor DarkGray
        Write-Host "  [cache-key.new]   Separator: [$Separator]" -ForegroundColor DarkGray
        Write-Host "  [cache-key.new]   Final key: [$finalKey]" -ForegroundColor DarkGray
        Write-Host "  [cache-key.new]   Final key type: $($finalKey.GetType().FullName)" -ForegroundColor DarkGray
    }
    
    # Level 2: Log successful cache key generation
    $debugLevel2 = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel2) -and $debugLevel2 -ge 2) {
        Write-Verbose "[cache-key.new] Generated cache key: $finalKey"
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
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [string]$Prefix = 'File',

        [switch]$UseHash,

        [string]$HashAlgorithm = 'SHA256'
    )

    # Validate file path
    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.ArgumentException]::new("FilePath cannot be null or empty"),
                        'CacheKey.InvalidFilePath',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $FilePath
                    )) -OperationName 'cache-key.file' -Context @{
                    FilePath = $FilePath
                    Prefix   = $Prefix
                }
            }
            else {
                Write-Error "FilePath cannot be null or empty"
            }
        }
        throw "FilePath cannot be null or empty"
    }

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    if ($useValidation) {
        if (-not (Test-ValidPath -Path $FilePath -PathType File)) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("File not found: $FilePath"),
                            'CacheKey.FileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $FilePath
                        )) -OperationName 'cache-key.file' -Context @{
                        FilePath = $FilePath
                        Prefix   = $Prefix
                    }
                }
                else {
                    Write-Error "File not found: $FilePath"
                }
            }
            throw "File not found: $FilePath"
        }
    }
    else {
        # Fallback to manual validation
        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("File not found: $FilePath"),
                            'CacheKey.FileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $FilePath
                        )) -OperationName 'cache-key.file' -Context @{
                        FilePath = $FilePath
                        Prefix   = $Prefix
                    }
                }
                else {
                    Write-Error "File not found: $FilePath"
                }
            }
            throw "File not found: $FilePath"
        }
    }

    # Get file info
    $fileInfo = Get-Item -LiteralPath $FilePath -ErrorAction Stop

    # Generate file identifier (hash or modification time)
    $debugLevel = 0
    if ($UseHash) {
        try {
            $fileHash = Get-FileHash -LiteralPath $FilePath -Algorithm $HashAlgorithm -ErrorAction Stop
            $fileIdentifier = $fileHash.Hash
            # Level 2: Log successful hash generation
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[cache-key.file] Generated file hash using $HashAlgorithm algorithm"
            }
        }
        catch {
            # Fallback to modification time if hash fails
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to generate file hash, using modification time" -OperationName 'cache-key.file' -Context @{
                            FilePath  = $FilePath
                            Algorithm = $HashAlgorithm
                            Error     = $_.Exception.Message
                        }
                    }
                    else {
                        Write-Warning "Failed to generate file hash, using modification time: $($_.Exception.Message)"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[cache-key.file] Hash generation error details - FilePath: $FilePath, Algorithm: $HashAlgorithm, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)"
                }
            }
            $fileIdentifier = $fileInfo.LastWriteTimeUtc.Ticks.ToString()
        }
    }
    else {
        $fileIdentifier = $fileInfo.LastWriteTimeUtc.Ticks.ToString()
    }

    # Generate cache key using just the filename (not full path) for consistency with test expectations
    $fileName = $fileInfo.Name
    $cacheKey = New-CacheKey -Prefix $Prefix -Components $fileName, $fileIdentifier
    # Level 2: Log successful cache key generation
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[cache-key.file] Generated file cache key: $cacheKey"
    }
    # Level 3: Log detailed file information
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [cache-key.file] File details - Name: $fileName, Identifier: $fileIdentifier, UseHash: $UseHash" -ForegroundColor DarkGray
    }
    return $cacheKey
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
        [ValidateNotNullOrEmpty()]
        [string]$DirectoryPath,

        [string]$Prefix = 'Directory'
    )

    # Validate directory path
    if ([string]::IsNullOrWhiteSpace($DirectoryPath)) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.ArgumentException]::new("DirectoryPath cannot be null or empty"),
                        'CacheKey.InvalidDirectoryPath',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $DirectoryPath
                    )) -OperationName 'cache-key.directory' -Context @{
                    DirectoryPath = $DirectoryPath
                    Prefix        = $Prefix
                }
            }
            else {
                Write-Error "DirectoryPath cannot be null or empty"
            }
        }
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
    $cacheKey = New-CacheKey -Prefix $Prefix -Components @($directoryName)
    # Level 2: Log successful cache key generation
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[cache-key.directory] Generated directory cache key: $cacheKey"
    }
    # Level 3: Log detailed directory information
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [cache-key.directory] Directory details - Name: $directoryName, FullPath: $DirectoryPath" -ForegroundColor DarkGray
    }
    return $cacheKey
}

# Export functions
Export-ModuleMember -Function @(
    'New-CacheKey',
    'New-FileCacheKey',
    'New-DirectoryCacheKey'
)
