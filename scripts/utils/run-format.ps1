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

Write-Output "Running PowerShell-Beautifier on: $Path"

# Ensure module is available in current user scope
if (-not (Get-Module -ListAvailable -Name PowerShell-Beautifier)) {
    Write-Output "PowerShell-Beautifier not found. Installing to CurrentUser scope..."
    try {
        Install-Module -Name PowerShell-Beautifier -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop
    } catch {
        Write-Error "Failed to install PowerShell-Beautifier: $($_.Exception.Message)"
        exit 2
    }
}

# Import the module
try {
    Import-Module -Name PowerShell-Beautifier -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import PowerShell-Beautifier: $($_.Exception.Message)"
    exit 2
}

$filesFormatted = 0
$errors = @()

Get-ChildItem -Path $Path -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Formatting $file"

    try {
        # Use Edit-DTWBeautifyScript to format the file in-place
        Edit-DTWBeautifyScript -SourcePath $file -DestinationPath $file -ErrorAction Stop
        $filesFormatted++
    } catch {
        $errors += [PSCustomObject]@{
            File = $file
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

Write-Output "PowerShell-Beautifier: all files formatted successfully"
exit 0