<#
scripts/checks/check-comment-help.ps1

Check that all functions in profile.d/*.ps1 fragments have comment-based help.
This ensures the automated documentation generator can create complete docs.

Usage:
  pwsh -NoProfile -File scripts\checks\check-comment-help.ps1
#>

param(
    [switch]$Verbose
)

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fragDir = Join-Path $root 'profile.d'
$psFiles = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name

$issueCount = 0

function Get-FunctionsWithoutCommentHelp($path) {
    $content = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return @() }

    $undocumented = @()

    # Use AST to find all function definitions
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
        $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

        foreach ($funcAst in $functionAsts) {
            $functionName = $funcAst.Name

            # Skip functions with colons (like global:..) as they are internal aliases
            if ($functionName -match ':') {
                continue
            }

            $hasHelp = $false

            # Check for comment-based help before the function
            $start = $funcAst.Extent.StartOffset
            $beforeText = $content.Substring(0, $start)
            $commentMatches = [regex]::Matches($beforeText, '<#[\s\S]*?#>')
            if ($commentMatches.Count -gt 0) {
                $helpContent = $commentMatches[-1].Value  # Last comment block
                # Check if it contains SYNOPSIS or DESCRIPTION
                if ($helpContent -match '\.SYNOPSIS|\.DESCRIPTION') {
                    $hasHelp = $true
                }
            }

            # Also check for comment-based help at the beginning of the function body
            if (-not $hasHelp -and $funcAst.Body -and $funcAst.Body.Extent) {
                $bodyStart = $funcAst.Body.Extent.StartOffset
                $bodyEnd = $funcAst.Body.Extent.EndOffset
                $bodyText = $content.Substring($bodyStart, $bodyEnd - $bodyStart)

                # Look for comment block at the beginning of the body
                $bodyCommentMatches = [regex]::Matches($bodyText, '^[\s]*<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                if ($bodyCommentMatches.Count -gt 0) {
                    $helpContent = $bodyCommentMatches[0].Value
                    if ($helpContent -match '\.SYNOPSIS|\.DESCRIPTION') {
                        $hasHelp = $true
                    }
                }
            }

            if (-not $hasHelp) {
                $undocumented += $functionName
            }
        }
    }
    catch {
        Write-Warning "Failed to parse $($path): $($_.Exception.Message)"
    }

    return $undocumented
}

Write-Output "Checking that all functions have comment-based help in $fragDir"

foreach ($ps in $psFiles) {
    $undocumentedFuncs = Get-FunctionsWithoutCommentHelp $ps.FullName

    if ($undocumentedFuncs.Count -gt 0) {
        $issueCount++
        Write-Output "MISSING HELP: $($ps.Name)"
        Write-Output "  Functions without comment-based help: $([string]::Join(', ', $undocumentedFuncs))"
        Write-Output ""
    }
    elseif ($Verbose) {
        Write-Output "OK: $($ps.Name)"
    }
}

if ($issueCount -gt 0) {
    Write-Output "Found $issueCount fragments with functions missing comment-based help."
    exit 2
}
else {
    Write-Output "All functions have comment-based help."
    exit 0
}
