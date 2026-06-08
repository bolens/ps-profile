#Requires -Version 7.0
<#
.SYNOPSIS
    Scans PowerShell files for shallow comment-based help blocks.

.DESCRIPTION
    Identifies functions whose comment-based help is missing key sections such as
    .DESCRIPTION, .PARAMETER, or .EXAMPLE documentation. Help may appear before the
    function or at the start of the function body.
#>
param(
    [string[]]$Path = @('profile.d', 'scripts'),
    [int]$MinIssues = 1,
    [int]$Limit = 200
)

$ErrorActionPreference = 'Stop'

$script:EnrichmentSkipFileNames = @(
    'enrich-missing-examples.ps1'
    'enrich-missing-parameters.ps1'
    'enrich-synopsis-only.ps1'
    'scan-shallow-help.ps1'
    'add-comment-help.ps1'
    'CommentHelp.psm1'
    'DocParserRegex.psm1'
    'RegexUtilities.psm1'
    'improve-bare-examples.ps1'
    'cleanup-help-examples.ps1'
    'reorder-comment-help.ps1'
)

function Get-FunctionHelpContent {
    param(
        [string]$Content,
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst
    )

    $bodyText = $Content.Substring(
        $FuncAst.Body.Extent.StartOffset,
        $FuncAst.Body.Extent.EndOffset - $FuncAst.Body.Extent.StartOffset)

    $bodyMatch = [regex]::Match($bodyText, '<#[\s\S]*?#>')
    if ($bodyMatch.Success) {
        return ($bodyMatch.Value -replace '^<#\s*', '' -replace '\s*#>$', '').Trim()
    }

    $before = if ($FuncAst.Extent.StartOffset -gt 0) {
        $Content.Substring(0, $FuncAst.Extent.StartOffset)
    }
    else {
        ''
    }

    $beforeMatches = [regex]::Matches($before, '<#[\s\S]*?#>')
    if ($beforeMatches.Count -eq 0) {
        return $null
    }

    return ($beforeMatches[$beforeMatches.Count - 1].Value -replace '^<#\s*', '' -replace '\s*#>$', '').Trim()
}

function Get-ShallowHelpIssues {
    param(
        [string]$HelpContent,
        [int]$ParamCount
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $hasSynopsis = $HelpContent -cmatch '\.SYNOPSIS'
    $hasDescription = $HelpContent -cmatch '\.DESCRIPTION'

    if ($hasSynopsis -and -not $hasDescription) {
        $issues.Add('synopsis-only')
    }

    if (-not $hasSynopsis -and -not $hasDescription) {
        $issues.Add('no-structured-help')
    }

    if ($hasDescription) {
        if ($HelpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
            $desc = $matches[1].Trim()
            if ($desc.Length -lt 25) {
                $issues.Add('short-description')
            }
        }
    }

    if ($ParamCount -gt 0) {
        $paramDocs = ([regex]::Matches($HelpContent, '(?m)^\s*\.PARAMETER\s+')).Count
        if ($paramDocs -eq 0) {
            $issues.Add('missing-parameter-docs')
        }

        $exampleDocs = ([regex]::Matches($HelpContent, '(?m)^\s*\.EXAMPLE\s*$')).Count
        if ($exampleDocs -eq 0) {
            $issues.Add('missing-examples')
        }
    }

    return $issues
}

$repoRoot = (Get-Location).Path
$results = [System.Collections.Generic.List[object]]::new()

foreach ($base in $Path) {
    if (-not (Test-Path -LiteralPath $base)) {
        continue
    }

    Get-ChildItem -Path $base -Recurse -Include '*.ps1', '*.psm1' -File | ForEach-Object {
        if ($script:EnrichmentSkipFileNames -contains $_.Name -or $_.Name -like 'Doc*.psm1') {
            return
        }

        $rel = $_.FullName.Substring($repoRoot.Length + 1)
        $content = Get-Content -LiteralPath $_.FullName -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            return
        }

        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
            $funcs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)

            foreach ($funcAst in $funcs) {
                $help = Get-FunctionHelpContent -Content $content -FuncAst $funcAst
                if (-not $help -or $help -notmatch '\.SYNOPSIS|\.DESCRIPTION') {
                    continue
                }

                $paramCount = if ($funcAst.Body.ParamBlock) { @($funcAst.Body.ParamBlock.Parameters).Count } else { 0 }
                $issues = Get-ShallowHelpIssues -HelpContent $help -ParamCount $paramCount

                if ($issues.Count -ge $MinIssues) {
                    $results.Add([PSCustomObject]@{
                            File     = $rel
                            Function = $funcAst.Name
                            Issues   = ($issues -join ', ')
                            Params   = $paramCount
                            Score    = $issues.Count
                        })
                }
            }
        }
        catch {
            # Skip unparseable files
        }
    }
}

$results |
    Sort-Object -Property @{ Expression = 'Score'; Descending = $true }, 'File' |
    Select-Object -First $Limit |
    Format-Table -AutoSize

Write-Host "Total shallow ($MinIssues+ issues): $($results.Count)"

$results | Group-Object -Property Issues | Sort-Object -Property Count -Descending | Select-Object -First 20 Name, Count
