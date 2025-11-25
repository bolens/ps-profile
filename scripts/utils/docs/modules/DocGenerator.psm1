<#
scripts/utils/docs/modules/DocGenerator.psm1

.SYNOPSIS
    Markdown documentation generation utilities.

.DESCRIPTION
    Provides functions for generating markdown documentation files from parsed function and alias data.
#>

<#
.SYNOPSIS
    Determines whether documentation debug output should be written.

.DESCRIPTION
    Checks PS_PROFILE_DEBUG, explicit -Debug usage, and DebugPreference to decide
    if verbose documentation diagnostics should be shown for doc generation modules.

.PARAMETER CallerCmdlet
    The originating PSCmdlet, used to inspect bound -Debug preference.

.OUTPUTS
    System.Boolean
#>
function Test-DocsDebugEnabled {
    param(
        [System.Management.Automation.PSCmdlet]$CallerCmdlet
    )

    if ($env:PS_PROFILE_DEBUG) {
        return $true
    }

    if ($CallerCmdlet -and $CallerCmdlet.MyInvocation -and $CallerCmdlet.MyInvocation.BoundParameters.ContainsKey('Debug')) {
        return $true
    }

    return $DebugPreference -in @('Continue', 'Inquire')
}

<#
.SYNOPSIS
    Writes a structured documentation debug message when debug is enabled.

.DESCRIPTION
    Emits "[DEBUG]" tagged messages to host output only when Test-DocsDebugEnabled
    indicates diagnostics should be shown. Supports optional coloring and caller context.

.PARAMETER Message
    Text to display.
.PARAMETER ForegroundColor
    Optional console color for the message.
.PARAMETER CallerCmdlet
    Originating PSCmdlet for debug preference detection.
#>
function Write-DocsDebugMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray,

        [System.Management.Automation.PSCmdlet]$CallerCmdlet
    )

    if (-not (Test-DocsDebugEnabled -CallerCmdlet $CallerCmdlet)) {
        return
    }

    if ($ForegroundColor) {
        Write-Host "[DEBUG] $Message" -ForegroundColor $ForegroundColor
    }
    else {
        Write-Host "[DEBUG] $Message"
    }
}

<#
.SYNOPSIS
    Helper function for GetRelativePath compatibility with older .NET versions.

.DESCRIPTION
    Calculates a relative path between two absolute paths using URI manipulation.
    This is a compatibility function for older .NET versions that don't have Path.GetRelativePath.

.PARAMETER From
    Source path.

.PARAMETER To
    Target path.

.OUTPUTS
    System.String. Relative path from From to To.
#>
function Get-RelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$From,
        
        [Parameter(Mandatory)]
        [string]$To
    )

    $fromUri = [Uri]::new($From)
    $toUri = [Uri]::new($To)

    if ($fromUri.Scheme -ne $toUri.Scheme) {
        return $To
    }

    $relativeUri = $fromUri.MakeRelativeUri($toUri)
    $relativePath = [Uri]::UnescapeDataString($relativeUri.ToString())

    # Convert forward slashes to backslashes on Windows
    if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
        $relativePath = $relativePath -replace '/', '\'
    }

    return $relativePath
}

<#
.SYNOPSIS
    Generates markdown documentation for functions.

.DESCRIPTION
    Creates individual markdown files for each function with all extracted help content.

.PARAMETER Functions
    List of parsed function objects.

.PARAMETER Aliases
    List of parsed alias objects (used for alias cross-references).

.PARAMETER DocsPath
    Path where documentation files should be generated.

.PARAMETER DocumentedCommandNames
    List to track which commands are being documented (for cleanup).

.OUTPUTS
    None. Files are written directly to disk.
#>
function Write-FunctionDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[PSCustomObject]]$Functions,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[PSCustomObject]]$Aliases,

        [Parameter(Mandatory)]
        [string]$DocsPath,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$DocumentedCommandNames
    )

    Write-DocsDebugMessage -Message "Write-FunctionDocumentation ENTERED" -CallerCmdlet $PSCmdlet
    Write-DocsDebugMessage -Message "Functions parameter: $($Functions.Count) items" -CallerCmdlet $PSCmdlet
    Write-DocsDebugMessage -Message "DocsPath parameter: $DocsPath" -CallerCmdlet $PSCmdlet
    Write-DocsDebugMessage -Message "DocumentedCommandNames parameter: $($DocumentedCommandNames.Count) items" -CallerCmdlet $PSCmdlet

    if (-not $Functions -or $Functions.Count -eq 0) {
        Write-DocsDebugMessage -Message "No functions to document, returning early" -ForegroundColor Red -CallerCmdlet $PSCmdlet
        Write-ScriptMessage -Message "No functions to document."
        return
    }

    Write-DocsDebugMessage -Message "Starting to write $($Functions.Count) function documentation files to: $DocsPath" -ForegroundColor Yellow -CallerCmdlet $PSCmdlet
    Write-ScriptMessage -Message "Writing $($Functions.Count) function documentation files to: $DocsPath"
    
    # Ensure directory exists
    if (-not (Test-Path $DocsPath)) {
        Write-DocsDebugMessage -Message "Creating directory: $DocsPath" -ForegroundColor Cyan -CallerCmdlet $PSCmdlet
        New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
    }
    
    $writtenCount = 0
    $processedCount = 0
    foreach ($function in $Functions) {
        $processedCount++
        if ($processedCount -le 3) {
            Write-DocsDebugMessage -Message "Processing function $processedCount/$($Functions.Count): $($function.Name)" -ForegroundColor Cyan -CallerCmdlet $PSCmdlet
        }
        
        if (-not $function -or -not $function.Name) {
            Write-Warning "Skipping function with null name or object"
            continue
        }
        
        $mdFile = Join-Path $DocsPath "$($function.Name).md"
        if ($processedCount -le 3) {
            Write-DocsDebugMessage -Message "Target file: $mdFile" -ForegroundColor Cyan -CallerCmdlet $PSCmdlet
        }
        $DocumentedCommandNames.Add($function.Name)

        $content = "# $($function.Name)`n`n"
        $content += "## Synopsis`n`n"
        $content += "$(if ($function.Synopsis) { $function.Synopsis } else { 'No synopsis available.' })`n`n"
        $content += "## Description`n`n"
        $content += "$(if ($function.Description) { $function.Description } else { 'No description available.' })`n`n"
        $content += "## Signature`n`n"
        $codeFence = '```'
        $content += "$codeFence" + "powershell`n"
        $content += "$(if ($function.Signature) { $function.Signature } else { 'No signature available.' })`n"
        $content += "$codeFence"

        if ($function.Parameters -and $function.Parameters.Count -gt 0) {
            $content += "`n`n## Parameters`n"
            foreach ($param in $function.Parameters) {
                $content += "`n### -$($param.Name)`n`n"
                
                # Add parameter type if available
                if ($param.Type) {
                    $content += "**Type:** $($param.Type)`n`n"
                }
                
                # Add attributes
                # Use List for better performance than array concatenation
                $attrs = [System.Collections.Generic.List[string]]::new()
                if ($param.Mandatory) { $attrs.Add("Mandatory") }
                if ($param.Pipeline) { $attrs.Add("Accepts pipeline input") }
                if ($param.Position -ne $null) { $attrs.Add("Position: $($param.Position)") }
                if ($attrs.Count -gt 0) {
                    $content += "**Attributes:** " + ($attrs -join ", ") + "`n`n"
                }
                
                # Add description
                $content += "$($param.Description)`n"
            }
        }
        else {
            $content += "`n`n## Parameters`n`nNo parameters."
        }
        
        # Add INPUTS section if available
        if ($function.Inputs) {
            $content += "`n`n## Inputs`n`n$($function.Inputs)`n"
        }
        
        # Add OUTPUTS section if available
        if ($function.Outputs) {
            $content += "`n`n## Outputs`n`n$($function.Outputs)`n"
        }

        $content += "`n`n## Examples"

        if ($function.Examples -and $function.Examples.Count -gt 0) {
            for ($i = 0; $i -lt $function.Examples.Count; $i++) {
                $content += "`n`n### Example $($i + 1)`n`n```powershell`n$($function.Examples[$i])`n````"
            }
        }
        else {
            $content += "`n`nNo examples provided."
        }
        
        # Add NOTES section if available
        if ($function.Notes) {
            $content += "`n`n## Notes`n`n$($function.Notes)`n"
        }
        
        # Add LINKS section if available
        if ($function.Links -and $function.Links.Count -gt 0) {
            $content += "`n`n## Related Links`n"
            foreach ($link in $function.Links) {
                $content += "`n- $link`n"
            }
        }
        
        # Add ALIASES section if this function has any aliases
        $functionAliases = $Aliases | Where-Object { $_.Target -eq $function.Name }
        # Deduplicate by alias name, keeping only one entry per alias name
        # Use a hashtable to track unique aliases, preferring ones with synopsis
        $aliasHash = @{}
        foreach ($alias in $functionAliases) {
            if (-not $aliasHash.ContainsKey($alias.Name)) {
                $aliasHash[$alias.Name] = $alias
            }
            else {
                # Prefer the one with synopsis, or replace if current has synopsis and stored doesn't
                $stored = $aliasHash[$alias.Name]
                if ($alias.Synopsis -and -not $stored.Synopsis) {
                    $aliasHash[$alias.Name] = $alias
                }
                elseif ($alias.Synopsis -and $stored.Synopsis) {
                    # Both have synopsis, prefer the last one (more specific definition)
                    $aliasHash[$alias.Name] = $alias
                }
            }
        }
        $uniqueAliases = $aliasHash.Values | Sort-Object Name
        if ($uniqueAliases.Count -gt 0) {
            $content += "`n`n## Aliases`n`n"
            $content += "This function has the following aliases:`n`n"
            foreach ($alias in $uniqueAliases) {
                $content += "- ``$($alias.Name)`` - "
                if ($alias.Synopsis) {
                    $content += $alias.Synopsis
                }
                else {
                    $content += "Alias for ``$($function.Name)``"
                }
                $content += "`n"
            }
        }

        # Calculate relative path - go up to docs/api level for correct relative path
        $baseDocsPath = Split-Path -Parent $DocsPath
        $relativePath = Get-RelativePath $baseDocsPath $function.File
        $content += "`n`n## Source`n`nDefined in: $relativePath"

        try {
            $content | Out-File -FilePath $mdFile -Encoding UTF8 -NoNewline:$false
            if (Test-Path $mdFile) {
                $writtenCount++
                Write-ScriptMessage -Message "Generated documentation: $mdFile"
            }
            else {
                Write-Warning "File was not created: $mdFile"
            }
        }
        catch {
            Write-Warning "Failed to write documentation file $mdFile : $_"
        }
    }
    
    Write-DocsDebugMessage -Message "Wrote $writtenCount of $($Functions.Count) function documentation files" -ForegroundColor Yellow -CallerCmdlet $PSCmdlet
    Write-ScriptMessage -Message "Completed writing function documentation. Wrote $writtenCount of $($Functions.Count) files."
}

<#
.SYNOPSIS
    Generates markdown documentation for aliases.

.DESCRIPTION
    Creates individual markdown files for each alias.

.PARAMETER Aliases
    List of parsed alias objects.

.PARAMETER DocsPath
    Path where documentation files should be generated.

.PARAMETER DocumentedCommandNames
    List to track which commands are being documented (for cleanup).

.OUTPUTS
    None. Files are written directly to disk.
#>
function Write-AliasDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[PSCustomObject]]$Aliases,

        [Parameter(Mandatory)]
        [string]$DocsPath,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$DocumentedCommandNames
    )

    if (-not $Aliases -or $Aliases.Count -eq 0) {
        Write-ScriptMessage -Message "No aliases to document."
        return
    }

    # Ensure directory exists
    if (-not (Test-Path $DocsPath)) {
        New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
    }

    $writtenCount = 0
    foreach ($alias in $Aliases) {
        if (-not $alias -or -not $alias.Name) {
            Write-Warning "Skipping alias with null name or object"
            continue
        }

        $mdFile = Join-Path $DocsPath "$($alias.Name).md"
        $DocumentedCommandNames.Add($alias.Name)
        
        $content = "# $($alias.Name)`n`n"
        
        # Synopsis
        $content += "## Synopsis`n`n"
        if ($alias.Synopsis) {
            $content += "$($alias.Synopsis)`n`n"
        }
        else {
            $content += "Alias for ``$($alias.Target)``.`n`n"
        }
        
        # Description
        $content += "## Description`n`n"
        if ($alias.Description) {
            $content += "$($alias.Description)`n`n"
        }
        else {
            $content += "This is an alias that points to the ``$($alias.Target)`` command.`n`n"
        }
        
        # Alias Information
        $content += "## Alias Information`n`n"
        $content += "**Alias for:** ``$($alias.Target)```n`n"
        $content += "Use this alias as a shorthand for the full command name.`n`n"
        
        # Examples
        $content += "## Examples`n`n"
        $content += "No examples provided.`n`n"
        
        # Source
        if ($alias.File) {
            $baseDocsPath = Split-Path -Parent $DocsPath
            $relativePath = Get-RelativePath $baseDocsPath $alias.File
            $content += "## Source`n`n"
            $content += "Defined in: $relativePath"
        }
        
        try {
            $content | Out-File -FilePath $mdFile -Encoding UTF8 -NoNewline:$false -Force
            $writtenCount++
            Write-ScriptMessage -Message "Generated alias documentation: $mdFile"
        }
        catch {
            Write-Error "Error generating documentation for alias $($alias.Name): $($_.Exception.Message)"
        }
    }
    
    Write-ScriptMessage -Message "Successfully wrote $writtenCount alias documentation files."
}

Export-ModuleMember -Function Write-FunctionDocumentation, Write-AliasDocumentation, Get-RelativePath

