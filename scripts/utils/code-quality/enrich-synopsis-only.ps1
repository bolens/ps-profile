#Requires -Version 7.0
<#
.SYNOPSIS
    Adds .DESCRIPTION sections to comment help that only has .SYNOPSIS.

.DESCRIPTION
    Scans PowerShell files and inserts a .DESCRIPTION section derived from the
    existing .SYNOPSIS text when parameter documentation is present but no
    description section exists.
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

function Add-DescriptionToHelpBlock {
    param([string]$HelpBlock)

    if ($HelpBlock -notmatch '(?m)^\s*\.SYNOPSIS\s*$' -or $HelpBlock -cmatch '\.DESCRIPTION') {
        return $HelpBlock
    }

    if ($HelpBlock -notmatch '(?ms)^\s*\.SYNOPSIS\s*\r?\n(?<synopsis>(?:\s+.+\r?\n)+)') {
        return $HelpBlock
    }

    $synopsis = ($matches['synopsis'] -replace '(?m)^\s+', '' -replace '\s+$', '').Trim()
    if ([string]::IsNullOrWhiteSpace($synopsis)) {
        return $HelpBlock
    }

    $descriptionBody = ($synopsis -split '\r?\n' | ForEach-Object { "    $_" }) -join "`n"
    $insert = ".DESCRIPTION`n$descriptionBody`n"

    return ($HelpBlock -replace '(?ms)(^\s*\.SYNOPSIS\s*\r?\n(?:\s+.+\r?\n)+)', "`$1$insert")
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
            $enrichedInner = Add-DescriptionToHelpBlock -HelpBlock $inner
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
