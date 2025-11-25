<#
scripts/utils/docs/modules/DocIndexGenerator.psm1

.SYNOPSIS
    Documentation index generation utilities.

.DESCRIPTION
    Provides functions for generating the main README.md index file for documentation.
#>

<#
.SYNOPSIS
    Generates the main README.md index file for the documentation.

.DESCRIPTION
    Creates a comprehensive index file that groups functions and aliases by their source fragments.

.PARAMETER Functions
    List of parsed function objects.

.PARAMETER Aliases
    List of parsed alias objects.

.PARAMETER DocsPath
    Path where the index file should be generated.

.OUTPUTS
    None. File is written directly to disk.
#>
function Write-DocumentationIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[PSCustomObject]]$Functions,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[PSCustomObject]]$Aliases,

        [Parameter(Mandatory)]
        [string]$DocsPath
    )

    # Generate index file
    $groupedFunctions = $Functions | Group-Object { [System.IO.Path]::GetFileName($_.File) } | Sort-Object Name

    $indexContent = "# PowerShell Profile API Documentation`n`n"
    $indexContent += "This documentation is automatically generated from comment-based help in the profile functions and aliases.`n`n"
    $indexContent += "**Total Functions:** $($Functions.Count)`n"
    $indexContent += "**Total Aliases:** $($Aliases.Count)`n"
    $indexContent += "**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`n`n"
    $indexContent += "## Functions by Fragment`n`n"

    foreach ($group in $groupedFunctions) {
        $fragmentName = $group.Name -replace '\.ps1$', ''
        $functionList = $group.Group | Sort-Object Name | ForEach-Object { "- [$($_.Name)](functions/$($_.Name).md) - $($_.Synopsis)" }
        $indexContent += "`n### $fragmentName ($($group.Count) functions)`n`n$($functionList -join "`n")`n"
    }

    # Add aliases section
    if ($Aliases.Count -gt 0) {
        $groupedAliases = $Aliases | Group-Object { [System.IO.Path]::GetFileName($_.File) } | Sort-Object Name
        $indexContent += "`n`n## Aliases by Fragment`n`n"
        
        foreach ($group in $groupedAliases) {
            $fragmentName = $group.Name -replace '\.ps1$', ''
            $aliasList = $group.Group | Sort-Object Name | ForEach-Object { 
                $desc = if ($_.Synopsis) { $_.Synopsis } else { "Alias for ``$($_.Target)``" }
                "- [$($_.Name)](aliases/$($_.Name).md) - $desc (alias for ``$($_.Target)``)"
            }
            $indexContent += "`n### $fragmentName ($($group.Count) aliases)`n`n$($aliasList -join "`n")`n"
        }
    }

    $indexContent += "`n`n## Generation`n`n"
    $indexContent += "This documentation was generated from the comment-based help in the profile fragments."

    $indexContent | Out-File -FilePath (Join-Path $DocsPath 'README.md') -Encoding UTF8 -NoNewline:$false
}

Export-ModuleMember -Function Write-DocumentationIndex

