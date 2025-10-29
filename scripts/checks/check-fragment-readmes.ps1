<#
scripts/checks/check-fragment-readmes.ps1

Compare top-level function names in profile.d/*.ps1 fragments against the
Functions section of profile.d/*.README.md files. Exit with code 0 when all
fragments match, and non-zero when any mismatch is found.

Usage:
  pwsh -NoProfile -File scripts\checks\check-fragment-readmes.ps1
#>

param(
    [switch]$Verbose
)

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fragDir = Join-Path $root 'profile.d'
$psFiles = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name

$mismatchCount = 0

function Get-FunctionsFromPs1($path) {
    $lines = Get-Content -Path $path -ErrorAction SilentlyContinue
    $names = [System.Collections.Generic.List[string]]::new()

    # Find explicit function declarations
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $m = [regex]::Match($line, '^\s*function\s+([A-Za-z0-9_\-]+)\b', 'IgnoreCase')
        if ($m.Success) { $names.Add($m.Groups[1].Value) }
    }

    # Find dynamically-created functions
    foreach ($l in $lines) {
        $ln = $l.Trim()
        # Set-AgentModeFunction -Name 'Name'
        $m2 = [regex]::Match($ln, 'Set-AgentModeFunction\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)')
        if ($m2.Success) { $names.Add($m2.Groups[1].Value) }

        # Set-AgentModeAlias -Name 'Name'
        $m3 = [regex]::Match($ln, 'Set-AgentModeAlias\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)')
        if ($m3.Success) { $names.Add($m3.Groups[1].Value) }

        # Set-Item/New-Item Function:Name
        $m4 = [regex]::Match($ln, '(?:Set-Item|New-Item)\s+(?:-Path\s+)?Function:(?:global:)?([A-Za-z0-9_\-]+)')
        if ($m4.Success) { $names.Add($m4.Groups[1].Value) }
    }

    # Filter out invalid names
    $keywords = 'if', 'for', 'foreach', 'while', 'switch', 'param', 'return', 'else', 'try', 'catch', 'function', 'global'
    $names = $names | Where-Object {
        ($_ -match '^[A-Za-z_][A-Za-z0-9_\-]*$') -and
        ($_ -notin $keywords) -and
        (-not ($_ -like '-*'))
    } | Sort-Object -Unique

    return $names
}

function Get-FunctionsFromReadme($path) {
    if (-not (Test-Path $path)) { return @() }
    $lines = Get-Content -Path $path -ErrorAction SilentlyContinue
    $start = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^[#\-]*Functions[\s#\-]*$' -or $lines[$i] -match '^Functions\s*$') { $start = $i; break }
    }
    if ($null -eq $start) { return @() }
    $funcs = @()
    for ($j = $start + 1; $j -lt $lines.Count; $j++) {
        $l = $lines[$j].Trim()
        if ($l -eq '') { continue }

        # If the very next line is a Setext underline (---- or ====) skip it and continue
        if ($l -match '^[=\-]{2,}$') { continue }

        # If this line looks like the start of a new section (heading) followed by an underline, stop
        if ($l -match '^[A-Za-z].+' -and ($j + 1 -lt $lines.Count) -and ($lines[$j + 1] -match '^[=\-]{2,}$')) { break }

        # Stop at other simple section headers like 'Something:'
        if ($l -match '^[A-Za-z].+:$') { break }

        # Ignore common decoration lines
        if ($l -match '^[`\-=_\s]+$') { continue }

        # Match list items like '- `Name` — desc' or '- Name' where the name begins with alnum
        $m = [regex]::Match($l, '^-\s*`?([A-Za-z0-9][A-Za-z0-9_\-]*)`?')
        if ($m.Success) { $funcs += $m.Groups[1].Value; continue }

        # Fallback: bare names without leading '- '
        $m2 = [regex]::Match($l, '^`?([A-Za-z0-9][A-Za-z0-9_\-]*)`?')
        if ($m2.Success) { $funcs += $m2.Groups[1].Value }
    }

    return $funcs
}

function Get-FunctionsWithoutDocumentation($path) {
    $content = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return @() }

    $undocumented = @()

    # Find all function definitions
    $functionMatches = [regex]::Matches($content, '(?s)function\s+(\w+)')

    foreach ($match in $functionMatches) {
        $functionName = $match.Groups[1].Value

        # Look for comment-based help before the function
        $functionIndex = $match.Index
        $beforeFunction = $content.Substring(0, $functionIndex)

        # Check if there's comment-based help (starts with <# and ends with #>)
        $lastCommentStart = $beforeFunction.LastIndexOf('<#')
        $lastCommentEnd = $beforeFunction.LastIndexOf('#>')

        $hasHelp = $false
        if ($lastCommentStart -ge 0 -and $lastCommentEnd -gt $lastCommentStart) {
            # Check if the comment contains SYNOPSIS or DESCRIPTION
            $commentContent = $beforeFunction.Substring($lastCommentStart, $lastCommentEnd - $lastCommentStart + 2)
            if ($commentContent -match '\.SYNOPSIS|\.DESCRIPTION') {
                $hasHelp = $true
            }
        }

        if (-not $hasHelp) {
            $undocumented += $functionName
        }
    }

    return $undocumented
}

Write-Output "Checking fragment READMEs in $fragDir"

foreach ($ps in $psFiles) {
    $readme = [System.IO.Path]::ChangeExtension($ps.FullName, '.README.md')
    $psFuncs = Get-FunctionsFromPs1 $ps.FullName
    $mdFuncs = Get-FunctionsFromReadme $readme
    $undocumentedFuncs = Get-FunctionsWithoutDocumentation $ps.FullName

    $onlyInPs = $psFuncs | Where-Object { $_ -notin $mdFuncs }
    $onlyInMd = $mdFuncs | Where-Object { $_ -notin $psFuncs }

    $hasIssues = $false

    if ($onlyInPs.Count -gt 0 -or $onlyInMd.Count -gt 0) {
        $mismatchCount++
        $hasIssues = $true
        Write-Output "MISMATCH: $($ps.Name)"
        if ($onlyInPs.Count -gt 0) { Write-Output "  Functions in PS1 but not in README: $([string]::Join(', ', $onlyInPs))" }
        if ($onlyInMd.Count -gt 0) { Write-Output "  Functions in README but not in PS1: $([string]::Join(', ', $onlyInMd))" }
    }

    if ($undocumentedFuncs.Count -gt 0) {
        $mismatchCount++
        $hasIssues = $true
        Write-Output "UNDOCUMENTED: $($ps.Name)"
        Write-Output "  Functions without comment-based help: $([string]::Join(', ', $undocumentedFuncs))"
    }

    if ($hasIssues) {
        Write-Output "  Readme: $([System.IO.Path]::GetFileName($readme))`n"
    }
    elseif ($Verbose) {
        Write-Output "OK: $($ps.Name)"
    }
}

if ($mismatchCount -gt 0) {
    Write-Output "Found $mismatchCount fragments with issues (mismatched functions or missing documentation)."
    exit 2
}
else {
    Write-Output "All fragment READMEs appear to list functions that match their PS1 files, and all functions have documentation."
    exit 0
}
