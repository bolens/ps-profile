<#
scripts/utils/docs/modules/DocParser.psm1

.SYNOPSIS
    Documentation parser utilities.

.DESCRIPTION
    Provides functions for parsing PowerShell files to extract functions and aliases
    with their comment-based help.
    
    Note: This module imports and uses functions from specialized submodules:
    - DocParserRegex.psm1: Regex pattern definitions
    - DocFunctionParser.psm1: Function parsing logic (AST function definitions)
    - DocAgentModeFunctionParser.psm1: Dynamic registration parsing (Set-AgentModeFunction, Register-LazyFunction, Set-Item Function:)
    - DocAliasParser.psm1: Alias detection logic
#>

$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
$functionParserPath = Join-Path $PSScriptRoot 'DocFunctionParser.psm1'
$agentModeParserPath = Join-Path $PSScriptRoot 'DocAgentModeFunctionParser.psm1'
$aliasParserPath = Join-Path $PSScriptRoot 'DocAliasParser.psm1'

if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
if (Test-Path $functionParserPath) {
    Import-Module $functionParserPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
if (Test-Path $agentModeParserPath) {
    Import-Module $agentModeParserPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
if (Test-Path $aliasParserPath) {
    Import-Module $aliasParserPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}

function Get-DeduplicatedDocumentedCommands {
    <#
    .SYNOPSIS
        Deduplicates parsed command metadata by name using stable file-path ordering.

    .DESCRIPTION
        When the same command name appears in multiple profile files, keeps the entry
        from the lexicographically latest source file so generation is deterministic
        across filesystems and CI runners.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[PSCustomObject]]$Commands,

        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    $commandByName = @{}
    foreach ($command in $Commands) {
        $name = $command.$PropertyName
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $existing = $commandByName[$name]
        if (-not $existing -or ($command.File -and $existing.File -and $command.File -gt $existing.File)) {
            $commandByName[$name] = $command
        }
    }

    $deduped = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($name in ($commandByName.Keys | Sort-Object)) {
        $deduped.Add($commandByName[$name])
    }

    return $deduped
}

<#
.SYNOPSIS
    Parses PowerShell files to extract functions and aliases with documentation.

.DESCRIPTION
    Scans PowerShell files in the specified directory and extracts functions and aliases
    along with their comment-based help content.

.PARAMETER ProfilePath
    Path to the directory containing PowerShell files to parse.

.PARAMETER Files
    Optional list of specific profile script files to parse instead of scanning the full tree.

.OUTPUTS
    PSCustomObject with Functions and Aliases properties, each containing a list of parsed items.
.EXAMPLE
    Get-DocumentedCommands

#>
function Get-DocumentedCommands {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath,

        [string[]]$Files
    )

    $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
    $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()
    $functionNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($Files -and $Files.Count -gt 0) {
        $sourceFiles = @($Files | Sort-Object { $_ })
    }
    else {
        $sourceFiles = @(Get-ChildItem -Path $ProfilePath -Filter '*.ps1' -Recurse -File |
            Sort-Object FullName |
            ForEach-Object { $_.FullName })
    }

    foreach ($file in $sourceFiles) {
        Write-Verbose "Scanning $file for functions..."

        $content = Get-Content -LiteralPath $file -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }

        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
        if (-not $ast) {
            continue
        }

        $fileLines = [string[]]@($content -split "\r?\n")

        $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        foreach ($funcAst in $functionAsts) {
            $parsedFunction = Parse-FunctionDocumentation -FuncAst $funcAst -Content $content -File $file
            if ($parsedFunction) {
                $functions.Add($parsedFunction)
                [void]$functionNames.Add($parsedFunction.Name)
            }
        }

        $dynamicFunctions = Parse-DynamicFunctionsFromFile `
            -File $file `
            -ExistingFunctionNames $functionNames `
            -Content $content `
            -FileLines $fileLines `
            -Ast $ast
        foreach ($parsedFunction in $dynamicFunctions) {
            $functions.Add($parsedFunction)
            [void]$functionNames.Add($parsedFunction.Name)
        }

        $parsedAliases = Parse-AliasesFromFile -File $file -Functions $functions -Content $content -Ast $ast
        foreach ($alias in $parsedAliases) {
            $aliases.Add($alias)
        }
    }

    $functions = Get-DeduplicatedDocumentedCommands -Commands $functions -PropertyName 'Name'
    $aliases = Get-DeduplicatedDocumentedCommands -Commands $aliases -PropertyName 'Name'

    return [PSCustomObject]@{
        Functions = $functions
        Aliases   = $aliases
    }
}

Export-ModuleMember -Function Get-DocumentedCommands, Get-DeduplicatedDocumentedCommands
