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

# Import FileContent for reading fragment files
$fileContentModulePath = Join-Path $PSScriptRoot 'FileContent.psm1'
if (Test-Path $fileContentModulePath) {
    Import-Module $fileContentModulePath -ErrorAction SilentlyContinue
}

# Import RegexUtilities for pattern matching
$regexModulePath = Join-Path $PSScriptRoot 'RegexUtilities.psm1'
if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -ErrorAction SilentlyContinue
}

# Import Logging for consistent output
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -ErrorAction SilentlyContinue
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

    if (-not (Test-Path $filePath)) {
        return @()
    }

    try {
        $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
            Read-FileContent -Path $filePath
        }
        else {
            Get-Content -Path $filePath -Raw -ErrorAction Stop
        }

        if ([string]::IsNullOrWhiteSpace($content)) {
            return @()
        }

        $dependencies = [System.Collections.Generic.List[string]]::new()

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
                    $dependencies.Add($depName)
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
                # Split by comma and clean up
                $depsLine -split ',' | ForEach-Object {
                    $depName = $_.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($depName)) {
                        $dependencies.Add($depName)
                    }
                }
            }
        }

        # Remove duplicates and return
        return $dependencies | Select-Object -Unique
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
        return @()
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
            # Found a cycle
            $cycle = $recursionStack | Where-Object { $_ -eq $FragmentName }
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
    $dependencies = @{}
    $dependents = @{}

    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName
        if ($disabledSet.Contains($baseName)) {
            continue
        }

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

    # Process queue
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($fragmentMap.ContainsKey($current)) {
            $sorted.Add($fragmentMap[$current])
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
        if ($sorted | Where-Object { $_.BaseName -eq $baseName }) {
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
function Get-FragmentTiers {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [switch]$ExcludeBootstrap
    )

    $tiers = @{
        Tier0 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        Tier1 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        Tier2 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        Tier3 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    }

    foreach ($file in $FragmentFiles) {
        $baseName = $file.BaseName

        if ($ExcludeBootstrap -and $baseName -eq '00-bootstrap') {
            continue
        }

        # Extract numeric prefix
        if ($baseName -match '^(\d+)-') {
            $prefix = [int]$matches[1]

            if ($prefix -ge 0 -and $prefix -le 9) {
                $tiers.Tier0.Add($file)
            }
            elseif ($prefix -ge 10 -and $prefix -le 29) {
                $tiers.Tier1.Add($file)
            }
            elseif ($prefix -ge 30 -and $prefix -le 69) {
                $tiers.Tier2.Add($file)
            }
            elseif ($prefix -ge 70 -and $prefix -le 99) {
                $tiers.Tier3.Add($file)
            }
        }
    }

    return $tiers
}

Export-ModuleMember -Function @(
    'Get-FragmentDependencies',
    'Test-FragmentDependencies',
    'Get-FragmentLoadOrder',
    'Get-FragmentTiers'
)

