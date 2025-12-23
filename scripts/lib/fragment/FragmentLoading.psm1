<#
scripts/lib/FragmentLoading.psm1

.SYNOPSIS
    Fragment loading, dependency resolution, and load order utilities.

.DESCRIPTION
    Provides functions for parsing fragment dependencies, calculating load order,
    and managing fragment loading. Supports topological sorting for dependency
    resolution and tier-based batch loading.

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

# Import FileContent for reading fragment files
$fileContentModulePath = Join-Path $PSScriptRoot 'FileContent.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    # Import-ModuleSafely has ErrorAction as a parameter, don't pass it explicitly to avoid duplicate
    Import-ModuleSafely -ModulePath $fileContentModulePath
}
else {
    # Fallback to manual validation
    if ($fileContentModulePath -and -not [string]::IsNullOrWhiteSpace($fileContentModulePath) -and (Test-Path -LiteralPath $fileContentModulePath)) {
        Import-Module $fileContentModulePath -ErrorAction SilentlyContinue
    }
}

# Import RegexUtilities for pattern matching
$regexModulePath = Join-Path $PSScriptRoot 'RegexUtilities.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    # Import-ModuleSafely has ErrorAction as a parameter, don't pass it explicitly to avoid duplicate
    Import-ModuleSafely -ModulePath $regexModulePath
}
else {
    # Fallback to manual validation
    if ($regexModulePath -and -not [string]::IsNullOrWhiteSpace($regexModulePath) -and (Test-Path -LiteralPath $regexModulePath)) {
        Import-Module $regexModulePath -ErrorAction SilentlyContinue
    }
}

# Import Logging for consistent output
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    # Import-ModuleSafely has ErrorAction as a parameter, don't pass it explicitly to avoid duplicate
    Import-ModuleSafely -ModulePath $loggingModulePath
}
else {
    # Fallback to manual validation
    if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
        Import-Module $loggingModulePath -ErrorAction SilentlyContinue
    }
}

# Cache for fragment dependencies to avoid re-parsing unchanged files
# Key: file path, Value: hashtable with Dependencies array and LastWriteTime
if (-not $script:FragmentDependencyCache) {
    $script:FragmentDependencyCache = @{}
}

<#
.SYNOPSIS
    Parses fragment dependencies in parallel using runspaces.

.DESCRIPTION
    Uses PowerShell runspaces (lighter weight than jobs) to parse fragment dependencies
    concurrently. This is much faster than sequential parsing and avoids the overhead
    of starting separate PowerShell processes (jobs).

.PARAMETER FilePaths
    Array of file path strings to parse for dependencies.

.OUTPUTS
    System.Array. Array of hashtables with FragmentName and Dependencies properties.
#>
function Invoke-ParallelDependencyParsing {
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory)]
        [string[]]$FilePaths
    )

    if ($FilePaths.Count -eq 0) {
        return @()
    }

    $runspacePool = $null
    # Optimized: Use List for better performance with Add() instead of +=
    # Note: These are used in main scope, not inside runspaces, so List<T> is safe
    $runspaces = [System.Collections.Generic.List[hashtable]]::new()
    $results = [System.Collections.Generic.List[hashtable]]::new()

    try {
        # Create runspace pool (min 1, max CPU count, capped at 10)
        $throttleLimit = [Math]::Min(10, [System.Environment]::ProcessorCount)
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $throttleLimit)
        $runspacePool.Open()

        # Scriptblock to parse dependencies (inline logic to avoid module imports)
        $scriptBlock = {
            param([string]$FilePath)

            $errorDetails = $null
            $baseName = $null
            $depString = ''

            try {
                # Validate input
                if ([string]::IsNullOrWhiteSpace($FilePath)) {
                    return @{ FragmentName = $null; Dependencies = ''; Error = 'Empty file path' }
                }

                # Get file info
                try {
                    $file = Get-Item -LiteralPath $FilePath -ErrorAction Stop
                    if ($null -eq $file) {
                        return @{ FragmentName = $null; Dependencies = ''; Error = 'File not found' }
                    }
                    $baseName = $file.BaseName
                }
                catch {
                    $errorDetails = "Get-Item failed: $($_.Exception.Message)"
                    return @{ FragmentName = $null; Dependencies = ''; Error = $errorDetails }
                }

                # Read file content
                try {
                    $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
                    if ([string]::IsNullOrWhiteSpace($content)) {
                        return @{ FragmentName = $baseName; Dependencies = ''; Error = $null }
                    }
                }
                catch {
                    $errorDetails = "Get-Content failed: $($_.Exception.Message)"
                    return @{ FragmentName = $baseName; Dependencies = ''; Error = $errorDetails }
                }

                # Pattern 1: #Requires -Fragment 'fragment-name'
                try {
                    $requiresPattern = [regex]::new(
                        '#Requires\s+-Fragment\s+[''""]([^''""]+)[''""]',
                        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                        [System.Text.RegularExpressions.RegexOptions]::Compiled
                    )
                    $matches = $requiresPattern.Matches($content)
                    foreach ($match in $matches) {
                        try {
                            if ($match.Groups.Count -gt 1) {
                                $depName = $match.Groups[1].Value.Trim()
                                if (-not [string]::IsNullOrWhiteSpace($depName)) {
                                    # Use string concatenation (avoid array operations)
                                    if ($depString) {
                                        $depString = "$depString,$depName"
                                    }
                                    else {
                                        $depString = $depName
                                    }
                                }
                            }
                        }
                        catch {
                            $exType = $_.Exception.GetType().FullName
                            $errorDetails = "Error processing requires match: $($_.Exception.Message) | Type: $exType | Stack: $($_.ScriptStackTrace)"
                            # Continue processing other matches
                        }
                    }
                }
                catch {
                    $exType = $_.Exception.GetType().FullName
                    $errorDetails = "Error creating/using requires pattern: $($_.Exception.Message) | Type: $exType | Stack: $($_.ScriptStackTrace)"
                }

                # Pattern 2: # Dependencies: fragment-name1, fragment-name2
                try {
                    $depsPattern = [regex]::new(
                        '#\s*Dependencies:\s*([^\r\n]+)',
                        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                        [System.Text.RegularExpressions.RegexOptions]::Compiled
                    )
                    $matches = $depsPattern.Matches($content)
                    foreach ($match in $matches) {
                        try {
                            if ($match.Groups.Count -gt 1) {
                                $depsLine = $match.Groups[1].Value.Trim()
                                if (-not [string]::IsNullOrWhiteSpace($depsLine)) {
                                    # Use string concatenation (avoid array operations)
                                    if ($depString) {
                                        $depString = "$depString,$depsLine"
                                    }
                                    else {
                                        $depString = $depsLine
                                    }
                                }
                            }
                        }
                        catch {
                            $exType = $_.Exception.GetType().FullName
                            $errorDetails = "Error processing dependencies match: $($_.Exception.Message) | Type: $exType | Stack: $($_.ScriptStackTrace)"
                            # Continue processing other matches
                        }
                    }
                }
                catch {
                    $exType = $_.Exception.GetType().FullName
                    $errorDetails = "Error creating/using dependencies pattern: $($_.Exception.Message) | Type: $exType | Stack: $($_.ScriptStackTrace)"
                }
            }
            catch {
                $exType = $_.Exception.GetType().FullName
                $errorDetails = "Unexpected error in scriptblock: $($_.Exception.Message) | Type: $exType | Stack: $($_.ScriptStackTrace)"
            }

            # Return result with error details for debugging
            return @{
                FragmentName = $baseName
                Dependencies = $depString  # Return as string, will be processed in main scope
                Error        = $errorDetails
            }
        }

        # Start all parsing tasks in parallel
        foreach ($filePath in $FilePaths) {
            try {
                $powershell = [PowerShell]::Create()
                if (-not $powershell) {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "    [Invoke-ParallelDependencyParsing] Failed to create PowerShell instance for: ${filePath}" -ForegroundColor Red
                    }
                    continue
                }

                $powershell.RunspacePool = $runspacePool
                
                try {
                    $null = $powershell.AddScript($scriptBlock)
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        $typeName = $_.Exception.GetType().FullName
                        Write-Host "    [Invoke-ParallelDependencyParsing] Error adding script for ${filePath}: $($_.Exception.Message) | Type: $typeName" -ForegroundColor Red
                    }
                    $powershell.Dispose()
                    continue
                }

                try {
                    $null = $powershell.AddArgument($filePath)
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        $typeName = $_.Exception.GetType().FullName
                        Write-Host "    [Invoke-ParallelDependencyParsing] Error adding argument for ${filePath}: $($_.Exception.Message) | Type: $typeName" -ForegroundColor Red
                    }
                    $powershell.Dispose()
                    continue
                }

                try {
                    $handle = $powershell.BeginInvoke()
                    if (-not $handle) {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Host "    [Invoke-ParallelDependencyParsing] BeginInvoke returned null for: ${filePath}" -ForegroundColor Red
                        }
                        $powershell.Dispose()
                        continue
                    }
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        $typeName = $_.Exception.GetType().FullName
                        Write-Host "    [Invoke-ParallelDependencyParsing] Error in BeginInvoke for ${filePath}`: $($_.Exception.Message) | Type: $typeName | Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
                    }
                    $powershell.Dispose()
                    continue
                }

                # Optimized: Use List.Add instead of +=
                try {
                    $runspaces.Add(@{
                            PowerShell = $powershell
                            Handle     = $handle
                            FilePath   = $filePath
                        })
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        $typeName = $_.Exception.GetType().FullName
                        Write-Host "    [Invoke-ParallelDependencyParsing] Error adding to runspaces list: $($_.Exception.Message) | Type: $typeName" -ForegroundColor Red
                    }
                    $powershell.Dispose()
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    $typeName = $_.Exception.GetType().FullName
                    Write-Host "    [Invoke-ParallelDependencyParsing] Unexpected error setting up runspace for ${filePath}`: $($_.Exception.Message) | Type: $typeName | Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
                }
            }
        }

        # Wait for all to complete using polling (STA-compatible)
        $pollIntervalMs = 50  # Check every 50ms
        $timeoutMs = 30000    # 30 second timeout
        $elapsedMs = 0
        $allCompleted = $false

        while ($elapsedMs -lt $timeoutMs) {
            $completedCount = 0
            foreach ($rs in $runspaces) {
                if ($rs.Handle.IsCompleted) {
                    $completedCount++
                }
            }

            if ($completedCount -eq $runspaces.Count) {
                $allCompleted = $true
                break
            }

            Start-Sleep -Milliseconds $pollIntervalMs
            $elapsedMs += $pollIntervalMs
        }

        if (-not $allCompleted) {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "    [Invoke-ParallelDependencyParsing] Warning: Not all dependency parsing tasks completed within timeout" -ForegroundColor Yellow
            }
        }

        # Collect results
        foreach ($rs in $runspaces) {
            try {
                if ($rs.Handle.IsCompleted) {
                    try {
                        $result = $rs.PowerShell.EndInvoke($rs.Handle)
                        
                        # Check for errors in the result
                        if ($result -and $result.Error) {
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Host "    [Invoke-ParallelDependencyParsing] Scriptblock error for $($rs.FilePath): $($result.Error)" -ForegroundColor Yellow
                            }
                        }
                        
                        # Check for PowerShell errors
                        if ($rs.PowerShell.HadErrors) {
                            $errors = $rs.PowerShell.Streams.Error
                            foreach ($error in $errors) {
                                if ($env:PS_PROFILE_DEBUG) {
                                    $errorType = $error.Exception.GetType().FullName
                                    Write-Host "    [Invoke-ParallelDependencyParsing] PowerShell error for $($rs.FilePath): $($error.Exception.Message) | Type: $errorType | Category: $($error.CategoryInfo.Category)" -ForegroundColor Red
                                    if ($error.ScriptStackTrace) {
                                        Write-Host "      Stack: $($error.ScriptStackTrace)" -ForegroundColor Red
                                    }
                                }
                            }
                        }
                        
                        if ($result -and -not [string]::IsNullOrWhiteSpace($result.FragmentName)) {
                            # Convert result to plain hashtable to avoid type issues after runspace deserialization
                            # Runspaces may return PSCustomObject or other types instead of hashtable
                            try {
                                $resultHashtable = @{
                                    FragmentName = $result.FragmentName
                                    Dependencies = $result.Dependencies
                                }
                                # Add Error property if present (for debugging)
                                if ($result.Error) {
                                    $resultHashtable['Error'] = $result.Error
                                }
                                # Optimized: Use List.Add instead of +=
                                $results.Add($resultHashtable)
                            }
                            catch {
                                if ($env:PS_PROFILE_DEBUG) {
                                    $typeName = $_.Exception.GetType().FullName
                                    $resultType = if ($result) { $result.GetType().FullName } else { 'null' }
                                    Write-Host "    [Invoke-ParallelDependencyParsing] Error adding result to list: $($_.Exception.Message) | Type: $typeName | Result type: $resultType" -ForegroundColor Red
                                }
                            }
                        }
                        elseif ($result) {
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Host "    [Invoke-ParallelDependencyParsing] Invalid result for $($rs.FilePath): FragmentName is null or empty" -ForegroundColor Yellow
                            }
                            $results.Add(@{ FragmentName = $null; Dependencies = ''; Error = 'Invalid result' })
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            $typeName = $_.Exception.GetType().FullName
                            Write-Host "    [Invoke-ParallelDependencyParsing] Error in EndInvoke for $($rs.FilePath): $($_.Exception.Message) | Type: $typeName | Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
                        }
                        $results.Add(@{ FragmentName = $null; Dependencies = ''; Error = $_.Exception.Message })
                    }
                }
                else {
                    # Timeout - return empty result for this file
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "    [Invoke-ParallelDependencyParsing] Timeout parsing: $($rs.FilePath)" -ForegroundColor Yellow
                    }
                    try {
                        $results.Add(@{ FragmentName = $null; Dependencies = ''; Error = 'Timeout' })
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Host "    [Invoke-ParallelDependencyParsing] Error adding timeout result: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    $typeName = $_.Exception.GetType().FullName
                    Write-Host "    [Invoke-ParallelDependencyParsing] Error processing runspace for $($rs.FilePath): $($_.Exception.Message) | Type: $typeName | Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
                }
                try {
                    $results.Add(@{ FragmentName = $null; Dependencies = ''; Error = $_.Exception.Message })
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "    [Invoke-ParallelDependencyParsing] Error adding error result: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            finally {
                try {
                    if ($rs.PowerShell) {
                        $rs.PowerShell.Dispose()
                    }
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "    [Invoke-ParallelDependencyParsing] Error disposing PowerShell: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "    [Invoke-ParallelDependencyParsing] Error in parallel parsing: $($_.Exception.Message)" -ForegroundColor Red
        }
        # Fallback: return empty results
        return @()
    }
    finally {
        # Cleanup runspace pool
        if ($runspacePool) {
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
    }

    # Process dependencies: split string, deduplicate, and convert to array
    # (hashtable operations don't work in runspaces, so we return string and process here)
    foreach ($result in $results) {
        try {
            if ($result.Dependencies) {
                # Dependencies is a comma-separated string from the runspace
                $depString = $result.Dependencies
                if (-not [string]::IsNullOrWhiteSpace($depString)) {
                    try {
                        # Split, trim, filter empty, and deduplicate using HashSet
                        $depSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                        $depArray = $depString -split ','
                        foreach ($dep in $depArray) {
                            try {
                                $trimmed = $dep.Trim()
                                if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                                    [void]$depSet.Add($trimmed)
                                }
                            }
                            catch {
                                if ($env:PS_PROFILE_DEBUG) {
                                    Write-Host "    [Invoke-ParallelDependencyParsing] Error processing dependency '$dep': $($_.Exception.Message)" -ForegroundColor Yellow
                                }
                            }
                        }
                        $result.Dependencies = [string[]]$depSet
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            $typeName = $_.Exception.GetType().FullName
                            Write-Host "    [Invoke-ParallelDependencyParsing] Error processing dependencies for $($result.FragmentName): $($_.Exception.Message) | Type: $typeName" -ForegroundColor Yellow
                        }
                        $result.Dependencies = @()
                    }
                }
                else {
                    $result.Dependencies = @()
                }
            }
            else {
                $result.Dependencies = @()
            }
            
            # Remove Error property if present (was only for debugging)
            if ($result.PSObject.Properties['Error']) {
                $result.PSObject.Properties.Remove('Error')
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                $typeName = $_.Exception.GetType().FullName
                Write-Host "    [Invoke-ParallelDependencyParsing] Error processing result: $($_.Exception.Message) | Type: $typeName" -ForegroundColor Red
            }
            if (-not $result.Dependencies) {
                $result.Dependencies = @()
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Parses dependencies from a fragment file header.

.DESCRIPTION
    Reads a fragment file and extracts declared dependencies from header comments.
    Supports two formats:
    1. #Requires -Fragment 'fragment-name'
    2. # Dependencies: fragment-name1, fragment-name2

.PARAMETER FragmentFile
    The fragment file to parse. Can be a FileInfo object or path string.

.OUTPUTS
    System.String[]. Array of fragment names that this fragment depends on.

.EXAMPLE
    $deps = Get-FragmentDependencies -FragmentFile $fragmentFile
    Write-Host "Dependencies: $($deps -join ', ')"
#>
function Get-FragmentDependencies {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [object]$FragmentFile
    )

    $filePath = if ($FragmentFile -is [System.IO.FileInfo]) {
        $FragmentFile.FullName
    }
    else {
        $FragmentFile
    }

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $filePath -PathType File)) {
            return @()
        }
    }
    else {
        # Fallback to manual validation
        if (-not ($filePath -and -not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path -LiteralPath $filePath))) {
            return @()
        }
    }

    # Check cache first (use file modification time to invalidate cache)
    $fileInfo = Get-Item -Path $filePath -ErrorAction SilentlyContinue
    if ($fileInfo) {
        $lastWriteTime = $fileInfo.LastWriteTime
        if ($script:FragmentDependencyCache.ContainsKey($filePath)) {
            $cached = $script:FragmentDependencyCache[$filePath]
            # Use cached result if file hasn't been modified
            if ($cached.LastWriteTime -eq $lastWriteTime) {
                return $cached.Dependencies
            }
        }
    }

    try {
        $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
            Read-FileContent -Path $filePath
        }
        else {
            Get-Content -Path $filePath -Raw -ErrorAction Stop
        }

        if ([string]::IsNullOrWhiteSpace($content)) {
            $result = @()
            # Cache empty result
            if ($fileInfo) {
                $script:FragmentDependencyCache[$filePath] = @{
                    Dependencies  = $result
                    LastWriteTime = $lastWriteTime
                }
            }
            return $result
        }

        # Optimized: Use HashSet to automatically prevent duplicates (O(1) lookup)
        $dependencies = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        # Pattern 1: #Requires -Fragment 'fragment-name'
        $requiresPattern = [regex]::new(
            '#Requires\s+-Fragment\s+[''""]([^''""]+)[''""]',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Compiled
        )

        foreach ($match in $requiresPattern.Matches($content)) {
            if ($match.Groups.Count -gt 1) {
                $depName = $match.Groups[1].Value.Trim()
                if (-not [string]::IsNullOrWhiteSpace($depName)) {
                    [void]$dependencies.Add($depName)
                }
            }
        }

        # Pattern 2: # Dependencies: fragment-name1, fragment-name2
        $depsPattern = [regex]::new(
            '#\s*Dependencies:\s*([^\r\n]+)',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Compiled
        )

        foreach ($match in $depsPattern.Matches($content)) {
            if ($match.Groups.Count -gt 1) {
                $depsLine = $match.Groups[1].Value.Trim()
                # Optimized: Use foreach loop instead of ForEach-Object
                $depParts = $depsLine -split ','
                foreach ($depPart in $depParts) {
                    $depName = $depPart.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($depName)) {
                        [void]$dependencies.Add($depName)
                    }
                }
            }
        }

        # Convert HashSet to array (no need for Select-Object -Unique since HashSet prevents duplicates)
        $result = [string[]]$dependencies
        
        # Cache the result
        if ($fileInfo) {
            $script:FragmentDependencyCache[$filePath] = @{
                Dependencies  = $result
                LastWriteTime = $lastWriteTime
            }
        }
        
        return $result
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                Write-ScriptMessage -Message "Failed to parse dependencies from '$filePath': $($_.Exception.Message)" -IsWarning
            }
            else {
                Write-Warning "Failed to parse dependencies from '$filePath': $($_.Exception.Message)"
            }
        }
        $result = @()
        # Cache empty result on error to avoid repeated failures
        if ($fileInfo) {
            $script:FragmentDependencyCache[$filePath] = @{
                Dependencies  = $result
                LastWriteTime = $lastWriteTime
            }
        }
        return $result
    }
}

<#
.SYNOPSIS
    Validates that all fragment dependencies are satisfied.

.DESCRIPTION
    Checks that all dependencies declared by fragments exist in the available
    fragment set and are not disabled.

.PARAMETER FragmentFiles
    Array of fragment FileInfo objects to validate.

.PARAMETER DisabledFragments
    Optional array of fragment names that are disabled.

.OUTPUTS
    System.Collections.Hashtable. Hashtable with:
    - Valid: $true if all dependencies are satisfied
    - MissingDependencies: Array of missing dependency names
    - CircularDependencies: Array of circular dependency chains (if any)

.EXAMPLE
    $result = Test-FragmentDependencies -FragmentFiles $fragments -DisabledFragments $disabled
    if (-not $result.Valid) {
        Write-Warning "Missing dependencies: $($result.MissingDependencies -join ', ')"
    }
#>
function Test-FragmentDependencies {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [string[]]$DisabledFragments = @()
    )

    # Build fragment name map
    $fragmentMap = @{}
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        $fragmentMap[$baseName] = $file
    }

    # Build disabled set for fast lookup
    $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($disabled in $DisabledFragments) {
        if (-not [string]::IsNullOrWhiteSpace($disabled)) {
            [void]$disabledSet.Add($disabled.Trim())
        }
    }

    $missingDependencies = [System.Collections.Generic.List[string]]::new()
    $allDependencies = @{}

    # Collect all dependencies
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if ($disabledSet.Contains($baseName)) {
            continue
        }

        $deps = Get-FragmentDependencies -FragmentFile $file
        $allDependencies[$baseName] = $deps

        # Check each dependency
        foreach ($dep in $deps) {
            if (-not $fragmentMap.ContainsKey($dep)) {
                $missingDependencies.Add("$baseName -> $dep")
            }
            elseif ($disabledSet.Contains($dep)) {
                $missingDependencies.Add("$baseName -> $dep (disabled)")
            }
        }
    }

    # Detect circular dependencies using DFS
    $circularDependencies = [System.Collections.Generic.List[string]]::new()
    $visited = [System.Collections.Generic.HashSet[string]]::new()
    $recursionStack = [System.Collections.Generic.HashSet[string]]::new()

    function Test-CircularDependency {
        param([string]$FragmentName)

        if ($recursionStack.Contains($FragmentName)) {
            # Found a cycle - recursionStack already contains the fragment name
            $circularDependencies.Add("Circular dependency detected: $FragmentName")
            return $true
        }

        if ($visited.Contains($FragmentName)) {
            return $false
        }

        [void]$visited.Add($FragmentName)
        [void]$recursionStack.Add($FragmentName)

        if ($allDependencies.ContainsKey($FragmentName)) {
            foreach ($dep in $allDependencies[$FragmentName]) {
                if (Test-CircularDependency -FragmentName $dep) {
                    return $true
                }
            }
        }

        [void]$recursionStack.Remove($FragmentName)
        return $false
    }

    foreach ($fragmentName in $allDependencies.Keys) {
        if (-not $visited.Contains($fragmentName)) {
            Test-CircularDependency -FragmentName $fragmentName | Out-Null
        }
    }

    return @{
        Valid                = ($missingDependencies.Count -eq 0 -and $circularDependencies.Count -eq 0)
        MissingDependencies  = $missingDependencies.ToArray()
        CircularDependencies = $circularDependencies.ToArray()
    }
}

<#
.SYNOPSIS
    Calculates the optimal load order for fragments using topological sort.

.DESCRIPTION
    Sorts fragments topologically based on their dependencies, ensuring that
    dependencies are loaded before fragments that depend on them.

.PARAMETER FragmentFiles
    Array of fragment FileInfo objects to sort.

.PARAMETER DisabledFragments
    Optional array of fragment names that are disabled (excluded from result).

.OUTPUTS
    System.IO.FileInfo[]. Sorted array of fragment files in load order.

.EXAMPLE
    $sortedFragments = Get-FragmentLoadOrder -FragmentFiles $fragments -DisabledFragments $disabled
    foreach ($fragment in $sortedFragments) {
        . $fragment.FullName
    }
#>
function Get-FragmentLoadOrder {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [string[]]$DisabledFragments = @()
    )

    # Build fragment name map
    $fragmentMap = @{}
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        $fragmentMap[$baseName] = $file
    }

    # Build disabled set
    $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($disabled in $DisabledFragments) {
        if (-not [string]::IsNullOrWhiteSpace($disabled)) {
            [void]$disabledSet.Add($disabled.Trim())
        }
    }

    # Build dependency graph
    # Optimize: Parse dependencies in parallel if Parallel module is available
    $dependencies = @{}
    $dependents = @{}
    
    $fragmentsToProcess = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if (-not $disabledSet.Contains($baseName)) {
            $fragmentsToProcess.Add($file)
        }
    }

    # Try to use parallel parsing if available (only for larger fragment sets)
    # Check environment variable to enable/disable parallel dependency parsing
    # Supports: '1', 'true' (case-insensitive) -> $true
    #           '0', 'false' (case-insensitive), empty/null -> $false
    $parallelDependenciesEnabled = $true
    if ($env:PS_PROFILE_PARALLEL_DEPENDENCIES) {
        $normalized = $env:PS_PROFILE_PARALLEL_DEPENDENCIES.Trim().ToLowerInvariant()
        $parallelDependenciesEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
    }
    
    $useParallelParsing = $false
    if ($parallelDependenciesEnabled -and $fragmentsToProcess.Count -gt 5) {
        # Runspaces are always available (built into PowerShell), no module loading needed
        $useParallelParsing = $true
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "  Parsing $($fragmentsToProcess.Count) fragment dependencies in parallel..." -ForegroundColor DarkGray
        }
        $parseStart = Get-Date
        # Optimized: Convert FileInfo objects to file paths using foreach loop
        # Strings serialize better than FileInfo objects for runspaces
        $filePaths = [System.Collections.Generic.List[string]]::new()
        foreach ($fragment in $fragmentsToProcess) {
            $filePaths.Add($fragment.FullName)
        }
        
        # Use runspaces for parallel dependency parsing (much faster than jobs)
        $dependencyResults = Invoke-ParallelDependencyParsing -FilePaths $filePaths
        
        $parseTime = (Get-Date) - $parseStart
        if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT) {
            Write-Host "  Dependency parsing completed in $([Math]::Round($parseTime.TotalMilliseconds))ms" -ForegroundColor DarkGray
        }
        $graphStart = Get-Date
        foreach ($result in $dependencyResults) {
            # Skip null or invalid results
            if ($null -eq $result -or $null -eq $result.FragmentName -or [string]::IsNullOrWhiteSpace($result.FragmentName)) {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "  [Get-FragmentLoadOrder] Skipping invalid result: $($result | ConvertTo-Json -Compress)" -ForegroundColor DarkYellow
                }
                continue
            }
            $baseName = $result.FragmentName
            if (-not $dependencies.ContainsKey($baseName)) {
                $dependencies[$baseName] = [System.Collections.Generic.List[string]]::new()
            }
            if (-not $dependents.ContainsKey($baseName)) {
                $dependents[$baseName] = [System.Collections.Generic.List[string]]::new()
            }
            
            # Handle null or missing Dependencies property
            if ($null -ne $result.Dependencies) {
                foreach ($dep in $result.Dependencies) {
                    if (-not [string]::IsNullOrWhiteSpace($dep) -and $fragmentMap.ContainsKey($dep) -and -not $disabledSet.Contains($dep)) {
                        $dependencies[$baseName].Add($dep)
                        if (-not $dependents.ContainsKey($dep)) {
                            $dependents[$dep] = [System.Collections.Generic.List[string]]::new()
                        }
                        $dependents[$dep].Add($baseName)
                    }
                }
            }
        }
        $graphTime = (Get-Date) - $graphStart
        if ($env:PS_PROFILE_DEBUG -and $graphTime.TotalMilliseconds -gt 50) {
            Write-Host "  [Get-FragmentLoadOrder] Dependency graph built in $([Math]::Round($graphTime.TotalMilliseconds))ms" -ForegroundColor DarkGray
        }
    }
    else {
        # Sequential parsing (fallback)
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "  [Get-FragmentLoadOrder] Parsing $($fragmentsToProcess.Count) fragment dependencies sequentially..." -ForegroundColor DarkGray
        }
        $parseStart = Get-Date
        foreach ($file in $fragmentsToProcess) {
            $baseName = $file.BaseName

            if (-not $dependencies.ContainsKey($baseName)) {
                $dependencies[$baseName] = [System.Collections.Generic.List[string]]::new()
            }
            if (-not $dependents.ContainsKey($baseName)) {
                $dependents[$baseName] = [System.Collections.Generic.List[string]]::new()
            }

            $deps = Get-FragmentDependencies -FragmentFile $file
            foreach ($dep in $deps) {
                if ($fragmentMap.ContainsKey($dep) -and -not $disabledSet.Contains($dep)) {
                    $dependencies[$baseName].Add($dep)
                    if (-not $dependents.ContainsKey($dep)) {
                        $dependents[$dep] = [System.Collections.Generic.List[string]]::new()
                    }
                    $dependents[$dep].Add($baseName)
                }
            }
        }
        $parseTime = (Get-Date) - $parseStart
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "  [Get-FragmentLoadOrder] Sequential parsing completed in $([Math]::Round($parseTime.TotalMilliseconds))ms" -ForegroundColor DarkGray
        }
    }

    # Topological sort using Kahn's algorithm
    $sorted = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $inDegree = @{}

    # Initialize in-degree count
    foreach ($fragmentName in $dependencies.Keys) {
        $inDegree[$fragmentName] = $dependencies[$fragmentName].Count
    }

    # Add fragments with no dependencies to queue
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if ($disabledSet.Contains($baseName)) {
            continue
        }
        if (-not $inDegree.ContainsKey($baseName) -or $inDegree[$baseName] -eq 0) {
            $queue.Enqueue($baseName)
        }
    }

    # Optimized: Use HashSet for O(1) lookup instead of Where-Object (O(n))
    $sortedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # Process queue
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($fragmentMap.ContainsKey($current)) {
            $sorted.Add($fragmentMap[$current])
            [void]$sortedNames.Add($current)
        }

        if ($dependents.ContainsKey($current)) {
            foreach ($dependent in $dependents[$current]) {
                $inDegree[$dependent]--
                if ($inDegree[$dependent] -eq 0) {
                    $queue.Enqueue($dependent)
                }
            }
        }
    }

    # Add any remaining fragments (shouldn't happen if no cycles, but handle gracefully)

    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if ($disabledSet.Contains($baseName)) {
            continue
        }
        if ($sortedNames.Contains($baseName)) {
            continue
        }
        $sorted.Add($file)
    }

    return $sorted.ToArray()
}

<#
.SYNOPSIS
    Groups fragments into tiers for batch loading.

.DESCRIPTION
    Groups fragments by their numeric prefix into tiers for optimized batch loading.
    Tier 0: 00-09, Tier 1: 10-29, Tier 2: 30-69, Tier 3: 70-99.

.PARAMETER FragmentFiles
    Array of fragment FileInfo objects to group.

.PARAMETER ExcludeBootstrap
    If specified, excludes 00-bootstrap from tier grouping.

.OUTPUTS
    System.Collections.Hashtable. Hashtable with keys Tier0, Tier1, Tier2, Tier3,
    each containing an array of FileInfo objects.

.EXAMPLE
    $tiers = Get-FragmentTiers -FragmentFiles $fragments
    foreach ($fragment in $tiers.Tier0) {
        . $fragment.FullName
    }
#>
<#
.SYNOPSIS
    Gets the tier declaration from a fragment file header.

.DESCRIPTION
    Parses a fragment file to extract the tier declaration from header comments.
    Supports explicit tier declarations: # Tier: core|essential|standard|optional
    Falls back to numeric prefix-based tier detection for backward compatibility.

.PARAMETER FragmentFile
    The fragment file to parse. Can be a FileInfo object or path string.

.OUTPUTS
    System.String. The tier name: 'core', 'essential', 'standard', or 'optional'.

.EXAMPLE
    $tier = Get-FragmentTier -FragmentFile $fragmentFile
    Write-Host "Fragment tier: $tier"
#>
function Get-FragmentTier {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [object]$FragmentFile
    )

    $filePath = if ($FragmentFile -is [System.IO.FileInfo]) {
        $FragmentFile.FullName
    }
    else {
        $FragmentFile
    }

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $filePath -PathType File)) {
            return 'optional'
        }
    }
    else {
        # Fallback to manual validation
        if (-not ($filePath -and -not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path -LiteralPath $filePath))) {
            return 'optional'
        }
    }

    try {
        $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
            Read-FileContent -Path $filePath
        }
        else {
            Get-Content -Path $filePath -Raw -ErrorAction Stop
        }

        if ([string]::IsNullOrWhiteSpace($content)) {
            return 'optional'
        }

        # Pattern: # Tier: tier-name
        # Match case-insensitive, allow whitespace variations
        $tierPattern = [regex]::new(
            '(?i)^\s*#\s*Tier\s*:\s*(core|essential|standard|optional)\s*$',
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )

        $match = $tierPattern.Match($content)
        if ($match.Success) {
            $tierName = $match.Groups[1].Value.ToLowerInvariant()
            # Validate tier name
            if ($tierName -in @('core', 'essential', 'standard', 'optional')) {
                return $tierName
            }
        }

        # Fallback: Check for numeric prefix (backward compatibility)
        $fileInfo = if ($FragmentFile -is [System.IO.FileInfo]) {
            $FragmentFile
        }
        else {
            Get-Item -Path $filePath -ErrorAction SilentlyContinue
        }

        if ($fileInfo) {
            $baseName = $fileInfo.BaseName

            # Special case: bootstrap is always core
            if ($baseName -eq '00-bootstrap' -or $baseName -eq 'bootstrap') {
                return 'core'
            }

            # Extract numeric prefix for backward compatibility
            if ($baseName -match '^(\d+)-') {
                $prefix = [int]$matches[1]

                if ($prefix -ge 0 -and $prefix -le 9) {
                    return 'core'
                }
                elseif ($prefix -ge 10 -and $prefix -le 29) {
                    return 'essential'
                }
                elseif ($prefix -ge 30 -and $prefix -le 69) {
                    return 'standard'
                }
                elseif ($prefix -ge 70 -and $prefix -le 99) {
                    return 'optional'
                }
            }
        }

        # Default to optional if no tier specified
        return 'optional'
    }
    catch {
        # On error, default to optional
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to parse tier from fragment '$filePath': $($_.Exception.Message)"
        }
        return 'optional'
    }
}

<#
.SYNOPSIS
    Groups fragments by tier for optimized batch loading.

.DESCRIPTION
    Groups fragments into tiers (core, essential, standard, optional) based on
    explicit tier declarations or numeric prefixes (for backward compatibility).
    Supports both named fragments (with explicit tier declarations) and numbered
    fragments (for migration period).

.PARAMETER FragmentFiles
    Array of fragment files to group.

.PARAMETER ExcludeBootstrap
    If specified, excludes bootstrap fragment from tier grouping.

.OUTPUTS
    Hashtable with keys: Tier0 (core), Tier1 (essential), Tier2 (standard), Tier3 (optional).

.EXAMPLE
    $tiers = Get-FragmentTiers -FragmentFiles $fragments
    foreach ($fragment in $tiers.Tier0) {
        . $fragment.FullName
    }
#>
function Get-FragmentTiers {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [switch]$ExcludeBootstrap
    )

    $tiers = @{
        Tier0 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()  # core
        Tier1 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()  # essential
        Tier2 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()  # standard
        Tier3 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()  # optional
    }

    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName

        if ($ExcludeBootstrap -and ($baseName -eq '00-bootstrap' -or $baseName -eq 'bootstrap')) {
            continue
        }

        # Get tier using new function (supports both explicit declarations and numeric prefixes)
        $tier = Get-FragmentTier -FragmentFile $file

        # Map tier names to tier numbers
        switch ($tier) {
            'core' {
                $tiers.Tier0.Add($file)
            }
            'essential' {
                $tiers.Tier1.Add($file)
            }
            'standard' {
                $tiers.Tier2.Add($file)
            }
            'optional' {
                $tiers.Tier3.Add($file)
            }
            default {
                # Unknown tier, default to optional
                $tiers.Tier3.Add($file)
            }
        }
    }

    return $tiers
}

<#
.SYNOPSIS
    Groups fragments by dependency level for parallel loading.

.DESCRIPTION
    Groups fragments into levels based on their dependency depth. Fragments at the same
    level have no dependencies on each other and can theoretically be loaded in parallel.
    Level 0 contains fragments with no dependencies, Level 1 contains fragments that
    depend only on Level 0 fragments, etc.

.PARAMETER FragmentFiles
    Array of fragment FileInfo objects to group.

.PARAMETER DisabledFragments
    Optional array of fragment names that are disabled (excluded from result).

.OUTPUTS
    System.Collections.Hashtable. Hashtable with keys Level0, Level1, Level2, etc.,
    each containing an array of FileInfo objects that can be loaded in parallel.

.EXAMPLE
    $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
    foreach ($level in $levels.Keys | Sort-Object) {
        # Load all fragments at this level (could be parallelized)
        foreach ($fragment in $levels[$level]) {
            . $fragment.FullName
        }
    }
#>
function Get-FragmentDependencyLevels {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [string[]]$DisabledFragments = @()
    )

    # Build fragment name map
    $fragmentMap = @{}
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        $fragmentMap[$baseName] = $file
    }

    # Build disabled set
    $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($disabled in $DisabledFragments) {
        if (-not [string]::IsNullOrWhiteSpace($disabled)) {
            [void]$disabledSet.Add($disabled.Trim())
        }
    }

    # Build dependency graph
    $dependencies = @{}
    $dependents = @{}

    # Filter out disabled fragments for processing
    $fragmentsToProcess = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if (-not $disabledSet.Contains($baseName)) {
            $fragmentsToProcess.Add($file)
        }
    }

    # Check if parallel dependency parsing is enabled
    $parallelDependenciesEnabled = $false
    if ($env:PS_PROFILE_PARALLEL_DEPENDENCIES) {
        $normalized = $env:PS_PROFILE_PARALLEL_DEPENDENCIES.Trim().ToLowerInvariant()
        $parallelDependenciesEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
    }
    
    $useParallelParsing = $false
    if ($parallelDependenciesEnabled -and $fragmentsToProcess.Count -gt 5) {
        # Runspaces are always available (built into PowerShell), no module loading needed
        $useParallelParsing = $true
    }

    if ($useParallelParsing) {
        # Parse dependencies in parallel using runspaces (lighter weight than jobs)
        if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT) {
            Write-Host "  Parsing $($fragmentsToProcess.Count) fragment dependencies in parallel..." -ForegroundColor DarkGray
        }
        $parseStart = Get-Date
        # Optimized: Convert FileInfo objects to file paths using foreach loop
        # Strings serialize better than FileInfo objects for runspaces
        $filePaths = [System.Collections.Generic.List[string]]::new()
        foreach ($fragment in $fragmentsToProcess) {
            $filePaths.Add($fragment.FullName)
        }
        
        # Use runspaces for parallel dependency parsing (much faster than jobs)
        $dependencyResults = Invoke-ParallelDependencyParsing -FilePaths $filePaths
        
        $parseTime = (Get-Date) - $parseStart
        if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT) {
            Write-Host "  Dependency parsing completed in $([Math]::Round($parseTime.TotalMilliseconds))ms" -ForegroundColor DarkGray
        }
        $graphStart = Get-Date
        foreach ($result in $dependencyResults) {
            # Skip null or invalid results
            if ($null -eq $result -or $null -eq $result.FragmentName -or [string]::IsNullOrWhiteSpace($result.FragmentName)) {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "  [Get-FragmentDependencyLevels] Skipping invalid result: $($result | ConvertTo-Json -Compress)" -ForegroundColor DarkYellow
                }
                continue
            }
            $baseName = $result.FragmentName
            if (-not $dependencies.ContainsKey($baseName)) {
                $dependencies[$baseName] = [System.Collections.Generic.List[string]]::new()
            }
            if (-not $dependents.ContainsKey($baseName)) {
                $dependents[$baseName] = [System.Collections.Generic.List[string]]::new()
            }
            
            # Handle null or missing Dependencies property
            if ($null -ne $result.Dependencies) {
                foreach ($dep in $result.Dependencies) {
                    if (-not [string]::IsNullOrWhiteSpace($dep) -and $fragmentMap.ContainsKey($dep) -and -not $disabledSet.Contains($dep)) {
                        $dependencies[$baseName].Add($dep)
                        if (-not $dependents.ContainsKey($dep)) {
                            $dependents[$dep] = [System.Collections.Generic.List[string]]::new()
                        }
                        $dependents[$dep].Add($baseName)
                    }
                }
            }
        }
        $graphTime = (Get-Date) - $graphStart
        if ($env:PS_PROFILE_DEBUG -and $graphTime.TotalMilliseconds -gt 50) {
            Write-Host "  [Get-FragmentDependencyLevels] Dependency graph built in $([Math]::Round($graphTime.TotalMilliseconds))ms" -ForegroundColor DarkGray
        }
    }
    else {
        # Sequential parsing (fallback)
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "  [Get-FragmentDependencyLevels] Parsing $($fragmentsToProcess.Count) fragment dependencies sequentially..." -ForegroundColor DarkGray
        }
        $parseStart = Get-Date
        foreach ($file in $fragmentsToProcess) {
            $baseName = $file.BaseName

            if (-not $dependencies.ContainsKey($baseName)) {
                $dependencies[$baseName] = [System.Collections.Generic.List[string]]::new()
            }
            if (-not $dependents.ContainsKey($baseName)) {
                $dependents[$baseName] = [System.Collections.Generic.List[string]]::new()
            }

            $deps = Get-FragmentDependencies -FragmentFile $file
            foreach ($dep in $deps) {
                if ($fragmentMap.ContainsKey($dep) -and -not $disabledSet.Contains($dep)) {
                    $dependencies[$baseName].Add($dep)
                    if (-not $dependents.ContainsKey($dep)) {
                        $dependents[$dep] = [System.Collections.Generic.List[string]]::new()
                    }
                    $dependents[$dep].Add($baseName)
                }
            }
        }
        $parseTime = (Get-Date) - $parseStart
        if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT) {
            Write-Host "  [Get-FragmentDependencyLevels] Sequential parsing completed in $([Math]::Round($parseTime.TotalMilliseconds))ms" -ForegroundColor DarkGray
        }
    }

    # Group by dependency level using BFS
    if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT) {
        Write-Host "  [Get-FragmentDependencyLevels] Grouping fragments by dependency level (BFS)..." -ForegroundColor DarkGray
    }
    $bfsStart = Get-Date
    $levels = @{}
    $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $inDegree = @{}

    # Initialize in-degree count
    foreach ($fragmentName in $dependencies.Keys) {
        $inDegree[$fragmentName] = $dependencies[$fragmentName].Count
    }

    # Add fragments with no dependencies to Level 0
    $currentLevel = 0
    $currentLevelFragments = [System.Collections.Generic.List[string]]::new()
    
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if ($disabledSet.Contains($baseName)) {
            continue
        }
        if (-not $inDegree.ContainsKey($baseName) -or $inDegree[$baseName] -eq 0) {
            $currentLevelFragments.Add($baseName)
            [void]$visited.Add($baseName)
        }
    }

    # Process levels
    while ($currentLevelFragments.Count -gt 0) {
        $levelKey = "Level$currentLevel"
        $levelFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        
        foreach ($fragmentName in $currentLevelFragments) {
            if ($fragmentMap.ContainsKey($fragmentName)) {
                $levelFiles.Add($fragmentMap[$fragmentName])
            }
        }
        
        $levels[$levelKey] = $levelFiles.ToArray()

        # Find next level: fragments that depend only on current level
        $nextLevelFragments = [System.Collections.Generic.List[string]]::new()
        foreach ($fragmentName in $dependencies.Keys) {
            if ($visited.Contains($fragmentName)) {
                continue
            }
            
            # Check if all dependencies are in visited set
            $allDepsVisited = $true
            foreach ($dep in $dependencies[$fragmentName]) {
                if (-not $visited.Contains($dep)) {
                    $allDepsVisited = $false
                    break
                }
            }
            
            if ($allDepsVisited) {
                $nextLevelFragments.Add($fragmentName)
                [void]$visited.Add($fragmentName)
            }
        }

        $currentLevel++
        $currentLevelFragments = $nextLevelFragments
    }

    # Add any remaining fragments (shouldn't happen if no cycles, but handle gracefully)
    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if ($disabledSet.Contains($baseName)) {
            continue
        }
        if (-not $visited.Contains($baseName)) {
            # Add to last level
            $lastLevelKey = "Level$currentLevel"
            if (-not $levels.ContainsKey($lastLevelKey)) {
                $levels[$lastLevelKey] = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
            }
            $levels[$lastLevelKey].Add($file)
        }
    }
    
    $bfsTime = (Get-Date) - $bfsStart
    if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT) {
        Write-Host "  [Get-FragmentDependencyLevels] BFS grouping completed in $([Math]::Round($bfsTime.TotalMilliseconds))ms ($($levels.Keys.Count) levels)" -ForegroundColor DarkGray
    }

    return $levels
}

Export-ModuleMember -Function @(
    'Get-FragmentDependencies',
    'Test-FragmentDependencies',
    'Get-FragmentLoadOrder',
    'Get-FragmentTier',
    'Get-FragmentTiers',
    'Get-FragmentDependencyLevels'
)

