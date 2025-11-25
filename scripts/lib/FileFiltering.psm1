<#
scripts/lib/FileFiltering.psm1

.SYNOPSIS
    File filtering utilities for excluding common directories and files.

.DESCRIPTION
    Provides standardized functions for filtering file collections to exclude
    common directories (like .git, node_modules, tests) and specific file patterns.
    This centralizes filtering logic used across multiple scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Filters file objects to exclude common directories and patterns.

.DESCRIPTION
    Filters a collection of file objects (FileInfo or similar) to exclude:
    - Test directories (tests, test)
    - Git directories (.git)
    - Node modules (node_modules)
    - Other common exclusion patterns
    
    Provides a consistent way to filter files across scripts.

.PARAMETER Files
    Array of file objects to filter. Expected to have FullName and/or Name properties.

.PARAMETER ExcludeTests
    If specified, excludes files in test directories. Defaults to $true.

.PARAMETER ExcludeGit
    If specified, excludes files in .git directories. Defaults to $true.

.PARAMETER ExcludeNodeModules
    If specified, excludes files in node_modules directories. Defaults to $true.

.PARAMETER ExcludePatterns
    Additional regex patterns to exclude. Files matching any pattern will be excluded.

.PARAMETER ExcludeNames
    Additional file names to exclude (exact match on Name property).

.OUTPUTS
    Array of filtered file objects.

.EXAMPLE
    $allFiles = Get-ChildItem -Path $Path -Recurse -File
    $filtered = Filter-Files -Files $allFiles -ExcludeTests -ExcludeGit
#>
function Filter-Files {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object[]]$Files,

        [switch]$ExcludeTests = $true,

        [switch]$ExcludeGit = $true,

        [switch]$ExcludeNodeModules = $true,

        [string[]]$ExcludePatterns = @(),

        [string[]]$ExcludeNames = @()
    )

    begin {
        $filteredFiles = [System.Collections.Generic.List[object]]::new()
    }

    process {
        foreach ($file in $Files) {
            if ($null -eq $file) {
                continue
            }

            $fullName = $null
            $name = $null

            # Extract FullName and Name properties
            if ($file.PSObject.Properties['FullName']) {
                $fullName = $file.FullName
            }
            elseif ($file -is [string]) {
                $fullName = $file
            }

            if ($file.PSObject.Properties['Name']) {
                $name = $file.Name
            }
            elseif ($file -is [string]) {
                $name = Split-Path -Leaf $file
            }

            # Skip if we can't determine path
            if (-not $fullName -and -not $name) {
                continue
            }

            # Exclude by name
            if ($name -and $ExcludeNames -contains $name) {
                continue
            }

            # Exclude test directories
            if ($ExcludeTests -and $fullName) {
                if ($fullName -match '[\\/]tests?[\\/]') {
                    continue
                }
            }

            # Exclude git directories
            if ($ExcludeGit -and $fullName) {
                if ($fullName -match '[\\/]\.git[\\/]') {
                    continue
                }
            }

            # Exclude node_modules
            if ($ExcludeNodeModules -and $fullName) {
                if ($fullName -like '*\node_modules\*' -or $fullName -like '*/node_modules/*') {
                    continue
                }
            }

            # Exclude by additional patterns
            if ($ExcludePatterns.Count -gt 0 -and $fullName) {
                $excluded = $false
                foreach ($pattern in $ExcludePatterns) {
                    if ($fullName -match $pattern) {
                        $excluded = $true
                        break
                    }
                }
                if ($excluded) {
                    continue
                }
            }

            $filteredFiles.Add($file)
        }
    }

    end {
        return $filteredFiles.ToArray()
    }
}

<#
.SYNOPSIS
    Gets default exclusion patterns for common directories.

.DESCRIPTION
    Returns a hashtable of compiled regex patterns for common exclusion patterns.
    Useful for scripts that need to apply consistent filtering logic.

.OUTPUTS
    Hashtable with keys: Tests, Git, NodeModules

.EXAMPLE
    $patterns = Get-DefaultExclusionPatterns
    $files = Get-ChildItem -Recurse | Where-Object { $_.FullName -notmatch $patterns.Tests }
#>
function Get-DefaultExclusionPatterns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Tests       = [regex]::new('[\\/]tests?[\\/]', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        Git         = [regex]::new('[\\/]\.git[\\/]', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        NodeModules = [regex]::new('[\\/]node_modules[\\/]', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Filter-Files',
    'Get-DefaultExclusionPatterns'
)

