<#
scripts/utils/run-format.ps1

.SYNOPSIS
    Formats PowerShell code using PSScriptAnalyzer for consistent styling.

.DESCRIPTION
    Formats PowerShell code using PSScriptAnalyzer's Invoke-Formatter for consistent styling.
    By default, formats all PowerShell files in the profile.d directory. Preserves original
    line endings (CRLF or LF) in the formatted output.

.PARAMETER Path
    The path to format. Defaults to profile.d directory relative to repository root.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1

    Formats all PowerShell files in the profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-format.ps1 -Path scripts

    Formats all PowerShell files in the scripts directory.
#>

param(
    [string]$Path = $null
)

# Default to profile.d relative to the repository root
if (-not $Path) {
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $repoRoot = Split-Path -Parent $scriptDir
    $Path = Join-Path $repoRoot 'profile.d'
}

Write-Output "Running PSScriptAnalyzer formatter on: $Path"

# Ensure PSScriptAnalyzer is available (includes formatting capabilities)
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Output "PSScriptAnalyzer not found. Installing to CurrentUser scope..."
    try {
        # Register PSGallery if not already registered
        if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Default
        }
        # Set PSGallery as trusted
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to install PSScriptAnalyzer: $($_.Exception.Message)"
        exit 2
    }
}

# Import the module
try {
    Import-Module -Name PSScriptAnalyzer -Force -ErrorAction Stop
}
catch {
    Write-Error "Failed to import PSScriptAnalyzer: $($_.Exception.Message)"
    exit 2
}

# Compile regex pattern once for CRLF detection
$crlfRegex = [regex]::new("`r`n", [System.Text.RegularExpressions.RegexOptions]::Compiled)

$filesFormatted = 0
# Use List for better performance than array concatenation
$errors = [System.Collections.Generic.List[PSCustomObject]]::new()

Get-ChildItem -Path $Path -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Formatting $file"

    try {
        # Read the original content to detect line endings
        $originalContent = Get-Content -Path $file -Raw -ErrorAction Stop
        $hasCRLF = $crlfRegex.IsMatch($originalContent)

        # Use Invoke-Formatter from PSScriptAnalyzer to format the file
        $formattedContent = Invoke-Formatter -ScriptDefinition $originalContent -ErrorAction Stop

        # Trim trailing whitespace and ensure consistent line endings
        $formattedContent = $formattedContent.TrimEnd()
        # Add back the appropriate line ending based on original file
        if ($hasCRLF) {
            $formattedContent += "`r`n"
        }
        else {
            $formattedContent += "`n"
        }

        $formattedContent | Set-Content -Path $file -Encoding UTF8 -NoNewline -ErrorAction Stop
        $filesFormatted++
    }
    catch {
        $errors.Add([PSCustomObject]@{
                File  = $file
                Error = $_.Exception.Message
            })
        Write-Warning "Failed to format $file`: $($_.Exception.Message)"
    }
}

Write-Output "Formatted $filesFormatted file(s)"

if ($errors.Count -gt 0) {
    Write-Error "Failed to format $($errors.Count) file(s):"
    $errors | ForEach-Object { Write-Output "  $($_.File): $($_.Error)" }
    exit 1
}

Write-Output "PSScriptAnalyzer: all files formatted successfully"
exit 0
