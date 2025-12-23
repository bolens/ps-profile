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
    index file listing all fragments alphabetically.

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
        # Extract fragment name (e.g., "00-bootstrap" from "00-bootstrap.md")
        $fragmentName = $readme.BaseName
        
        # Extract purpose from README (between "Purpose" and next section)
        $purpose = ''
        $content = Get-Content -Path $readme.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and -not [string]::IsNullOrWhiteSpace($content)) {
            if ($content -match '(?s)Purpose\s+-+\s+(.*?)(?=\r?\n\r?\n\w)') {
                $purpose = $matches[1].Trim()
            }
        }
        
        # If no purpose found, use a default
        if ([string]::IsNullOrWhiteSpace($purpose)) {
            $purpose = "See fragment source for details."
        }

        # Strip number prefix from fragment name for display (e.g., "00-bootstrap" -> "bootstrap")
        $displayName = $fragmentName
        if ($fragmentName -match '^\d+-(.+)') {
            $displayName = $matches[1]
        }

        # Check if source file exists
        $sourceFile = Join-Path $ProfilePath "$fragmentName.ps1"
        $hasSource = Test-Path $sourceFile

        $fragments.Add([PSCustomObject]@{
                Name        = $fragmentName
                DisplayName = $displayName
                Purpose     = $purpose
                ReadmePath  = $readme.Name
                HasSource   = $hasSource
            })
    }

    # Sort fragments alphabetically by display name
    $sortedFragments = $fragments | Sort-Object DisplayName

    # Generate index content
    $indexContent = "# Fragment Documentation`n`n"
    $indexContent += "This documentation provides an overview of all profile fragments. Each fragment is a modular component of the PowerShell profile.`n`n"
    $indexContent += "**Total Fragments:** $($fragments.Count)`n"
    # Use locale-aware date formatting for user-facing documentation
    $generatedDate = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
        Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
    }
    else {
        (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
    $indexContent += "**Generated:** $generatedDate`n`n"
    $indexContent += "## Fragment Overview`n`n"
    $indexContent += "Each fragment provides specific functionality and can be enabled or disabled independently.`n`n"

    # Add all fragments in alphabetical order
    $indexContent += "## All Fragments`n`n"
    foreach ($fragment in $sortedFragments) {
        $link = "[$($fragment.DisplayName)]($($fragment.ReadmePath))"
        $purposeText = if ($fragment.Purpose) { " — $($fragment.Purpose)" } else { "" }
        $indexContent += "- $link$purposeText`n"
    }

    $indexContent += "## Generation`n`n"
    $indexContent += "This index is automatically generated from fragment README files in this directory, which are themselves generated from source files in the `profile.d/` directory.`n"

    # Write index file
    $indexPath = Join-Path $FragmentsPath 'README.md'
    $indexContent | Out-File -FilePath $indexPath -Encoding UTF8 -NoNewline:$false
    Write-ScriptMessage -Message "Generated fragment index: $indexPath"
}

Export-ModuleMember -Function Write-FragmentIndex

