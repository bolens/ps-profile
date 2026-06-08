<#
scripts/utils/docs/modules/DocAgentModeFunctionParser.psm1

.SYNOPSIS
    Dynamic function registration parsing utilities for documentation extraction.

.DESCRIPTION
    Detects Set-AgentModeFunction, Register-LazyFunction, and Set-Item Function:
    registrations and extracts adjacent comment-based help, single-line comments,
    and inline trailing comments for generated API docs.
#>

$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
$helpParserPath = Join-Path $PSScriptRoot 'DocHelpParser.psm1'
$aliasParserPath = Join-Path $PSScriptRoot 'DocAliasParser.psm1'

if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
if (Test-Path $helpParserPath) {
    Import-Module $helpParserPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
if (Test-Path $aliasParserPath) {
    Import-Module $aliasParserPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Resolves a script block argument from a command parameter.

.DESCRIPTION
    Inspects named command parameters and returns the associated script block AST.

.PARAMETER CommandAst
    Command AST to inspect.

.PARAMETER ParameterName
    Parameter name whose script block value should be returned.

.OUTPUTS
    System.Management.Automation.Language.ScriptBlockAst

.EXAMPLE
    Get-CommandParameterScriptBlockAst -CommandAst $cmd -ParameterName 'Body'
#>
function Get-CommandParameterScriptBlockAst {
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    param(
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [string]$ParameterName
    )

    if (-not $CommandAst -or -not $ParameterName) {
        return $null
    }

    $elements = $CommandAst.CommandElements
    for ($i = 0; $i -lt $elements.Count; $i++) {
        $element = $elements[$i]
        if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and $element.ParameterName -ieq $ParameterName) {
            if ($element.Argument -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                return $element.Argument.ScriptBlock
            }

            if ($i + 1 -lt $elements.Count -and
                $elements[$i + 1] -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
                return $elements[$i + 1].ScriptBlock
            }
        }
    }

    return $null
}

<#
.SYNOPSIS
    Extracts a function name from a Set-Item or New-Item Function: command.

.DESCRIPTION
    Reads the Function: path from Set-Item or New-Item command arguments.

.PARAMETER CommandAst
    Set-Item or New-Item command AST.

.OUTPUTS
    System.String

.EXAMPLE
    Get-FunctionNameFromSetItemCommand -CommandAst $commandAst
#>
function Get-FunctionNameFromSetItemCommand {
    [OutputType([string])]
    param(
        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    if (-not $CommandAst) {
        return $null
    }

    $pathValue = Get-CommandParameterValue -CommandAst $CommandAst -ParameterName 'Path'
    if (-not $pathValue) {
        $pathValue = Get-CommandParameterValue -CommandAst $CommandAst -ParameterName 'LiteralPath'
    }

    if (-not $pathValue) {
        foreach ($element in $CommandAst.CommandElements) {
            if ($element -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $pathValue = $element.Value
                break
            }
        }
    }

    if (-not $pathValue) {
        return $null
    }

    $pathText = $pathValue.ToString().Trim('"', "'")
    if ($pathText -match $script:regexFunctionPath) {
        return $matches[1]
    }

    return $null
}

<#
.SYNOPSIS
    Finds dynamic function registration commands in a script AST.

.DESCRIPTION
    Collects Set-AgentModeFunction, Register-LazyFunction, and Set-Item Function:
    registration commands in source order.

.PARAMETER Ast
    Parsed script AST to search.

.OUTPUTS
    System.Collections.Generic.List[PSCustomObject]

.EXAMPLE
    Get-DynamicRegistrationCommands -Ast $ast
#>
function Get-DynamicRegistrationCommands {
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        [System.Management.Automation.Language.Ast]$Ast
    )

    $registrations = [System.Collections.Generic.List[PSCustomObject]]::new()
    $commandAsts = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)

    foreach ($commandAst in $commandAsts) {
        $commandName = $commandAst.GetCommandName()
        if (-not $commandName) {
            continue
        }

        switch -Regex ($commandName) {
            '^Set-AgentModeFunction$' {
                $registrations.Add([PSCustomObject]@{
                        Type       = 'Set-AgentModeFunction'
                        CommandAst = $commandAst
                        StartOffset = $commandAst.Extent.StartOffset
                    })
                continue
            }
            '^Register-LazyFunction$' {
                $registrations.Add([PSCustomObject]@{
                        Type       = 'Register-LazyFunction'
                        CommandAst = $commandAst
                        StartOffset = $commandAst.Extent.StartOffset
                    })
                continue
            }
            '^(Set-Item|New-Item)$' {
                $functionName = Get-FunctionNameFromSetItemCommand -CommandAst $commandAst
                if ($functionName) {
                    $registrations.Add([PSCustomObject]@{
                            Type         = 'Set-Item'
                            CommandAst   = $commandAst
                            StartOffset  = $commandAst.Extent.StartOffset
                            FunctionName = $functionName
                        })
                }
            }
        }
    }

    return [System.Collections.Generic.List[PSCustomObject]]($registrations | Sort-Object StartOffset)
}

<#
.SYNOPSIS
    Returns parameter AST nodes for a dynamic registration body.

.DESCRIPTION
    Reads the registration script block param block when one is declared.

.PARAMETER RegistrationType
    Registration command type name.

.PARAMETER CommandAst
    Registration command AST.

.OUTPUTS
    System.Management.Automation.Language.ParameterAst[]

.EXAMPLE
    Get-RegistrationParameterAsts -RegistrationType 'Set-AgentModeFunction' -CommandAst $cmd
#>
function Get-RegistrationParameterAsts {
    [OutputType([System.Management.Automation.Language.ParameterAst[]])]
    param(
        [Parameter(Mandatory)]
        [string]$RegistrationType,

        [Parameter(Mandatory)]
        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    switch ($RegistrationType) {
        'Set-AgentModeFunction' {
            $bodyAst = Get-CommandParameterScriptBlockAst -CommandAst $CommandAst -ParameterName 'Body'
            if ($bodyAst -and $bodyAst.ParamBlock -and $bodyAst.ParamBlock.Parameters) {
                return $bodyAst.ParamBlock.Parameters
            }
        }
        'Set-Item' {
            $valueAst = Get-CommandParameterScriptBlockAst -CommandAst $CommandAst -ParameterName 'Value'
            if ($valueAst -and $valueAst.ParamBlock -and $valueAst.ParamBlock.Parameters) {
                return $valueAst.ParamBlock.Parameters
            }
        }
    }

    return $null
}

<#
.SYNOPSIS
    Builds a documentation object from dynamic registration help content.

.DESCRIPTION
    Converts parsed help text and optional parameter AST nodes into the shared
    documentation object shape used by API doc generation.

.PARAMETER FunctionName
    Registered function name.

.PARAMETER HelpContent
    Structured or normalized help text.

.PARAMETER File
    Source file path.

.PARAMETER ParameterAsts
    Optional parameter AST nodes from the registration body.

.OUTPUTS
    PSCustomObject

.EXAMPLE
    New-DynamicFunctionDocumentation -FunctionName 'Invoke-GitClone' -HelpContent $help -File $file
#>
function New-DynamicFunctionDocumentation {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [string]$HelpContent,

        [Parameter(Mandatory)]
        [string]$File,

        [System.Management.Automation.Language.ParameterAst[]]$ParameterAsts
    )

    $help = ConvertFrom-CommentHelpContent -HelpContent $HelpContent -ParameterAsts $ParameterAsts
    if (-not $help.Synopsis -and -not $help.Description) {
        return $null
    }

    $description = $help.Description
    if ($help.Synopsis -and [string]::IsNullOrWhiteSpace($description)) {
        $description = $help.Synopsis
    }

    return [PSCustomObject]@{
        Name        = $FunctionName
        Signature   = Build-FunctionSignature -FunctionName $FunctionName -ParameterAsts $ParameterAsts
        Synopsis    = $help.Synopsis
        Description = $description
        Parameters  = $help.Parameters
        Examples    = $help.Examples
        Outputs     = $help.Outputs
        Notes       = $help.Notes
        Inputs      = $help.Inputs
        Links       = $help.Links
        File        = $File
    }
}

<#
.SYNOPSIS
    Resolves the function name for a dynamic registration command.

.DESCRIPTION
    Reads the Name argument or preset function name for a registration command.

.PARAMETER RegistrationType
    Registration command type name.

.PARAMETER CommandAst
    Registration command AST.

.PARAMETER PresetFunctionName
    Optional function name preset for Set-Item registrations.

.OUTPUTS
    System.String

.EXAMPLE
    Get-RegistrationFunctionName -RegistrationType 'Register-LazyFunction' -CommandAst $cmd
#>
function Get-RegistrationFunctionName {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$RegistrationType,

        [Parameter(Mandatory)]
        [System.Management.Automation.Language.CommandAst]$CommandAst,

        [string]$PresetFunctionName
    )

    if ($PresetFunctionName) {
        return $PresetFunctionName
    }

    $functionName = Get-CommandParameterValue -CommandAst $CommandAst -ParameterName 'Name'
    if (-not $functionName) {
        return $null
    }

    return $functionName.ToString().Trim('"', "'")
}

<#
.SYNOPSIS
    Parses dynamic function registrations from a PowerShell file.

.DESCRIPTION
    Finds Set-AgentModeFunction, Register-LazyFunction, and Set-Item Function:
    registrations with resolvable help and returns documentation objects compatible
    with Parse-FunctionDocumentation output.

.PARAMETER File
    Path to the PowerShell file to parse.

.PARAMETER ExistingFunctionNames
    Function names already discovered via AST parsing (skipped to avoid duplicates).

.PARAMETER Content
    Optional pre-read file content. Avoids duplicate disk reads when supplied by Get-DocumentedCommands.

.PARAMETER FileLines
    Optional pre-split file lines corresponding to Content.

.PARAMETER Ast
    Optional pre-parsed script AST for the file.

.OUTPUTS
    List of PSCustomObject function documentation entries.

.EXAMPLE
    Parse-DynamicFunctionsFromFile -File ./profile.d/git.ps1
#>
function Parse-DynamicFunctionsFromFile {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        [Parameter(Mandatory)]
        [string]$File,

        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]]$ExistingFunctionNames,

        [string]$Content,

        [string[]]$FileLines,

        [System.Management.Automation.Language.Ast]$Ast
    )

    $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
    if (-not $Content) {
        if (-not (Test-Path -LiteralPath $File)) {
            return $functions
        }

        $FileLines = [string[]]@(Get-Content -LiteralPath $File -ErrorAction SilentlyContinue)
        if ($FileLines.Count -eq 0) {
            return $functions
        }

        $Content = $FileLines -join "`n"
    }
    elseif (-not $FileLines -or $FileLines.Count -eq 0) {
        $FileLines = [string[]]@($Content -split "\r?\n")
    }

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $functions
    }

    if (-not $Ast) {
        $parseErrors = $null
        $tokens = $null
        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($File, [ref]$tokens, [ref]$parseErrors)
        if (-not $Ast) {
            return $functions
        }
    }

    $content = $Content
    $fileLines = $FileLines
    $ast = $Ast

    $registrations = Get-DynamicRegistrationCommands -Ast $ast
    foreach ($registration in $registrations) {
        $functionName = Get-RegistrationFunctionName `
            -RegistrationType $registration.Type `
            -CommandAst $registration.CommandAst `
            -PresetFunctionName $registration.FunctionName

        if (-not $functionName -or $functionName -match ':' -or $functionName -match '^__') {
            continue
        }

        if ($ExistingFunctionNames -and $ExistingFunctionNames.Contains($functionName)) {
            continue
        }

        $helpContent = Get-RegistrationHelpContent `
            -FileContent $content `
            -SourceFileLines $fileLines `
            -RegistrationCommandAst $registration.CommandAst `
            -FunctionName $functionName
        if (-not $helpContent) {
            continue
        }

        $parameterAsts = Get-RegistrationParameterAsts -RegistrationType $registration.Type -CommandAst $registration.CommandAst
        $parsedFunction = New-DynamicFunctionDocumentation `
            -FunctionName $functionName `
            -HelpContent $helpContent `
            -File $File `
            -ParameterAsts $parameterAsts

        if (-not $parsedFunction) {
            continue
        }

        $functions.Add($parsedFunction)
        if ($ExistingFunctionNames) {
            [void]$ExistingFunctionNames.Add($functionName)
        }
    }

    return $functions
}

<#
.SYNOPSIS
    Back-compat wrapper around Parse-DynamicFunctionsFromFile.

.DESCRIPTION
    Preserves the original parser entry point used by older documentation code.

.PARAMETER File
    Path to the PowerShell file to parse.

.PARAMETER ExistingFunctionNames
    Function names already discovered via AST parsing.

.OUTPUTS
    System.Collections.Generic.List[PSCustomObject]

.EXAMPLE
    Parse-AgentModeFunctionsFromFile -File ./profile.d/git.ps1
#>
function Parse-AgentModeFunctionsFromFile {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        [Parameter(Mandatory)]
        [string]$File,

        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]]$ExistingFunctionNames
    )

    Parse-DynamicFunctionsFromFile @PSBoundParameters
}

Export-ModuleMember -Function @(
    'Parse-DynamicFunctionsFromFile'
    'Parse-AgentModeFunctionsFromFile'
    'Get-DynamicRegistrationCommands'
    'Get-RegistrationFunctionName'
)
