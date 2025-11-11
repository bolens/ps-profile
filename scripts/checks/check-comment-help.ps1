<#
scripts/checks/check-comment-help.ps1

.SYNOPSIS
    Checks that all functions in profile.d fragments have comment-based help.

.DESCRIPTION
    Checks that all functions in profile.d/*.ps1 fragments have comment-based help.
    This ensures the automated documentation generator can create complete docs.
    Scans all PowerShell files in the profile.d directory and reports any functions
    that are missing comment-based help blocks.

.PARAMETER Verbose
    If specified, outputs detailed information about each function checked.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-comment-help.ps1

    Checks all functions in profile.d for comment-based help.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-comment-help.ps1 -Verbose

    Checks all functions with verbose output.
#>

param(
    [switch]$Verbose
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utils' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $fragDir = Join-Path $repoRoot 'profile.d'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$psFiles = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name

# Compile regex patterns once for better performance
$regexCommentBlock = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexCommentBlockMultiline = [regex]::new('^[\s]*<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)

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
            $commentMatches = $regexCommentBlock.Matches($beforeText)
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
                $bodyCommentMatches = $regexCommentBlockMultiline.Matches($bodyText)
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
        Write-ScriptMessage -Message "Failed to parse $($path): $($_.Exception.Message)" -IsWarning
    }

    return $undocumented
}

Write-ScriptMessage -Message "Checking that all functions have comment-based help in $fragDir"

foreach ($ps in $psFiles) {
    $undocumentedFuncs = Get-FunctionsWithoutCommentHelp $ps.FullName

    if ($undocumentedFuncs.Count -gt 0) {
        $issueCount++
        Write-ScriptMessage -Message "MISSING HELP: $($ps.Name)"
        Write-ScriptMessage -Message "  Functions without comment-based help: $([string]::Join(', ', $undocumentedFuncs))"
        Write-ScriptMessage -Message ""
    }
    elseif ($Verbose) {
        Write-ScriptMessage -Message "OK: $($ps.Name)"
    }
}

if ($issueCount -gt 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $issueCount fragments with functions missing comment-based help."
}
else {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "All functions have comment-based help."
}

