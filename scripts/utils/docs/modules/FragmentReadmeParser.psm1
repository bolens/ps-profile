<#
scripts/utils/docs/modules/FragmentReadmeParser.psm1

.SYNOPSIS
    Fragment README parsing utilities.

.DESCRIPTION
    Provides functions for parsing PowerShell fragments to extract purpose, functions, and helpers.
#>

# Import regex patterns
$regexModulePath = Join-Path $PSScriptRoot 'FragmentReadmeRegex.psm1'
if (Test-Path $regexModulePath) {
    try {
        Import-Module $regexModulePath -DisableNameChecking -ErrorAction Stop -Force
        # Ensure regex patterns are available in script scope
        if (-not $script:regexCommentLine) {
            $script:regexCommentLine = [regex]::new('^\s*#\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        if (-not $script:regexFunction) {
            $script:regexFunction = [regex]::new('^\s*function\s+([A-Za-z0-9_\-\.\~]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        if (-not $script:regexDecorativeEquals) {
            $script:regexDecorativeEquals = [regex]::new('^# =+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        if (-not $script:regexDecorativeDashes) {
            $script:regexDecorativeDashes = [regex]::new('^# -+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        if (-not $script:regexMultilineCommentStart) {
            $script:regexMultilineCommentStart = [regex]::new('^\s*<#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        if (-not $script:regexMultilineCommentEnd) {
            $script:regexMultilineCommentEnd = [regex]::new('^\s*#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
        if (-not $script:regexCommentStart) {
            $script:regexCommentStart = [regex]::new('^\s*#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        }
    }
    catch {
        Write-Warning "Failed to import regex patterns, using fallback: $($_.Exception.Message)"
        # Fallback: create regex patterns directly
        $script:regexCommentLine = [regex]::new('^\s*#\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $script:regexFunction = [regex]::new('^\s*function\s+([A-Za-z0-9_\-\.\~]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $script:regexDecorativeEquals = [regex]::new('^# =+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $script:regexDecorativeDashes = [regex]::new('^# -+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $script:regexMultilineCommentStart = [regex]::new('^\s*<#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $script:regexMultilineCommentEnd = [regex]::new('^\s*#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $script:regexCommentStart = [regex]::new('^\s*#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    }
}
else {
    # Create regex patterns directly if module not found
    $script:regexCommentLine = [regex]::new('^\s*#\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:regexFunction = [regex]::new('^\s*function\s+([A-Za-z0-9_\-\.\~]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:regexDecorativeEquals = [regex]::new('^# =+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:regexDecorativeDashes = [regex]::new('^# -+$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:regexMultilineCommentStart = [regex]::new('^\s*<#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:regexMultilineCommentEnd = [regex]::new('^\s*#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $script:regexCommentStart = [regex]::new('^\s*#', [System.Text.RegularExpressions.RegexOptions]::Compiled)
}

<#
.SYNOPSIS
    Extracts purpose from fragment header comments.

.DESCRIPTION
    Parses the first 60 lines of a fragment file to extract a purpose statement from comments.

.PARAMETER FilePath
    Path to the fragment file.

.OUTPUTS
    String. The extracted purpose, or a default message if none found.
#>
function Get-FragmentPurpose {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]$FileInfo
    )

    $headerLines = Get-Content -Path $FilePath -TotalCount 60 -ErrorAction SilentlyContinue
    $purpose = $null
    $skipFilename = $true
    $inMultilineComment = $false

    if ($headerLines) {
        foreach ($l in $headerLines) {
            $trim = $l.Trim()
            # Track multiline comment state
            if ($script:regexMultilineCommentStart.IsMatch($trim)) { $inMultilineComment = $true; continue }
            if ($script:regexMultilineCommentEnd.IsMatch($trim) -and $inMultilineComment) { $inMultilineComment = $false; continue }

            # Skip decorative lines
            if ($script:regexDecorativeEquals.IsMatch($trim) -or $script:regexDecorativeDashes.IsMatch($trim) -or $trim -eq '#') { continue }

            # Look for comment lines
            $m = $script:regexCommentLine.Match($trim)
            if ($m.Success -or
                ($inMultilineComment -and
                $trim -and
                -not $script:regexMultilineCommentStart.IsMatch($trim) -and
                -not $script:regexCommentStart.IsMatch($trim))) {
                $purposeText = if ($m.Success) { $m.Groups[1].Value } else { $trim }
                # Skip generic or decorative text
                if ($purposeText -notmatch '^=+$' -and $purposeText -notmatch '^-+$' -and $purposeText -notmatch '^\.+$') {
                    # Skip filename if it matches the actual filename
                    if ($skipFilename -and ($purposeText -eq $FileInfo.Name -or $purposeText -eq "profile.d/$($FileInfo.Name)")) {
                        $skipFilename = $false
                        continue
                    }
                    $purpose = $purposeText
                    break
                }
            }
        }
    }

    if (-not $purpose) {
        $purpose = "Small fragment: see file $($FileInfo.Name) for details."
    }

    return $purpose
}

<#
.SYNOPSIS
    Extracts function descriptions from comments above function declarations.

.DESCRIPTION
    Looks for comments up to 10 lines before a function declaration.

.PARAMETER AllLines
    Array of all lines in the file.

.PARAMETER FunctionIndex
    Index of the line containing the function declaration.

.OUTPUTS
    String. The extracted description, or $null if none found.
#>
function Get-FunctionDescription {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string[]]$AllLines,

        [Parameter(Mandatory)]
        [int]$FunctionIndex
    )

    $desc = $null
    $inMultilineComment = $false

    # First pass: determine if we're starting inside a multiline comment
    for ($k = $FunctionIndex - 1; $k -ge [Math]::Max(0, $FunctionIndex - 10); $k--) {
        $checkLine = $AllLines[$k].Trim()
        if ($script:regexMultilineCommentStart.IsMatch($checkLine)) { $inMultilineComment = $true; break }
        if ($script:regexMultilineCommentEnd.IsMatch($checkLine) -and $inMultilineComment) { $inMultilineComment = $false; break }
        # Only break on actual code lines, not content inside comments
        if ($checkLine -and
            -not $script:regexEmptyLine.IsMatch($checkLine) -and
            -not $script:regexCommentStart.IsMatch($checkLine) -and
            -not $script:regexIfStatement.IsMatch($checkLine) -and
            -not $inMultilineComment) {
            break
        }
    }

    # Second pass: extract comments
    for ($j = $FunctionIndex - 1; $j -ge [Math]::Max(0, $FunctionIndex - 10); $j--) {
        $up = $AllLines[$j].Trim()

        # Track multiline comment state
        if ($script:regexMultilineCommentStart.IsMatch($up)) { $inMultilineComment = $true; continue }
        if ($script:regexMultilineCommentEnd.IsMatch($up) -and $inMultilineComment) { $inMultilineComment = $false; continue }

        # Check for single-line comment lines above
        $dm = $script:regexCommentLine.Match($up)
        if ($dm.Success -and -not $inMultilineComment) {
            $descText = $dm.Groups[1].Value
            # Skip if this looks like a structured comment
            if ($descText -notmatch '^[-=\s]*$' -and $descText -notmatch '^[A-Za-z ]+:$' -and $descText.Length -lt 120) {
                $desc = $descText
                break
            }
        }
        # Check for content inside multiline comments
        elseif ($inMultilineComment -and
            $up -and
            -not $script:regexMultilineCommentStart.IsMatch($up) -and
            -not $script:regexCommentStart.IsMatch($up)) {
            # Extract the first meaningful line from multiline comment
            $descText = $up.Trim()
            # Skip function names, titles, decorative lines
            if ($descText -notmatch '^[-=\s]*$' -and
                $descText -notmatch '^[A-Za-z ]+:$' -and
                $descText -notmatch '^[A-Za-z0-9_\-]+$' -and
                $descText -notmatch '^-+$' -and
                $descText.Length -lt 120) {
                $desc = $descText
                break
            }
        }

        # Stop if we hit a non-comment, non-empty line
        if ($up -and
            -not $script:regexEmptyLine.IsMatch($up) -and
            -not $script:regexCommentStart.IsMatch($up) -and
            -not $script:regexIfStatement.IsMatch($up) -and
            -not $inMultilineComment) {
            break
        }
    }

    return $desc
}

<#
.SYNOPSIS
    Extracts functions from a fragment file.

.DESCRIPTION
    Parses a fragment file to extract function declarations and dynamically-created functions.

.PARAMETER FilePath
    Path to the fragment file.

.OUTPUTS
    List of PSCustomObject with Name and Short (description) properties.
#>
function Get-FragmentFunctions {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $functions = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        $allLines = Get-Content -Path $FilePath -ErrorAction SilentlyContinue

        # Extract top-level function declarations
        for ($i = 0; $i -lt $allLines.Count; $i++) {
            $line = $allLines[$i]
            # Match function declarations
            $fm = $script:regexFunction.Match($line)
            if ($fm.Success) {
                $fname = $fm.Groups[1].Value
                $desc = Get-FunctionDescription -AllLines $allLines -FunctionIndex $i
                $functions.Add([PSCustomObject]@{ Name = $fname; Short = $desc })
            }
        }

        # Detect dynamically-created functions
        for ($i = 0; $i -lt $allLines.Count; $i++) {
            $line = $allLines[$i]
            $ln = $line.Trim()
            $fname = $null
            $desc = $null

            # Check for different patterns of function creation
            if ($ln -match 'Set-AgentModeFunction\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)') {
                $fname = $matches[1]
            }
            elseif ($ln -match 'Set-AgentModeAlias\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)') {
                $fname = $matches[1]
            }
            elseif ($ln -match '(?:Set-Item|New-Item)\s+(?:-Path\s+)?Function:(?:global:)?([A-Za-z0-9_\-\.\~]+)') {
                $fname = $matches[1]
            }

            if ($fname) {
                $desc = Get-FunctionDescription -AllLines $allLines -FunctionIndex $i

                # If no comment found above, check for inline comment on the function line
                if (-not $desc) {
                    $functionLine = $allLines[$i].Trim()
                    $inlineMatch = $script:regexInlineComment.Match($functionLine)
                    if ($inlineMatch.Success) {
                        $inlineDesc = $inlineMatch.Groups[1].Value
                        # Skip decorative comments
                        if ($inlineDesc -notmatch '^[-=\s]*$' -and $inlineDesc -notmatch '^[A-Za-z ]+:$') {
                            $desc = $inlineDesc
                        }
                    }
                }

                # Only add if not already in the list
                if ($functions.Name -notcontains $fname) {
                    if (-not $desc) { $desc = 'dynamically-created; see fragment source' }
                    $functions.Add([PSCustomObject]@{ Name = $fname; Short = $desc })
                }
            }
        }
    }
    catch {
        # Graceful degradation - return empty list
    }

    return $functions
}

<#
.SYNOPSIS
    Detects Enable-* helper functions in a fragment.

.DESCRIPTION
    Scans a fragment file for Enable-* function declarations.

.PARAMETER FilePath
    Path to the fragment file.

.OUTPUTS
    Array of function names (strings).
#>
function Get-FragmentEnableHelpers {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $enableHelpers = @()
    try {
        $enableMatches = Select-String -Path $FilePath -Pattern 'function\s+Enable-[A-Za-z0-9_-]+' -AllMatches -ErrorAction SilentlyContinue
        foreach ($m in $enableMatches) {
            foreach ($mm in $m.Matches) {
                $enableHelpers += $mm.Value.Trim()
            }
        }
        $enableHelpers = $enableHelpers | Sort-Object -Unique
    }
    catch {
        # Graceful degradation - return empty array
    }

    return $enableHelpers
}

Export-ModuleMember -Function @(
    'Get-FragmentPurpose',
    'Get-FragmentFunctions',
    'Get-FragmentEnableHelpers'
)

