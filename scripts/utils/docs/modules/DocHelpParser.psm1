<#
scripts/utils/docs/modules/DocHelpParser.psm1

.SYNOPSIS
    Shared comment-based help parsing for documentation generators.

.DESCRIPTION
    Normalizes comment blocks and extracts structured help sections used by
    function and Set-AgentModeFunction documentation parsers.
#>

$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Strips comment markers and normalizes indentation in a help block.

.DESCRIPTION
    Removes the opening and closing comment delimiters, trims whitespace, and
    dedents lines so structured help sections can be parsed consistently.

.PARAMETER CommentBlock
    Raw comment block text including &lt;# and #&gt; delimiters.

.OUTPUTS
    System.String

.EXAMPLE
    Normalize-CommentHelpBlock -CommentBlock $commentBlock
#>
function Normalize-CommentHelpBlock {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$CommentBlock
    )

    $helpContent = $CommentBlock -replace '^<#\s*', '' -replace '\s*#>$', ''
    $helpContent = $helpContent.Trim()
    $helpContent = $helpContent -replace '\r', ''

    $lines = $helpContent -split "\r?\n"
    $minIndent = ($lines | Where-Object { $_ -match '\S' } | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
    if ($minIndent -gt 0) {
        $lines = $lines | ForEach-Object { if ($_.Length -ge $minIndent) { $_.Substring($minIndent) } else { $_ } }
    }

    return ($lines -join "`n")
}

function ConvertFrom-CommentHelpContent {
    <#
    .SYNOPSIS
        Parses normalized comment-based help into documentation fields.

    .DESCRIPTION
        Extracts synopsis, description, parameters, examples, outputs, notes,
        inputs, and links from normalized help text. Parameter metadata is
        enriched from AST nodes when supplied.

    .PARAMETER HelpContent
        Normalized comment-based help inner text.

    .PARAMETER ParameterAsts
        Optional parameter AST nodes used to enrich parameter metadata.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        ConvertFrom-CommentHelpContent -HelpContent $help -ParameterAsts $params
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$HelpContent,

        [System.Management.Automation.Language.ParameterAst[]]$ParameterAsts
    )

    $parameters = [System.Collections.Generic.List[PSCustomObject]]::new()
    $examples = [System.Collections.Generic.List[string]]::new()
    $links = [System.Collections.Generic.List[string]]::new()

    $synopsis = ''
    $description = ''
    $outputs = ''
    $notes = ''
    $inputs = ''

    if ($HelpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.(?:DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
        $synopsis = $matches[1].Trim()
    }

    if ($HelpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
        $description = $matches[1].Trim()
        $description = $description -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    $paramMatches = $script:regexParameter.Matches($HelpContent)
    foreach ($paramMatch in $paramMatches) {
        $paramName = $paramMatch.Groups[1].Value
        $paramDesc = $paramMatch.Groups[2].Value.Trim()
        $paramDesc = $paramDesc -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '

        $paramDetail = $null
        if ($ParameterAsts) {
            foreach ($paramAst in $ParameterAsts) {
                if ($paramAst.Name.VariablePath.UserPath -eq $paramName) {
                    $paramType = if ($paramAst.StaticType) { "[$($paramAst.StaticType.Name)]" } else { '' }
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
                Type        = if ($paramDetail) { $paramDetail.Type } else { '' }
                Mandatory   = if ($paramDetail) { $paramDetail.Mandatory } else { $false }
                Pipeline    = if ($paramDetail) { $paramDetail.Pipeline } else { $false }
                Position    = if ($paramDetail) { $paramDetail.Position } else { $null }
            })
    }

    $exampleMatches = $script:regexExample.Matches($HelpContent)
    foreach ($exampleMatch in $exampleMatches) {
        $examples.Add($exampleMatch.Groups[1].Value.Trim())
    }

    if ($HelpContent -match '(?s)\.OUTPUTS\s*\n\s*(.+?)(?=\n\s*\.(?:NOTES|INPUTS|LINK)|$)') {
        $outputs = $matches[1].Trim()
        $outputs = $outputs -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    if ($HelpContent -match '(?s)\.NOTES\s*\n\s*(.+?)(?=\n\s*\.(?:INPUTS|LINK)|$)') {
        $notes = $matches[1].Trim()
        $notes = $notes -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    if ($HelpContent -match '(?s)\.INPUTS\s*\n\s*(.+?)(?=\n\s*\.(?:LINK)|$)') {
        $inputs = $matches[1].Trim()
        $inputs = $inputs -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
    }

    $linkMatches = $script:regexLink.Matches($HelpContent)
    foreach ($linkMatch in $linkMatches) {
        $links.Add($linkMatch.Groups[1].Value.Trim())
    }

    return [PSCustomObject]@{
        Synopsis    = $synopsis
        Description = $description
        Parameters  = $parameters
        Examples    = $examples
        Outputs     = $outputs
        Notes       = $notes
        Inputs      = $inputs
        Links       = $links
    }
}

<#
.SYNOPSIS
    Builds a display signature for a documented function.

.DESCRIPTION
    Combines the function name with typed parameter names for API documentation.

.PARAMETER FunctionName
    Name of the function.

.PARAMETER ParameterAsts
    Optional parameter AST nodes from the function definition.

.OUTPUTS
    System.String

.EXAMPLE
    Build-FunctionSignature -FunctionName 'Get-Example' -ParameterAsts $params
#>
function Build-FunctionSignature {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [System.Management.Automation.Language.ParameterAst[]]$ParameterAsts
    )

    $signature = $FunctionName
    if ($ParameterAsts -and $ParameterAsts.Count -gt 0) {
        $paramList = foreach ($paramAst in $ParameterAsts) {
            $paramName = $paramAst.Name.VariablePath.UserPath
            $paramType = if ($paramAst.StaticType) { "[$($paramAst.StaticType.Name)]" } else { '' }
            "$paramType`$$paramName"
        }
        if ($paramList) {
            $signature += ' ' + ($paramList -join ', ')
        }
    }

    return $signature
}

<#
.SYNOPSIS
    Determines whether comment text is decorative rather than documentation.

.DESCRIPTION
    Returns true for separator lines, section labels, arrows, and other text
    that should not be treated as synopsis or description content.

.PARAMETER Text
    Comment text to evaluate.

.OUTPUTS
    System.Boolean

.EXAMPLE
    Test-DecorativeCommentText -Text '---'
#>
function Test-DecorativeCommentText {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $true
    }

    if ($Text -match '^[-=\s\.]+$') {
        return $true
    }

    if ($Text -match '^[A-Za-z ]+:$') {
        return $true
    }

    if ($Text -eq '>' -or $Text -eq '<') {
        return $true
    }

    return $false
}

<#
.SYNOPSIS
    Creates minimal structured help from synopsis text.

.DESCRIPTION
    Builds a .SYNOPSIS and .DESCRIPTION block when only a short caption or
    single-line comment is available for a dynamic registration.

.PARAMETER Synopsis
    Synopsis text for the generated help block.

.PARAMETER Description
    Optional description text. Defaults to the synopsis when omitted.

.OUTPUTS
    System.String

.EXAMPLE
    ConvertTo-StructuredHelpFromSynopsis -Synopsis 'Git clone helper'
#>
function ConvertTo-StructuredHelpFromSynopsis {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Synopsis,

        [string]$Description
    )

    $synopsisText = $Synopsis.Trim()
    $descriptionText = if ($Description) { $Description.Trim() } else { $synopsisText }
    return ".SYNOPSIS`n    $synopsisText`n.DESCRIPTION`n    $descriptionText"
}

<#
.SYNOPSIS
    Extracts a function-specific bullet description from help text.

.DESCRIPTION
    Looks for markdown-style bullet lines that mention the function name and
    returns the trailing description text.

.PARAMETER HelpText
    Normalized help text to search.

.PARAMETER FunctionName
    Function name to match within bullet lines.

.OUTPUTS
    System.String

.EXAMPLE
    Get-FunctionBulletFromHelpText -HelpText $help -FunctionName 'Invoke-GitClone'
#>
function Get-SyntheticConversionRegistrationHelp {
    <#
    .SYNOPSIS
        Builds fallback help text for lazy conversion wrapper registrations.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    if ($FunctionName -match '^_') {
        return $null
    }

    if ($FunctionName -match '^Convert-([A-Za-z]+)$') {
        $unit = $matches[1]
        return ConvertTo-StructuredHelpFromSynopsis -Synopsis "Convert between $unit units"
    }

    if ($FunctionName -match '^ConvertFrom-(.+?)To([A-Za-z]+)$') {
        return ConvertTo-StructuredHelpFromSynopsis -Synopsis "Convert from $($matches[1]) to $($matches[2]) units"
    }

    if ($FunctionName -match '^ConvertTo-(.+?)From([A-Za-z]+)$') {
        return ConvertTo-StructuredHelpFromSynopsis -Synopsis "Convert to $($matches[1]) from $($matches[2]) units"
    }

    return $null
}

function Get-FunctionBulletFromHelpText {
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$HelpText,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    $escapedName = [regex]::Escape($FunctionName)
    $bulletPattern = "(?m)^\s*[-*]\s*$escapedName(?:\s*\([^)]+\))?\s*:\s*(.+)$"
    if ($HelpText -match $bulletPattern) {
        return $matches[1].Trim()
    }

    return $null
}

function Get-RegistrationHelpFromFileBlock {
    <#
    .SYNOPSIS
        Resolves help from a file-level comment block when local help is absent.

    .DESCRIPTION
        Scans file-level comment blocks for structured help or function bullets
        that describe the requested registration target.

    .PARAMETER FileContent
        Full file content as a string.

    .PARAMETER FunctionName
        Registered function name to locate within file-level help.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-RegistrationHelpFromFileBlock -FileContent $content -FunctionName 'Invoke-GitClone'
    #>
    param(
        [Parameter(Mandatory)]
        $FileContent,

        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    if ([string]::IsNullOrWhiteSpace([string]$FileContent) -or [string]::IsNullOrWhiteSpace($FunctionName)) {
        return $null
    }

    $commentMatches = $script:regexCommentBlock.Matches([string]$FileContent)
    if ($commentMatches.Count -eq 0) {
        return $null
    }

    $fileBlock = $null
    foreach ($match in $commentMatches) {
        $normalized = Normalize-CommentHelpBlock -CommentBlock $match.Value
        if ($normalized.Length -lt 40) {
            continue
        }

        $hasStructuredHelp = $normalized -match '(?m)^\s*\.(?:SYNOPSIS|DESCRIPTION)\s*$'
        $mentionsFunction = $normalized -match [regex]::Escape($FunctionName)
        if ($hasStructuredHelp -or $mentionsFunction) {
            $fileBlock = $normalized
            break
        }
    }

    if (-not $fileBlock) {
        return $null
    }

    $bulletText = Get-FunctionBulletFromHelpText -HelpText $fileBlock -FunctionName $FunctionName
    if ($bulletText) {
        return ConvertTo-StructuredHelpFromSynopsis -Synopsis $bulletText
    }

    $descriptionSection = ''
    if ($fileBlock -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
        $descriptionSection = $matches[1]
        $bulletText = Get-FunctionBulletFromHelpText -HelpText $descriptionSection -FunctionName $FunctionName
        if ($bulletText) {
            return ConvertTo-StructuredHelpFromSynopsis -Synopsis $bulletText
        }
    }

    $fileSynopsis = ''
    if ($fileBlock -match '(?m)^\s*\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.(?:DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
        $fileSynopsis = $matches[1].Trim()
    }

    if ($descriptionSection) {
        foreach ($line in ($descriptionSection -split "\r?\n")) {
            if ($line -match [regex]::Escape($FunctionName)) {
                $lineText = $line.Trim().TrimStart('-', '*').Trim()
                if ($lineText) {
                    return ConvertTo-StructuredHelpFromSynopsis -Synopsis $lineText -Description $descriptionSection.Trim()
                }
            }
        }
    }

    if ($fileBlock -notmatch '(?m)^\s*\.SYNOPSIS\s*$' -and $fileBlock -match [regex]::Escape($FunctionName)) {
        $lines = $fileBlock -split "\r?\n" | Where-Object { $_ -match '\S' }
        $matchingLine = $lines | Where-Object { $_ -match [regex]::Escape($FunctionName) } | Select-Object -First 1
        if ($matchingLine) {
            $synopsis = $matchingLine.Trim().TrimStart('#').Trim()
            $description = ($fileBlock -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' ').Trim()
            return ConvertTo-StructuredHelpFromSynopsis -Synopsis $synopsis -Description $description
        }
    }

    if ($fileSynopsis -and $descriptionSection -and $descriptionSection -match [regex]::Escape($FunctionName)) {
        return ConvertTo-StructuredHelpFromSynopsis -Synopsis $fileSynopsis -Description $descriptionSection.Trim()
    }

    return $null
}

function Get-RegistrationHelpContent {
    <#
    .SYNOPSIS
        Resolves comment-based help for dynamic function registrations.

    .DESCRIPTION
        Searches inline comments, nearby block comments, and file-level help to
        build structured help content for Set-AgentModeFunction registrations.

    .PARAMETER FileContent
        Full file content as a string.

    .PARAMETER SourceFileLines
        File content split into lines for proximity checks.

    .PARAMETER RegistrationCommandAst
        AST node for the registration command.

    .PARAMETER FunctionName
        Optional registered function name used for bullet matching.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-RegistrationHelpContent -FileContent $content -SourceFileLines $lines -RegistrationCommandAst $cmd -FunctionName 'Invoke-GitClone'
    #>
    param(
        [Parameter(Mandatory)]
        $FileContent,

        [Parameter(Mandatory)]
        $SourceFileLines,

        [Parameter(Mandatory)]
        $RegistrationCommandAst,

        [string]$FunctionName
    )

    $lineArray = @($SourceFileLines)
    if ($lineArray.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$FileContent)) {
        return $null
    }

    $commandStartOffset = $RegistrationCommandAst.Extent.StartOffset
    $commandLineIndex = $RegistrationCommandAst.Extent.StartLineNumber - 1
    $startLine = $RegistrationCommandAst.Extent.StartLineNumber
    $endLine = $RegistrationCommandAst.Extent.EndLineNumber

    for ($lineNumber = $endLine; $lineNumber -ge $startLine; $lineNumber--) {
        $line = $lineArray[$lineNumber - 1]
        $inlineMatch = $script:regexInlineComment.Match($line)
        if ($inlineMatch.Success) {
            $inlineText = $inlineMatch.Groups[1].Value.Trim()
            if (-not (Test-DecorativeCommentText -Text $inlineText)) {
                return ConvertTo-StructuredHelpFromSynopsis -Synopsis $inlineText
            }
        }
    }

    $beforeText = [string]$FileContent.Substring(0, $commandStartOffset)
    $commentMatches = $script:regexCommentBlock.Matches($beforeText)
    if ($commentMatches.Count -gt 0) {
        $lastMatch = $commentMatches[$commentMatches.Count - 1]
        $commandLine = ($beforeText.Substring(0, $commandStartOffset) -split "\r?\n").Count
        $commentEndLine = ($beforeText.Substring(0, $lastMatch.Index + $lastMatch.Length) -split "\r?\n").Count
        if (($commandLine - $commentEndLine) -le 3) {
            $blockHelp = Normalize-CommentHelpBlock -CommentBlock $lastMatch.Value
            if ($blockHelp -match '(?m)^\s*\.(?:SYNOPSIS|DESCRIPTION)\s*$') {
                if ($FunctionName) {
                    $bulletText = Get-FunctionBulletFromHelpText -HelpText $blockHelp -FunctionName $FunctionName
                    if ($bulletText) {
                        return ConvertTo-StructuredHelpFromSynopsis -Synopsis $bulletText
                    }

                    return $blockHelp
                }

                return $blockHelp
            }
        }
    }

    if ($FunctionName) {
        $commentMatches = $script:regexCommentBlock.Matches([string]$FileContent)
        foreach ($match in $commentMatches) {
            $normalized = Normalize-CommentHelpBlock -CommentBlock $match.Value
            $bulletText = Get-FunctionBulletFromHelpText -HelpText $normalized -FunctionName $FunctionName
            if ($bulletText) {
                return ConvertTo-StructuredHelpFromSynopsis -Synopsis $bulletText
            }
        }
    }

    for ($lineIndex = $commandLineIndex - 1; $lineIndex -ge [Math]::Max(0, $commandLineIndex - 10); $lineIndex--) {
        $line = $lineArray[$lineIndex]
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $trimmedLine = $line.Trim()
        if ($trimmedLine -match '^\s*<#' -or $trimmedLine -match '^\s*#>\s*$') {
            break
        }

        $singleLineMatch = $script:regexSingleLineComment.Match($trimmedLine)
        if ($singleLineMatch.Success) {
            $singleLineText = $singleLineMatch.Groups[1].Value.Trim()
            if (-not (Test-DecorativeCommentText -Text $singleLineText)) {
                return ConvertTo-StructuredHelpFromSynopsis -Synopsis $singleLineText
            }
        }
    }

    if ($FunctionName) {
        $fileBlockHelp = Get-RegistrationHelpFromFileBlock -FileContent $FileContent -FunctionName $FunctionName
        if ($fileBlockHelp) {
            return $fileBlockHelp
        }

        $syntheticHelp = Get-SyntheticConversionRegistrationHelp -FunctionName $FunctionName
        if ($syntheticHelp) {
            return $syntheticHelp
        }
    }

    return $null
}

Export-ModuleMember -Function @(
    'Normalize-CommentHelpBlock'
    'ConvertFrom-CommentHelpContent'
    'Build-FunctionSignature'
    'Test-DecorativeCommentText'
    'ConvertTo-StructuredHelpFromSynopsis'
    'Get-RegistrationHelpFromFileBlock'
    'Get-RegistrationHelpContent'
    'Get-SyntheticConversionRegistrationHelp'
)
