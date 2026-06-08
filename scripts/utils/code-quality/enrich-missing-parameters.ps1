#Requires -Version 7.0
<#
.SYNOPSIS
    Adds .PARAMETER and .EXAMPLE sections inferred from function param blocks.

.DESCRIPTION
    Scans PowerShell files and appends .PARAMETER and .EXAMPLE sections when a
    function has a param block but its comment help is missing those sections.
#>
param(
    [Parameter(Mandatory)]
    [string[]]$Path
)

$script:EnrichmentSkipFileNames = @(
    'enrich-missing-examples.ps1'
    'enrich-missing-parameters.ps1'
    'enrich-synopsis-only.ps1'
    'scan-shallow-help.ps1'
    'add-comment-help.ps1'
    'CommentHelp.psm1'
    'DocParserRegex.psm1'
)

function Get-ParameterHelpLines {
    <#
    .SYNOPSIS
        Builds .PARAMETER help lines from a function AST param block.

    .DESCRIPTION
        Generates placeholder parameter documentation for each declared parameter.

    .PARAMETER FuncAst
        Parsed function definition AST.

    .EXAMPLE
        Get-ParameterHelpLines -FuncAst $funcAst
    #>
    param(
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst
    )

    if (-not $FuncAst.Body.ParamBlock) {
        return @()
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($paramAst in $FuncAst.Body.ParamBlock.Parameters) {
        $paramName = $paramAst.Name.VariablePath.UserPath
        $lines.Add(".PARAMETER $paramName")
        $lines.Add("    $paramName parameter.")
    }

    return $lines
}

function Add-ParameterDocsToHelpBlock {
    <#
    .SYNOPSIS
        Appends missing .PARAMETER and .EXAMPLE sections to a help block.

    .DESCRIPTION
        Infers parameter documentation from the function AST when help is incomplete.

    .PARAMETER HelpBlock
        Comment-based help inner text without the surrounding &lt;# #&gt; delimiters.

    .PARAMETER FunctionName
        Function name used to generate a representative example command.

    .PARAMETER FuncAst
        Parsed function definition AST.

    .EXAMPLE
        Add-ParameterDocsToHelpBlock -HelpBlock $inner -FunctionName 'Invoke-Pip' -FuncAst $funcAst
    #>
    param(
        [string]$HelpBlock,
        [string]$FunctionName,
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst
    )

    $paramCount = if ($FuncAst.Body.ParamBlock) { @($FuncAst.Body.ParamBlock.Parameters).Count } else { 0 }
    if ($paramCount -eq 0) {
        return $HelpBlock
    }

    $hasParamDocs = $HelpBlock -match '(?m)^\s*\.PARAMETER\s+'
    $hasExamples = $HelpBlock -match '(?m)^\s*\.EXAMPLE\s*$'
    if ($hasParamDocs -and $hasExamples) {
        return $HelpBlock
    }

    $append = [System.Collections.Generic.List[string]]::new()
    if (-not $hasParamDocs) {
        foreach ($line in (Get-ParameterHelpLines -FuncAst $FuncAst)) {
            $append.Add($line) | Out-Null
        }
    }

    if (-not $hasExamples) {
        $exampleLine = switch -Regex ($FunctionName) {
            '^Invoke-' { "    $FunctionName -Arguments @('-h')" }
            '^Get-' { "    $FunctionName" }
            '^New-' { "    $FunctionName" }
            '^Add-' { "    $FunctionName" }
            '^Sync-' { "    $FunctionName" }
            '^Install-' { "    $FunctionName 'package-name'" }
            default { "    $FunctionName" }
        }
        $append.Add('.EXAMPLE')
        $append.Add($exampleLine)
    }

    if ($append.Count -eq 0) {
        return $HelpBlock
    }

    return ($HelpBlock.TrimEnd() + "`n" + ($append -join "`n") + "`n")
}

foreach ($targetPath in $Path) {
    if (-not (Test-Path -LiteralPath $targetPath)) {
        continue
    }

    $files = if ((Get-Item -LiteralPath $targetPath).PSIsContainer) {
        Get-ChildItem -Path $targetPath -Recurse -Include '*.ps1', '*.psm1' -File
    }
    else {
        , (Get-Item -LiteralPath $targetPath)
    }

    foreach ($file in $files) {
        if ($script:EnrichmentSkipFileNames -contains $file.Name -or $file.Name -like 'Doc*.psm1') {
            continue
        }

        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }

        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
        $replacements = [System.Collections.Generic.List[object]]::new()

        foreach ($funcAst in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
            $funcName = $funcAst.Name -replace '^.*:', ''
            $helpStart = 0
            $helpEnd = 0
            $help = $null

            $bodyText = $content.Substring($funcAst.Body.Extent.StartOffset, $funcAst.Body.Extent.EndOffset - $funcAst.Body.Extent.StartOffset)
            $bodyMatch = [regex]::Match($bodyText, '<#[\s\S]*?#>')
            if ($bodyMatch.Success) {
                $helpStart = $funcAst.Body.Extent.StartOffset + $bodyMatch.Index
                $helpEnd = $helpStart + $bodyMatch.Length
                $help = $bodyMatch.Value
            }
            else {
                $before = $content.Substring(0, $funcAst.Extent.StartOffset)
                $beforeMatches = [regex]::Matches($before, '<#[\s\S]*?#>')
                if ($beforeMatches.Count -eq 0) {
                    continue
                }

                $last = $beforeMatches[$beforeMatches.Count - 1]
                $helpStart = $last.Index
                $helpEnd = $helpStart + $last.Length
                $help = $last.Value
            }

            $inner = ($help -replace '^<#\s*', '' -replace '\s*#>$', '').Trim()
            $enrichedInner = Add-ParameterDocsToHelpBlock -HelpBlock $inner -FunctionName $funcName -FuncAst $funcAst
            if ($enrichedInner -eq $inner) {
                continue
            }

            $replacements.Add([PSCustomObject]@{
                    Start = $helpStart
                    End   = $helpEnd
                    Text  = "<#`n$enrichedInner`n#>"
                })
        }

        if ($replacements.Count -eq 0) {
            continue
        }

        $updated = $content
        foreach ($replacement in ($replacements | Sort-Object -Property Start -Descending)) {
            $updated = $updated.Substring(0, $replacement.Start) + $replacement.Text + $updated.Substring($replacement.End)
        }

        Set-Content -LiteralPath $file.FullName -Value $updated -Encoding UTF8 -NoNewline
        Write-Host "Updated: $($file.FullName) ($($replacements.Count) blocks)"
    }
}
