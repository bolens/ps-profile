<#
.SYNOPSIS
    Fragment discovery and ordering logic for profile loading.

.DESCRIPTION
    Handles fragment discovery, bootstrap separation, load order determination,
    and preparation of fragments for loading.
#>

function Initialize-FragmentDiscovery {
    <#
    .SYNOPSIS
        Discovers and orders fragments for loading.

    .DESCRIPTION
        Separates bootstrap fragments, determines load order (manual override or
        dependency-aware), creates disabled fragment set, and prepares final fragment list.

    .PARAMETER AllFragments
        All discovered fragments.

    .PARAMETER LoadOrderOverride
        Manual load order override from configuration.

    .PARAMETER DisabledFragments
        List of disabled fragment names.

    .PARAMETER FragmentLoadingModule
        Path to fragment loading module for dependency-aware ordering.

    .PARAMETER FragmentLoadingModuleExists
        Whether the fragment loading module exists.

    .PARAMETER PerformanceConfig
        Performance configuration hashtable.

    .PARAMETER FragmentLibDir
        Directory containing fragment library modules.

    .OUTPUTS
        Hashtable with:
        - BootstrapFragment: Bootstrap fragments array
        - FragmentsToLoad: Final list of fragments to load
        - DisabledSet: HashSet of disabled fragment names
        - NonBootstrapFragments: Non-bootstrap fragments in order
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$AllFragments,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$LoadOrderOverride = @(),

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$DisabledFragments = @(),

        [Parameter(Mandatory)]
        [string]$FragmentLoadingModule,

        [Parameter(Mandatory)]
        [bool]$FragmentLoadingModuleExists,

        [Parameter(Mandatory = $false)]
        [bool]$EnableParallelLoading = $false,

        [Parameter(Mandatory)]
        [hashtable]$PerformanceConfig,

        [Parameter(Mandatory)]
        [string]$FragmentLibDir
    )

    # Optimized: Single-pass filtering instead of multiple Where-Object calls
    # Bootstrap fragment always loads first
    $bootstrapFragment = @()
    $otherFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($fragment in $AllFragments) {
        $baseName = $fragment.BaseName
        if ($baseName -eq 'bootstrap') {
            $bootstrapFragment += $fragment
        }
        else {
            $otherFragments.Add($fragment)
        }
    }

    # Determine fragment load order: use override if specified, otherwise dependency-aware ordering
    # Initialize $nonBootstrapFragments to ensure it's never null
    $nonBootstrapFragments = $null
    if ($LoadOrderOverride.Count -gt 0) {
        # Manual load order: load specified fragments first, then remaining fragments alphabetically
        # Optimized: Build lookup dictionary and use HashSet for O(1) lookups
        $fragmentLookup = @{}
        foreach ($fragment in $otherFragments) {
            $fragmentLookup[$fragment.BaseName] = $fragment
        }

        $orderedFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        $orderedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        foreach ($fragmentName in $LoadOrderOverride) {
            # Skip bootstrap fragment (always loads first)
            if ($fragmentName -eq 'bootstrap') { continue }
            if ($fragmentLookup.ContainsKey($fragmentName)) {
                $orderedFragments.Add($fragmentLookup[$fragmentName])
                [void]$orderedNames.Add($fragmentName)
            }
        }

        $unorderedFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        foreach ($fragment in $otherFragments) {
            if (-not $orderedNames.Contains($fragment.BaseName)) {
                $unorderedFragments.Add($fragment)
            }
        }
        $unorderedFragments = $unorderedFragments | Sort-Object Name

        $nonBootstrapFragments = $orderedFragments + $unorderedFragments
    }
    else {
        # Automatic ordering:
        # - If parallel loading is enabled, avoid dependency parsing here (it will be done once later for level grouping)
        # - Otherwise, use dependency-aware ordering when available
        $nonBootstrapFragments = $otherFragments | Sort-Object Name

        if (-not $EnableParallelLoading -and $FragmentLoadingModuleExists) {
            try {
                Import-Module $FragmentLoadingModule -ErrorAction SilentlyContinue -DisableNameChecking
                if (Get-Command Get-FragmentLoadOrder -ErrorAction SilentlyContinue) {
                    $result = Get-FragmentLoadOrder -FragmentFiles $otherFragments -DisabledFragments $DisabledFragments
                    if ($null -ne $result -and $result.Count -gt 0) {
                        $nonBootstrapFragments = $result
                    }
                }
            }
            catch {
                # Keep alphabetical fallback
                $nonBootstrapFragments = $otherFragments | Sort-Object Name
            }
        }
    }
    
    # Ensure $nonBootstrapFragments is never null (fallback to empty array if needed)
    if ($null -eq $nonBootstrapFragments) {
        $nonBootstrapFragments = @()
    }

    $disabledSet = $null
    if ($DisabledFragments) {
        $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($name in $DisabledFragments) {
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            [void]$disabledSet.Add($name)
        }
    }

    $fragmentsToLoad = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    # Always load bootstrap first
    if ($bootstrapFragment) {
        foreach ($fragment in $bootstrapFragment) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    # Add the remaining fragments in the chosen order
    if ($null -ne $nonBootstrapFragments -and $nonBootstrapFragments.Count -gt 0) {
        foreach ($fragment in $nonBootstrapFragments) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    return @{
        BootstrapFragment     = $bootstrapFragment
        FragmentsToLoad       = $fragmentsToLoad
        DisabledSet           = $disabledSet
        NonBootstrapFragments = $nonBootstrapFragments
    }
}

Export-ModuleMember -Function Initialize-FragmentDiscovery
