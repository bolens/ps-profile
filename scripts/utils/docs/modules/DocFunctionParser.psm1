<#
scripts/utils/docs/modules/DocFunctionParser.psm1

.SYNOPSIS
    Function parsing utilities for documentation extraction.

.DESCRIPTION
    Provides functions for parsing PowerShell functions from AST and extracting their comment-based help.
#>

# Import regex patterns
$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Parses a function from AST and extracts its documentation.

.DESCRIPTION
    Extracts function signature, comment-based help, and parameter details from a function AST node.

.PARAMETER FuncAst
    The FunctionDefinitionAst node to parse.

.PARAMETER Content
    The full file content as a string.

.PARAMETER File
    The file path where the function is located.

.OUTPUTS
    PSCustomObject with function documentation, or $null if no documentation found.
#>
function Parse-FunctionDocumentation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst,

        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter(Mandatory)]
        [string]$File
    )

    $functionName = $FuncAst.Name

    # Skip functions with colons (like global:..) as they are internal aliases
    if ($functionName -match ':') {
        return $null
    }

    $start = $FuncAst.Extent.StartOffset

    # Build function signature
    $signature = $functionName
    if ($FuncAst.Parameters) {
        $paramList = $FuncAst.Parameters | ForEach-Object {
            $paramName = $_.Name.VariablePath.UserPath
            $paramType = if ($_.StaticType) { "[$($_.StaticType.Name)]" } else { "" }
            "$paramType`$$paramName"
        }
        if ($paramList) {
            $signature += " " + ($paramList -join ", ")
        }
    }

    # Get text before the function
    $beforeText = $Content.Substring(0, $start)

    # Find the last comment block before the function
    $commentMatches = $script:regexCommentBlock.Matches($beforeText)
    if ($commentMatches.Count -eq 0) {
        return $null  # No comment block, skip
    }

    $helpContent = $commentMatches[-1].Value  # Last comment block
    # Remove the comment markers
    $helpContent = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''

    # Trim leading/trailing whitespace from help content
    $helpContent = $helpContent.Trim()

    # Remove carriage returns
    $helpContent = $helpContent -replace '\r', ''

    # Normalize indentation by removing common leading spaces
    $lines = $helpContent -split "\r?\n"
    $minIndent = ($lines | Where-Object { $_ -match '\S' } | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
    if ($minIndent -gt 0) {
        $lines = $lines | ForEach-Object { if ($_.Length -ge $minIndent) { $_.Substring($minIndent) } else { $_ } }
    }
    $helpContent = $lines -join "`n"

    # Parse the help content - extract all sections
    $synopsis = ""
    $description = ""
    $parameters = [System.Collections.Generic.List[PSCustomObject]]::new()
    $examples = [System.Collections.Generic.List[string]]::new()
    $outputs = ""
    $notes = ""
    $inputs = ""
    $links = [System.Collections.Generic.List[string]]::new()

    # Extract SYNOPSIS
    if ($helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.(?:DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
        $synopsis = $matches[1].Trim()
    }

    # Extract DESCRIPTION
    if ($helpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
        $description = $matches[1].Trim()
        $description = $description -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    # Extract PARAMETERS
    $paramMatches = $script:regexParameter.Matches($helpContent)
    foreach ($paramMatch in $paramMatches) {
        $paramName = $paramMatch.Groups[1].Value
        $paramDesc = $paramMatch.Groups[2].Value.Trim()
        $paramDesc = $paramDesc -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '

        # Find matching parameter details from AST
        $paramDetail = $null
        if ($FuncAst.Parameters) {
            foreach ($paramAst in $FuncAst.Parameters) {
                if ($paramAst.Name.VariablePath.UserPath -eq $paramName) {
                    $paramType = if ($paramAst.StaticType) { "[$($paramAst.StaticType.Name)]" } else { "" }
                    $isMandatory = $false
                    $isPipeline = $false
                    $position = $null

                    if ($paramAst.Attributes) {
                        foreach ($attr in $paramAst.Attributes) {
                            try {
                                $attrTypeName = $attr.TypeName.GetReflectionType().Name
                                if ($attrTypeName -eq 'ParameterAttribute') {
                                    foreach ($namedArg in $attr.NamedArguments) {
                                        if ($namedArg.ArgumentName -eq 'Mandatory' -and $namedArg.Argument.Value) {
                                            $isMandatory = $true
                                        }
                                        if ($namedArg.ArgumentName -eq 'ValueFromPipeline' -and $namedArg.Argument.Value) {
                                            $isPipeline = $true
                                        }
                                        if ($namedArg.ArgumentName -eq 'Position' -and $namedArg.Argument.Value) {
                                            $position = $namedArg.Argument.Value
                                        }
                                    }
                                }
                            }
                            catch {
                                # Skip attributes we can't parse
                            }
                        }
                    }

                    $paramDetail = [PSCustomObject]@{
                        Type      = $paramType
                        Mandatory = $isMandatory
                        Pipeline  = $isPipeline
                        Position  = $position
                    }
                    break
                }
            }
        }

        $parameters.Add([PSCustomObject]@{
                Name        = $paramName
                Description = $paramDesc
                Type        = if ($paramDetail) { $paramDetail.Type } else { "" }
                Mandatory   = if ($paramDetail) { $paramDetail.Mandatory } else { $false }
                Pipeline    = if ($paramDetail) { $paramDetail.Pipeline } else { $false }
                Position    = if ($paramDetail) { $paramDetail.Position } else { $null }
            })
    }

    # Extract EXAMPLES
    $exampleMatches = $script:regexExample.Matches($helpContent)
    foreach ($exampleMatch in $exampleMatches) {
        $examples.Add($exampleMatch.Groups[1].Value.Trim())
    }

    # Extract OUTPUTS
    if ($helpContent -match '(?s)\.OUTPUTS\s*\n\s*(.+?)(?=\n\s*\.(?:NOTES|INPUTS|LINK)|$)') {
        $outputs = $matches[1].Trim()
        $outputs = $outputs -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    # Extract NOTES
    if ($helpContent -match '(?s)\.NOTES\s*\n\s*(.+?)(?=\n\s*\.(?:INPUTS|LINK)|$)') {
        $notes = $matches[1].Trim()
        $notes = $notes -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    # Extract INPUTS
    if ($helpContent -match '(?s)\.INPUTS\s*\n\s*(.+?)(?=\n\s*\.(?:LINK)|$)') {
        $inputs = $matches[1].Trim()
        $inputs = $inputs -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    # Extract LINKS
    $linkMatches = $script:regexLink.Matches($helpContent)
    foreach ($linkMatch in $linkMatches) {
        $links.Add($linkMatch.Groups[1].Value.Trim())
    }

    return [PSCustomObject]@{
        Name        = $functionName
        Signature   = $signature
        Synopsis    = $synopsis
        Description = $description
        Parameters  = $parameters
        Examples    = $examples
        Outputs     = $outputs
        Notes       = $notes
        Inputs      = $inputs
        Links       = $links
        File        = $File
    }
}

Export-ModuleMember -Function Parse-FunctionDocumentation

