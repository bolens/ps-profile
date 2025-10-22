# scripts/generate-fragment-readmes.ps1

<#
Generate minimal README files for each profile.d/*.ps1 fragment. The script
extracts a short purpose line from the top-of-file comment block, detects
top-level functions and short comments above them, and mentions any
Enable-* helpers. Existing README files are preserved unless -Force is used.

Usage:
    pwsh -NoProfile -File scripts\generate-fragment-readmes.ps1 [-Force]
#>

param(
    [switch]$Force
)

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fragDir = Join-Path $root 'profile.d'
$psFiles = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name

foreach ($ps in $psFiles) {
    $mdPath = [System.IO.Path]::ChangeExtension($ps.FullName, '.README.md')
    if ((Test-Path $mdPath) -and (-not $Force)) { continue }

    # Try to read a header comment for a short purpose line
    $headerLines = Get-Content -Path $ps.FullName -TotalCount 60 -ErrorAction SilentlyContinue
    $purpose = $null
    $skipFilename = $true
    $inMultilineComment = $false
    if ($headerLines) {
        foreach ($l in $headerLines) {
            $trim = $l.Trim()
            # Track multiline comment state
            if ($trim -match '^\s*<#') { $inMultilineComment = $true; continue }
            if ($trim -match '^\s*#>' -and $inMultilineComment) { $inMultilineComment = $false; continue }
            
            # Skip decorative lines
            if ($trim -match '^# =+$' -or $trim -match '^# -+$' -or $trim -eq '#') { continue }
            
            # Look for comment lines (both single-line # and inside multiline comments)
            $m = [regex]::Match($trim, '^\s*#\s*(.+)$')
            if ($m.Success -or ($inMultilineComment -and $trim -and -not ($trim -match '^\s*<#') -and -not ($trim -match '^\s*#'))) {
                $purposeText = if ($m.Success) { $m.Groups[1].Value } else { $trim }
                # Skip generic or decorative text
                if ($purposeText -notmatch '^=+$' -and $purposeText -notmatch '^-+$' -and $purposeText -notmatch '^\.+$') {
                    # Skip filename if it matches the actual filename (with or without path prefix)
                    if ($skipFilename -and ($purposeText -eq $ps.Name -or $purposeText -eq "profile.d/$($ps.Name)")) {
                        $skipFilename = $false
                        continue
                    }
                    $purpose = $purposeText
                    break
                }
            }
        }
    }

    if (-not $purpose) { $purpose = "Small fragment: see file $($ps.Name) for details." }

    # Detect any Enable-* helpers defined in the fragment so we can mention them
    $enableHelpers = @()
    try {
        $enableMatches = Select-String -Path $ps.FullName -Pattern 'function\s+Enable-[A-Za-z0-9_-]+' -AllMatches -ErrorAction SilentlyContinue
        foreach ($m in $enableMatches) { foreach ($mm in $m.Matches) { $enableHelpers += $mm.Value.Trim() } }
        $enableHelpers = $enableHelpers | Sort-Object -Unique
    } catch {}

    # Extract top-level function declarations and a short comment above them (if present)
    $functions = @()
    try {
        $allLines = Get-Content -Path $ps.FullName -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $allLines.Count; $i++) {
            $line = $allLines[$i]
            # Match function declarations (not in comments), including those inside conditional blocks
            $fm = [regex]::Match($line, '^\s*function\s+([A-Za-z0-9_\-]+)\b')
            if ($fm.Success) {
                $fname = $fm.Groups[1].Value
                $desc = $null
                # Look for comments above the function (up to 10 lines back)
                $inMultilineComment = $false
                # First pass: determine if we're starting inside a multiline comment
                for ($k = $i - 1; $k -ge [Math]::Max(0, $i - 10); $k--) {
                    $checkLine = $allLines[$k].Trim()
                    if ($checkLine -match '^\s*<#') { $inMultilineComment = $true; break }
                    if ($checkLine -match '^\s*#>' -and $inMultilineComment) { $inMultilineComment = $false; break }
                    # Only break on actual code lines, not content inside comments
                    if ($checkLine -and -not ($checkLine -match '^\s*$') -and -not ($checkLine -match '^\s*#') -and -not ($checkLine -match '^\s*if\s*\(') -and -not $inMultilineComment) { break }
                }
                # Second pass: extract comments
                for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 10); $j--) {
                    $up = $allLines[$j].Trim()
                    
                    # Track multiline comment state
                    if ($up -match '^\s*<#') { $inMultilineComment = $true; continue }
                    if ($up -match '^\s*#>' -and $inMultilineComment) { $inMultilineComment = $false; continue }
                    
                    # Check for single-line comment lines above
                    $dm = [regex]::Match($up, '^\s*#\s*(.+)$')
                    if ($dm.Success -and -not $inMultilineComment) {
                        $descText = $dm.Groups[1].Value
                        # Skip if this looks like a structured comment (dashes, equals, etc.)
                        if ($descText -notmatch '^[-=\s]*$' -and $descText -notmatch '^[A-Za-z ]+:$' -and $descText.Length -lt 120) {
                            $desc = $descText
                            break
                        }
                    }
                    # Check for content inside multiline comments
                    elseif ($inMultilineComment -and $up -and -not ($up -match '^\s*<#') -and -not ($up -match '^\s*#')) {
                        # Extract the first meaningful line from multiline comment
                        $descText = $up.Trim()
                        # Skip function names, titles (word + dashes), decorative lines
                        if ($descText -notmatch '^[-=\s]*$' -and $descText -notmatch '^[A-Za-z ]+:$' -and $descText -notmatch '^[A-Za-z0-9_\-]+$' -and $descText -notmatch '^-+$' -and $descText.Length -lt 120) {
                            $desc = $descText
                            break
                        }
                    }
                    
                    # Stop if we hit a non-comment, non-empty line (but allow if statements)
                    if ($up -and -not ($up -match '^\s*$') -and -not ($up -match '^\s*#') -and -not ($up -match '^\s*if\s*\(') -and -not $inMultilineComment) {
                        break
                    }
                }
                $functions += [PSCustomObject]@{ Name = $fname; Short = $desc }
            }
        }
    } catch {}

    # Detect dynamically-created functions (Set-Item Function:Name, Function:Name references,
    # Set-AgentModeFunction/Set-AgentModeAlias, New-Item Function:Name)
    try {
        for ($i = 0; $i -lt $allLines.Count; $i++) {
            $line = $allLines[$i]
            $ln = $line.Trim()
            $fname = $null
            $desc = $null
            
            # Check for different patterns of function creation
            if ($ln -match 'Set-AgentModeFunction\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)') {
                $fname = $matches[1]
            } elseif ($ln -match 'Set-AgentModeAlias\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)') {
                $fname = $matches[1]
            } elseif ($ln -match '(?:Set-Item|New-Item)\s+(?:-Path\s+)?Function:(?:global:)?([A-Za-z0-9_\-]+)') {
                $fname = $matches[1]
            }
            
            if ($fname) {
                # Look for comments above the function creation (up to 10 lines back)
                $inMultilineComment = $false
                # First pass: determine if we're starting inside a multiline comment
                for ($k = $i - 1; $k -ge [Math]::Max(0, $i - 10); $k--) {
                    $checkLine = $allLines[$k].Trim()
                    if ($checkLine -match '^\s*<#') { $inMultilineComment = $true; break }
                    if ($checkLine -match '^\s*#>' -and $inMultilineComment) { $inMultilineComment = $false; break }
                    # Only break on actual code lines, not content inside comments
                    if ($checkLine -and -not ($checkLine -match '^\s*$') -and -not ($checkLine -match '^\s*#') -and -not ($checkLine -match '^\s*if\s*\(') -and -not $inMultilineComment) { break }
                }
                # Second pass: extract comments
                for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 10); $j--) {
                    $up = $allLines[$j].Trim()
                    
                    # Track multiline comment state
                    if ($up -match '^\s*<#') { $inMultilineComment = $true; continue }
                    if ($up -match '^\s*#>' -and $inMultilineComment) { $inMultilineComment = $false; continue }
                    
                    # Check for single-line comment lines above
                    $dm = [regex]::Match($up, '^\s*#\s*(.+)$')
                    if ($dm.Success -and -not $inMultilineComment) {
                        $descText = $dm.Groups[1].Value
                        # Skip if this looks like a structured comment (dashes, equals, etc.)
                        if ($descText -notmatch '^[-=\s]*$' -and $descText -notmatch '^[A-Za-z ]+:$' -and $descText.Length -lt 120) {
                            $desc = $descText
                            break
                        }
                    }
                    # Check for content inside multiline comments
                    elseif ($inMultilineComment -and $up -and -not ($up -match '^\s*<#') -and -not ($up -match '^\s*#')) {
                        # Extract the first meaningful line from multiline comment
                        $descText = $up.Trim()
                        # Skip function names, titles (word + dashes), decorative lines
                        if ($descText -notmatch '^[-=\s]*$' -and $descText -notmatch '^[A-Za-z ]+:$' -and $descText -notmatch '^[A-Za-z0-9_\-]+$' -and $descText -notmatch '^-+$' -and $descText.Length -lt 120) {
                            $desc = $descText
                            break
                        }
                    }
                    
                    # Stop if we hit a non-comment, non-empty line
                    if ($up -and -not ($up -match '^\s*$') -and -not ($up -match '^\s*#') -and -not ($up -match '^\s*if\s*\(') -and -not $inMultilineComment) {
                        break
                    }
                }
                
                # If no comment found above, check for inline comment on the function line
                if (-not $desc) {
                    $functionLine = $allLines[$i].Trim()
                    if ($functionLine -match "# (.+)$") {
                        $inlineDesc = $matches[1]
                        # Skip decorative comments
                        if ($inlineDesc -notmatch '^[-=\s]*$' -and $inlineDesc -notmatch '^[A-Za-z ]+:$') {
                            $desc = $inlineDesc
                        }
                    }
                }
                
                # Only add if not already in the list
                if ($functions.Name -notcontains $fname) {
                    if (-not $desc) { $desc = 'dynamically-created; see fragment source' }
                    $functions += [PSCustomObject]@{ Name = $fname; Short = $desc }
                }
            }
        }
    } catch {}

    $title = "profile.d/$($ps.Name)"
    $underline = '=' * $title.Length

    $md = @()
    $md += $title
    $md += $underline
    $md += ''
    $md += 'Purpose'
    $md += '-------'
    $md += $purpose
    $md += ''
    $md += 'Usage'
    $md += '-----'
    $md += ('See the fragment source: `{0}` for examples and usage notes.' -f $ps.Name)
    if ($functions.Count -gt 0) {
        $md += ''
        $md += 'Functions'
        $md += '---------'
        foreach ($f in $functions) {
            if ($f.Short) { $md += ('- `{0}` — {1}' -f $f.Name, $f.Short) } else { $md += ('- `{0}`' -f $f.Name) }
        }
    }
    if ($enableHelpers.Count -gt 0) {
        $md += ''
        $md += 'Enable helpers'
        $md += '--------------'
        foreach ($h in $enableHelpers) { $md += ('- {0} (lazy enabler; imports or config when called)' -f $h) }
    }
    $md += ''
    $md += 'Dependencies'
    $md += '------------'
    $md += 'None explicit; see the fragment for runtime checks and optional tooling dependencies.'
    $md += ''
    $md += 'Notes'
    $md += '-----'
    $md += 'Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.'

    ($md -join [Environment]::NewLine) | Out-File -FilePath $mdPath -Encoding utf8 -Force
    Write-Output ("Created: {0}" -f (Split-Path $mdPath -Leaf))
}

Write-Output 'Done generating fragment README files.'
