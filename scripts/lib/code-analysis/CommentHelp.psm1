<#
scripts/lib/CommentHelp.psm1

.SYNOPSIS
    Comment-based help extraction utilities.

.DESCRIPTION
    Provides functions for extracting and parsing comment-based help blocks from PowerShell files.
    This module centralizes the logic for finding comment blocks before functions and checking
    if they contain proper help documentation.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import dependencies
$regexModulePath = Join-Path $PSScriptRoot 'RegexUtilities.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $regexModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($regexModulePath -and -not [string]::IsNullOrWhiteSpace($regexModulePath) -and (Test-Path -LiteralPath $regexModulePath)) {
        Import-Module $regexModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Finds comment blocks before a function definition.

.DESCRIPTION
    Searches the text before a function definition for comment blocks (multiline comments).
    Returns the last comment block found, which is typically the comment-based help.

.PARAMETER BeforeText
    The text content that appears before the function definition.

.PARAMETER AllBlocks
    If specified, returns all comment blocks found, not just the last one.

.OUTPUTS
    System.Text.RegularExpressions.Match or System.Text.RegularExpressions.Match[].
    The comment block match(es) found.

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $content = Get-Content -Path "script.ps1" -Raw
    $functions = Get-FunctionsFromAst -Ast $ast
    foreach ($func in $functions) {
        $beforeText = Get-TextBeforeFunction -FuncAst $func -Content $content
        $commentBlock = Get-CommentBlockBeforeFunction -BeforeText $beforeText
        if ($commentBlock) {
            Write-Output "Found help for $($func.Name)"
        }
    }
#>
function Get-CommentBlockBeforeFunction {
    [CmdletBinding()]
    [OutputType([System.Text.RegularExpressions.Match])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$BeforeText,

        [switch]$AllBlocks
    )

    if (-not (Get-Command Get-CommonRegexPatterns -ErrorAction SilentlyContinue)) {
        # Fallback: create regex inline if RegexUtilities not available
        $commentRegex = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }
    else {
        $patterns = Get-CommonRegexPatterns
        $commentRegex = $patterns['CommentBlock']
    }

    $matches = $commentRegex.Matches($BeforeText)

    if ($matches.Count -eq 0) {
        return $null
    }

    if ($AllBlocks) {
        return $matches
    }

    # Return the last comment block (closest to the function)
    $lastIndex = $matches.Count - 1
    return $matches[$lastIndex]
}

<#
.SYNOPSIS
    Checks if a comment block contains comment-based help.

.DESCRIPTION
    Determines if a comment block contains proper comment-based help by checking
    for the presence of .SYNOPSIS or .DESCRIPTION sections.

.PARAMETER CommentBlock
    The comment block text (with or without comment markers).

.OUTPUTS
System.Boolean. True if the comment block contains help documentation.

.EXAMPLE
$commentBlock = Get-CommentBlockBeforeFunction -BeforeText $beforeText
if ($commentBlock -and (Test-CommentBlockHasHelp -CommentBlock $commentBlock.Value)) {
    Write-Output "Function has proper help documentation"
}
#>
function Test-CommentBlockHasHelp {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$CommentBlock
    )

    # Check if it contains SYNOPSIS or DESCRIPTION (case-sensitive)
    return $CommentBlock -cmatch '\.SYNOPSIS|\.DESCRIPTION'
}

<#
.SYNOPSIS
    Extracts comment-based help content from a comment block.

.DESCRIPTION
    Extracts and normalizes the help content from a comment block by removing
    comment markers and normalizing whitespace and indentation.

.PARAMETER CommentBlock
    The comment block text (with comment markers).

.OUTPUTS
    System.String. The normalized help content.

.EXAMPLE
    $commentBlock = Get-CommentBlockBeforeFunction -BeforeText $beforeText
    if ($commentBlock) {
        $helpContent = Get-HelpContentFromCommentBlock -CommentBlock $commentBlock.Value
        # Parse $helpContent for .SYNOPSIS, .DESCRIPTION, etc.
    }
#>
function Get-HelpContentFromCommentBlock {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$CommentBlock
    )

    # Remove the comment markers
    $helpContent = $CommentBlock -replace '^<#\s*', '' -replace '\s*#>$', ''

    # Trim leading/trailing whitespace
    $helpContent = $helpContent.Trim()

    # Remove carriage returns
    $helpContent = $helpContent -replace '\r', ''

    # Normalize indentation by removing common leading spaces
    $lines = $helpContent -split "\r?\n"
    $nonEmptyLines = $lines | Where-Object { $_ -match '\S' }
    if ($nonEmptyLines.Count -gt 0) {
        $minIndent = ($nonEmptyLines | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
        if ($minIndent -gt 0) {
            $lines = $lines | ForEach-Object {
                if ($_.Length -ge $minIndent) {
                    $_.Substring($minIndent)
                }
                else {
                    $_
                }
            }
        }
    }
    $helpContent = $lines -join "`n"

    return $helpContent
}

<#
.SYNOPSIS
    Checks if a function has comment-based help.

.DESCRIPTION
    Checks if a function definition has comment-based help by examining the text
    before the function and optionally at the beginning of the function body.

.PARAMETER FuncAst
    The FunctionDefinitionAst node.

.PARAMETER Content
    The full file content as a string.

.PARAMETER CheckBody
    If specified, also checks for comment blocks at the beginning of the function body.

.OUTPUTS
    System.Boolean. True if the function has comment-based help.

.EXAMPLE
    $ast = Get-PowerShellAst -Path "script.ps1"
    $content = Get-Content -Path "script.ps1" -Raw
    $functions = Get-FunctionsFromAst -Ast $ast
    foreach ($func in $functions) {
        if (Test-FunctionHasHelp -FuncAst $func -Content $content) {
            Write-Output "$($func.Name) has help"
        }
    }
#>
function Test-FunctionHasHelp {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst,

        [Parameter(Mandatory)]
        [string]$Content,

        [switch]$CheckBody
    )

    # Check for comment-based help before the function
    $beforeText = $null
    try {
        if (Get-Command Get-TextBeforeFunction -ErrorAction SilentlyContinue) {
            $beforeText = Get-TextBeforeFunction -FuncAst $FuncAst -Content $Content
        }
        else {
            # Fallback: calculate beforeText manually
            $start = $FuncAst.Extent.StartOffset
            if ($start -gt 0) {
                $beforeText = $Content.Substring(0, $start)
            }
            else {
                $beforeText = ""
            }
        }
    }
    catch {
        # If Get-TextBeforeFunction fails, try manual calculation
        $start = $FuncAst.Extent.StartOffset
        if ($start -gt 0) {
            $beforeText = $Content.Substring(0, $start)
        }
        else {
            $beforeText = ""
        }
    }

    if ($null -eq $beforeText) {
        $beforeText = ""
    }

    $commentBlock = Get-CommentBlockBeforeFunction -BeforeText $beforeText

    if ($commentBlock -and (Test-CommentBlockHasHelp -CommentBlock $commentBlock.Value)) {
        return $true
    }

    # Optionally check at the beginning of the function body
    if ($CheckBody -and $FuncAst.Body -and $FuncAst.Body.Extent) {
        $bodyStart = $FuncAst.Body.Extent.StartOffset
        $bodyEnd = $FuncAst.Body.Extent.EndOffset
        $bodyText = $Content.Substring($bodyStart, $bodyEnd - $bodyStart)

        # Look for comment block at the beginning of the body
        if (-not (Get-Command Get-CommonRegexPatterns -ErrorAction SilentlyContinue)) {
            $multilineCommentRegex = [regex]::new('^[\s]*<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        else {
            $patterns = Get-CommonRegexPatterns
            $multilineCommentRegex = $patterns['CommentBlockMultiline']
        }

        $bodyCommentMatches = $multilineCommentRegex.Matches($bodyText)
        if ($bodyCommentMatches.Count -gt 0) {
            $helpContent = $bodyCommentMatches[0].Value
            if (Test-CommentBlockHasHelp -CommentBlock $helpContent) {
                return $true
            }
        }
    }

    return $false
}

Export-ModuleMember -Function @(
    'Get-CommentBlockBeforeFunction',
    'Test-CommentBlockHasHelp',
    'Get-HelpContentFromCommentBlock',
    'Test-FunctionHasHelp'
)

