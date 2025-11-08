<#
scripts/utils/find-duplicate-functions.ps1

.SYNOPSIS
    Finds duplicate function definitions in profile.d directory.

.DESCRIPTION
    Scans all PowerShell script files in the profile.d directory and identifies
    functions that are defined in multiple files. This helps detect potential conflicts
    or duplicate function definitions that could cause issues.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\find-duplicate-functions.ps1

    Scans profile.d directory and reports any duplicate function definitions.
#>

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module -Path $commonModulePath -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $profileDir = Join-Path $repoRoot 'profile.d'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

if (-not (Test-Path $profileDir)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "profile.d not found at $profileDir"
}

$files = Get-ChildItem -Path $profileDir -Filter '*.ps1' -File

# Use List for better performance than array concatenation
$found = [System.Collections.Generic.List[PSCustomObject]]::new()

# Compile regex once for better performance
$functionRegex = [regex]::new("function\s+([A-Za-z0-9_-]+)\s*\{", [System.Text.RegularExpressions.RegexOptions]::Compiled)

foreach ($f in $files) {
    $content = Get-Content -Raw -Path $f.FullName
    foreach ($m in $functionRegex.Matches($content)) {
        $found.Add([PSCustomObject]@{
                File = $f.FullName
                Name = $m.Groups[1].Value
            })
    }
}

$groups = $found | Group-Object Name | Where-Object { $_.Count -gt 1 }

if ($groups.Count -eq 0) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "No duplicate function definitions found in profile.d"
}

foreach ($g in $groups) {
    Write-ScriptMessage -Message "Function: $($g.Name)"
    $g.Group | ForEach-Object { Write-ScriptMessage -Message "  - $($_.File)" }
    Write-ScriptMessage -Message ""
}

# Exit with validation failure if duplicates found (non-zero exit indicates issue)
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($groups.Count) duplicate function definition(s)"
