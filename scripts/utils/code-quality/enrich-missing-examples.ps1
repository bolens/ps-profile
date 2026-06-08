#Requires -Version 7.0
<#
.SYNOPSIS
    Adds .EXAMPLE sections to comment help blocks that already document parameters.

.DESCRIPTION
    Scans PowerShell files and appends a .EXAMPLE section when a function already
    documents parameters but has no standalone .EXAMPLE heading.
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

function Add-ExampleToHelpBlock {
    <#
    .SYNOPSIS
        Appends an .EXAMPLE section to a help block when parameters are documented.

    .DESCRIPTION
        Returns the original help block unchanged when parameters or examples are missing.

    .PARAMETER HelpBlock
        Comment-based help inner text without the surrounding &lt;# #&gt; delimiters.

    .PARAMETER FunctionName
        Function name used to generate a representative example command.

    .EXAMPLE
        Add-ExampleToHelpBlock -HelpBlock $inner -FunctionName 'Format-Json'
    #>
    param(
        [string]$HelpBlock,
        [string]$FunctionName
    )

    if ($HelpBlock -notmatch '(?m)^\s*\.PARAMETER\s+' -or $HelpBlock -match '(?m)^\s*\.EXAMPLE\s*$') {
        return $HelpBlock
    }

    $exampleLine = switch -Regex ($FunctionName) {
        '^Format-' { "    $FunctionName -InputObject (Get-Content ./data.json -Raw | ConvertFrom-Json)" }
        '^ConvertFrom-' { "    $FunctionName -InputPath ./input.file" }
        '^ConvertTo-' { "    $FunctionName -InputPath ./input.file" }
        default { "    $FunctionName" }
    }

    return ($HelpBlock.TrimEnd() + "`n.EXAMPLE`n$exampleLine`n")
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
            $help = $null
            $helpStart = 0
            $helpEnd = 0

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
            $enrichedInner = Add-ExampleToHelpBlock -HelpBlock $inner -FunctionName $funcName
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
