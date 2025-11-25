<#
scripts/utils/docs/modules/DocParser.psm1

.SYNOPSIS
    Documentation parser utilities.

.DESCRIPTION
    Provides functions for parsing PowerShell files to extract functions and aliases
    with their comment-based help.
    
    Note: This module imports and uses functions from specialized submodules:
    - DocParserRegex.psm1: Regex pattern definitions
    - DocFunctionParser.psm1: Function parsing logic
    - DocAliasParser.psm1: Alias detection logic
#>

# Import specialized submodules
$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
$functionParserPath = Join-Path $PSScriptRoot 'DocFunctionParser.psm1'
$aliasParserPath = Join-Path $PSScriptRoot 'DocAliasParser.psm1'

if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $functionParserPath) {
    Import-Module $functionParserPath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $aliasParserPath) {
    Import-Module $aliasParserPath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Parses PowerShell files to extract functions and aliases with documentation.

.DESCRIPTION
    Scans PowerShell files in the specified directory and extracts functions and aliases
    along with their comment-based help content.

.PARAMETER ProfilePath
    Path to the directory containing PowerShell files to parse.

.OUTPUTS
    PSCustomObject with Functions and Aliases properties, each containing a list of parsed items.
#>
function Get-DocumentedCommands {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath
    )

    # Use List for better performance than array concatenation
    $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
    $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()

    Get-ChildItem -Path $ProfilePath -Filter '*.ps1' | ForEach-Object {
        $file = $_.FullName
        Write-Output "Scanning $file for functions..."

        # Parse the file content to find functions using AST
        $content = Get-Content $file -Raw
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
        $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

        foreach ($funcAst in $functionAsts) {
            $parsedFunction = Parse-FunctionDocumentation -FuncAst $funcAst -Content $content -File $file
            if ($parsedFunction) {
                $functions.Add($parsedFunction)
            }
        }

        # Parse aliases from the file
        $parsedAliases = Parse-AliasesFromFile -File $file -Functions $functions
        foreach ($alias in $parsedAliases) {
            $aliases.Add($alias)
        }
    }

    return [PSCustomObject]@{
        Functions = $functions
        Aliases   = $aliases
    }
}

Export-ModuleMember -Function Get-DocumentedCommands
