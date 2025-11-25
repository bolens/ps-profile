<#
scripts/utils/docs/modules/FragmentIndexGenerator.psm1

.SYNOPSIS
    Fragment documentation index generation utilities.

.DESCRIPTION
    Provides functions for generating the fragment documentation index file.
#>

<#
.SYNOPSIS
    Generates the fragment documentation index file.

.DESCRIPTION
    Reads fragment README files from the fragments directory and generates a comprehensive
    index file that groups fragments by their number ranges (00-09, 10-19, etc.).

.PARAMETER FragmentsPath
    Path to the fragments documentation directory (e.g., docs/fragments).

.PARAMETER ProfilePath
    Path to the profile.d directory containing the fragment source files.

.OUTPUTS
    None. File is written directly to disk.
#>
function Write-FragmentIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentsPath,

        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    # Resolve path to absolute if needed
    if (-not [System.IO.Path]::IsPathRooted($FragmentsPath)) {
        $resolved = Resolve-Path -Path $FragmentsPath -ErrorAction SilentlyContinue
        if ($resolved) {
            $FragmentsPath = $resolved.Path
        }
        else {
            Write-Warning "Fragment path could not be resolved: $FragmentsPath"
            return
        }
    }
    
    # Ensure path exists
    if (-not (Test-Path $FragmentsPath)) {
        Write-Warning "Fragment path does not exist: $FragmentsPath"
        return
    }

    # Get all fragment README files (exclude README.md)
    $fragmentReadmes = Get-ChildItem -Path $FragmentsPath -Filter '*.md' -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -ne 'README.md' } |
    Sort-Object Name

    if ($null -eq $fragmentReadmes -or $fragmentReadmes.Count -eq 0) {
        Write-Warning "No fragment README files found in $FragmentsPath"
        return
    }

    # Parse fragment information
    $fragments = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    foreach ($readme in $fragmentReadmes) {
        $content = Get-Content -Path $readme.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            continue
        }

        # Extract fragment name (e.g., "00-bootstrap" from "00-bootstrap.md")
        $fragmentName = $readme.BaseName
        
        # Extract purpose from README (between "Purpose" and next section)
        $purpose = ''
        if ($content -match '(?s)Purpose\s+-+\s+(.*?)(?=\r?\n\r?\n\w)') {
            $purpose = $matches[1].Trim()
        }

        # Extract fragment number
        $fragmentNumber = -1
        if ($fragmentName -match '^(\d+)-') {
            $fragmentNumber = [int]$matches[1]
        }

        # Check if source file exists
        $sourceFile = Join-Path $ProfilePath "$fragmentName.ps1"
        $hasSource = Test-Path $sourceFile

        $fragments.Add([PSCustomObject]@{
                Name       = $fragmentName
                Number     = $fragmentNumber
                Purpose    = $purpose
                ReadmePath = $readme.Name
                HasSource  = $hasSource
            })
    }

    # Group fragments by number ranges
    $groupedFragments = $fragments | 
    Where-Object { $_.Number -ge 0 } | 
    Group-Object { 
        [math]::Floor($_.Number / 10) * 10 
    } | 
    Sort-Object Name

    # Generate index content
    $indexContent = "# Fragment Documentation`n`n"
    $indexContent += "This documentation provides an overview of all profile fragments. Each fragment is a modular component of the PowerShell profile.`n`n"
    $indexContent += "**Total Fragments:** $($fragments.Count)`n"
    $indexContent += "**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`n`n"
    $indexContent += "## Fragment Overview`n`n"
    $indexContent += "Fragments are loaded in numerical order (00-99). Each fragment provides specific functionality and can be enabled or disabled independently.`n`n"

    # Add fragments by range
    foreach ($group in $groupedFragments) {
        $rangeStart = $group.Name
        $rangeEnd = $rangeStart + 9
        $indexContent += "`n### Fragments $rangeStart-$rangeEnd`n`n"
        
        $sortedFragments = $group.Group | Sort-Object Number
        foreach ($fragment in $sortedFragments) {
            $link = "[$($fragment.Name)]($($fragment.ReadmePath))"
            $purposeText = if ($fragment.Purpose) { " — $($fragment.Purpose)" } else { "" }
            $indexContent += "- $link$purposeText`n"
        }
    }

    # Add any fragments without numbers
    $unnumberedFragments = $fragments | Where-Object { $_.Number -lt 0 }
    if ($unnumberedFragments.Count -gt 0) {
        $indexContent += "`n### Unnumbered Fragments`n`n"
        foreach ($fragment in $unnumberedFragments) {
            $link = "[$($fragment.Name)]($($fragment.ReadmePath))"
            $purposeText = if ($fragment.Purpose) { " — $($fragment.Purpose)" } else { "" }
            $indexContent += "- $link$purposeText`n"
        }
    }

    $indexContent += "`n`n## Fragment Load Order`n`n"
    $indexContent += "Fragments are loaded in the following order based on their numeric prefix:`n`n"
    $indexContent += "- **00-09**: Core bootstrap, environment, helpers`n"
    $indexContent += "- **10-19**: Terminal configuration (PSReadLine, prompts, Git)`n"
    $indexContent += "- **20-29**: Container engines, cloud tools`n"
    $indexContent += "- **30-39**: Development tools and aliases`n"
    $indexContent += "- **40-69**: Language-specific tools`n"
    $indexContent += "- **70-79**: Advanced features`n`n"

    $indexContent += "## Generation`n`n"
    $indexContent += "This index is automatically generated from fragment README files in the `profile.d/` directory.`n"

    # Write index file
    $indexPath = Join-Path $FragmentsPath 'README.md'
    $indexContent | Out-File -FilePath $indexPath -Encoding UTF8 -NoNewline:$false
    Write-ScriptMessage -Message "Generated fragment index: $indexPath"
}

Export-ModuleMember -Function Write-FragmentIndex

