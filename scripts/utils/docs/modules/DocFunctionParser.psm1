<#
scripts/utils/docs/modules/DocFunctionParser.psm1

.SYNOPSIS
    Function parsing utilities for documentation extraction.

.DESCRIPTION
    Provides functions for parsing PowerShell functions from AST and extracting their comment-based help.
#>

$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
$helpParserPath = Join-Path $PSScriptRoot 'DocHelpParser.psm1'

if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
if (Test-Path $helpParserPath) {
    Import-Module $helpParserPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
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
.EXAMPLE
    Parse-FunctionDocumentation

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

    if ($functionName -match ':') {
        return $null
    }

    $start = $FuncAst.Extent.StartOffset
    $beforeText = $Content.Substring(0, $start)
    $commentMatches = $script:regexCommentBlock.Matches($beforeText)
    if ($commentMatches.Count -eq 0) {
        return $null
    }

    $helpContent = Normalize-CommentHelpBlock -CommentBlock $commentMatches[-1].Value
    $parameterAsts = if ($FuncAst.Parameters) { $FuncAst.Parameters } else { $null }
    $help = ConvertFrom-CommentHelpContent -HelpContent $helpContent -ParameterAsts $parameterAsts

    return [PSCustomObject]@{
        Name        = $functionName
        Signature   = Build-FunctionSignature -FunctionName $functionName -ParameterAsts $parameterAsts
        Synopsis    = $help.Synopsis
        Description = $help.Description
        Parameters  = $help.Parameters
        Examples    = $help.Examples
        Outputs     = $help.Outputs
        Notes       = $help.Notes
        Inputs      = $help.Inputs
        Links       = $help.Links
        File        = $File
    }
}

Export-ModuleMember -Function Parse-FunctionDocumentation
