<#
scripts/lib/AstParsing.psm1

.SYNOPSIS
    PowerShell AST parsing utilities.

.DESCRIPTION
    Provides common functions for parsing PowerShell Abstract Syntax Trees (AST) to extract
    functions, signatures, and other code structure information. This module centralizes
    AST parsing operations that are duplicated across multiple scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Parses a PowerShell file and returns its AST.

.DESCRIPTION
    Parses a PowerShell script file and returns the Abstract Syntax Tree (AST) representation.
    This is the foundation for all AST-based analysis operations.

.PARAMETER Path
    Path to the PowerShell file to parse.

.OUTPUTS
    System.Management.Automation.Language.ScriptBlockAst. The parsed AST.

.EXAMPLE
    $ast = Get-PowerShellAst -Path "profile.d/env.ps1"
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
#>
function Get-PowerShellAst {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $Path -PathType File)) {
            throw "File not found: $Path"
        }
    }
    else {
        # Fallback to manual validation
        if (-not ($Path -and -not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path))) {
            throw "File not found: $Path"
        }
    }

    # Read file content first to handle encoding and line endings properly
    # Try to use FileContent module if available, otherwise fallback to Get-Content
    $content = $null
    if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
        try {
            $content = Read-FileContent -Path $Path
        }
        catch {
            # Fallback to Get-Content if Read-FileContent fails
            $content = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction Stop
        }
    }
    else {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction Stop
    }

    if ([string]::IsNullOrWhiteSpace($content)) {
        throw "File is empty: $Path"
    }

    # Parse from content string instead of file path for better encoding/line ending handling
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$errors)

    if ($null -eq $ast) {
        throw "Failed to parse $Path : Could not generate AST"
    }

    if ($errors -and $errors.Count -gt 0) {
        $errorMessages = $errors | ForEach-Object { 
            $msg = $_.Message
            if ([string]::IsNullOrWhiteSpace($msg)) {
                $msg = "Parse error at line $($_.Extent.StartLineNumber), column $($_.Extent.StartColumnNumber)"
            }
            $msg
        } | Select-Object -First 5
        $errorSummary = $errorMessages -join '; '
        # Truncate if too long
        if ($errorSummary.Length -gt 200) {
            $errorSummary = $errorSummary.Substring(0, 197) + "..."
        }
        # Clean up repetitive patterns
        $errorSummary = $errorSummary -replace ';{3,}', ';'
        if ($errors.Count -gt 5) {
            $errorSummary += " (and $($errors.Count - 5) more error(s))"
        }
        throw "PowerShell syntax errors in file $Path : $errorSummary"
    }

    return $ast
}

<#
.SYNOPSIS
    Gets all function definitions from a PowerShell AST.

.DESCRIPTION
    Finds all function definitions in a PowerShell AST, optionally filtering out
    internal functions (those with colons in their names like global:function).

.PARAMETER Ast
    The PowerShell AST to search.

.PARAMETER IncludeInternal
    If specified, includes internal functions (those with colons in their names).
    Defaults to false.

.OUTPUTS
    System.Management.Automation.Language.FunctionDefinitionAst[]. Array of function AST nodes.

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $functions = Get-FunctionsFromAst -Ast $ast
    foreach ($func in $functions) {
        Write-Output "Found function: $($func.Name)"
    }
#>
function Get-FunctionsFromAst {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.FunctionDefinitionAst[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.Ast]$Ast,

        [switch]$IncludeInternal
    )

    $functions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    if (-not $IncludeInternal) {
        $functions = $functions | Where-Object { $_.Name -notmatch ':' }
    }

    return $functions
}

<#
.SYNOPSIS
    Gets the function signature string from a function AST.

.DESCRIPTION
    Builds a function signature string from a FunctionDefinitionAst, including the function name
    and parameter list with types.

.PARAMETER FuncAst
    The FunctionDefinitionAst node to extract the signature from.

.OUTPUTS
    System.String. The function signature (e.g., "Get-Example [string]$Name, [int]$Count").

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $functions = Get-FunctionsFromAst -Ast $ast
    foreach ($func in $functions) {
        $signature = Get-FunctionSignature -FuncAst $func
        Write-Output $signature
    }
#>
function Get-FunctionSignature {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst
    )

    $signature = $FuncAst.Name

    # Parameters are in Body.ParamBlock, not directly in Parameters
    $paramBlock = if ($FuncAst.Body -and $FuncAst.Body.ParamBlock) {
        $FuncAst.Body.ParamBlock
    }
    elseif ($FuncAst.Parameters) {
        # Fallback to direct Parameters property if it exists
        $FuncAst.Parameters
    }
    else {
        $null
    }

    if ($paramBlock -and $paramBlock.Parameters) {
        $paramList = $paramBlock.Parameters | ForEach-Object {
            $paramName = $_.Name.VariablePath.UserPath
            $paramType = if ($_.StaticType) { "[$($_.StaticType.Name)]" } else { "" }
            "$paramType`$$paramName"
        }
        if ($paramList) {
            $signature += " " + ($paramList -join ", ")
        }
    }

    return $signature
}

<#
.SYNOPSIS
    Gets the text content before a function definition.

.DESCRIPTION
    Extracts the text content that appears before a function definition in a file.
    This is useful for finding comment-based help blocks that precede functions.

.PARAMETER FuncAst
    The FunctionDefinitionAst node.

.PARAMETER Content
    The full file content as a string.

.OUTPUTS
    System.String. The text content before the function definition.

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $content = Get-Content -Path "script.ps1" -Raw
    $functions = Get-FunctionsFromAst -Ast $ast
    foreach ($func in $functions) {
        $beforeText = Get-TextBeforeFunction -FuncAst $func -Content $content
        # Check for comment blocks in $beforeText
    }
#>
function Get-TextBeforeFunction {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $start = $FuncAst.Extent.StartOffset
    if ($start -gt 0) {
        return $Content.Substring(0, $start)
    }
    return ""
}

<#
.SYNOPSIS
    Gets the text content of a function body.

.DESCRIPTION
    Extracts the text content of a function's body from its AST.

.PARAMETER FuncAst
    The FunctionDefinitionAst node.

.OUTPUTS
    System.String. The function body text.

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $functions = Get-FunctionsFromAst -Ast $ast
    foreach ($func in $functions) {
        $body = Get-FunctionBody -FuncAst $func
        Write-Output "Function $($func.Name) body length: $($body.Length)"
    }
#>
function Get-FunctionBody {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst
    )

    if ($FuncAst.Body -and $FuncAst.Body.Extent) {
        return $FuncAst.Body.Extent.Text
    }
    return ""
}

<#
.SYNOPSIS
    Calculates code complexity metrics from an AST.

.DESCRIPTION
    Counts control flow statements (if, while, foreach, for, switch, try) in an AST
    to provide a simple complexity metric.

.PARAMETER Ast
    The PowerShell AST to analyze.

.OUTPUTS
    System.Int32. The complexity count (number of control flow statements).

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $complexity = Get-AstComplexity -Ast $ast
    Write-Output "Code complexity: $complexity"
#>
function Get-AstComplexity {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    $complexity = ($Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.IfStatementAst] -or
                $node -is [System.Management.Automation.Language.WhileStatementAst] -or
                $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
                $node -is [System.Management.Automation.Language.ForStatementAst] -or
                $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
                $node -is [System.Management.Automation.Language.TryStatementAst]
            }, $true)).Count

    return $complexity
}

Export-ModuleMember -Function @(
    'Get-PowerShellAst',
    'Get-FunctionsFromAst',
    'Get-FunctionSignature',
    'Get-TextBeforeFunction',
    'Get-FunctionBody',
    'Get-AstComplexity'
)

