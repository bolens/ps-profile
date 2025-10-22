<#
scripts/utils/generate-changelog.ps1

Generates changelog using git-cliff from conventional commits.

Usage: pwsh -NoProfile -File scripts/utils/generate-changelog.ps1
#>

param(
    [string]$OutputFile = "CHANGELOG.md",
    [switch]$Unreleased
)

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cliffConfig = Join-Path $repoRoot 'cliff.toml'
$changelogPath = Join-Path $repoRoot $OutputFile

Write-Output "Generating changelog..."

# Check if git-cliff is available
$gitCliff = Get-Command git-cliff -ErrorAction SilentlyContinue
if (-not $gitCliff) {
    Write-Output "git-cliff not found. Installing..."

    # Try to install git-cliff
    try {
        # Check if cargo is available (Rust toolchain)
        $cargo = Get-Command cargo -ErrorAction SilentlyContinue
        if ($cargo) {
            Write-Output "Installing git-cliff via cargo..."
            & cargo install git-cliff
        } else {
            # Try via other methods
            Write-Output "Please install git-cliff manually:"
            Write-Output "  Via cargo: cargo install git-cliff"
            Write-Output "  Via scoop: scoop install git-cliff"
            Write-Output "  Via winget: winget install git-cliff"
            Write-Output "  Download from: https://github.com/orhun/git-cliff/releases"
            exit 1
        }
    } catch {
        Write-Error "Failed to install git-cliff: $($_.Exception.Message)"
        exit 1
    }
}

# Generate changelog
$args = @(
    '--config', $cliffConfig,
    '--output', $changelogPath
)

if ($Unreleased) {
    $args += '--unreleased'
}

Write-Output "Running: git-cliff $($args -join ' ')"
& git-cliff @args

if ($LASTEXITCODE -eq 0) {
    Write-Output "Changelog generated successfully: $changelogPath"
} else {
    Write-Error "Failed to generate changelog"
    exit $LASTEXITCODE
}
