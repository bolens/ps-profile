<#
scripts/utils/run-format.ps1

Format PowerShell code using PowerShell-Beautifier for consistent styling.

Usage: pwsh -NoProfile -File scripts/utils/run-format.ps1
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

$filesFormatted = 0
$errors = @()

Get-ChildItem -Path $Path -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Formatting $file"

    try {
        # Use Invoke-Formatter from PSScriptAnalyzer to format the file
        $formattedContent = Invoke-Formatter -ScriptDefinition (Get-Content -Path $file -Raw) -ErrorAction Stop
        $formattedContent | Set-Content -Path $file -Encoding UTF8 -ErrorAction Stop
        $filesFormatted++
    }
    catch {
        $errors += [PSCustomObject]@{
            File  = $file
            Error = $_.Exception.Message
        }
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
