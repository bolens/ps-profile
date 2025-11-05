<#
.SYNOPSIS
    Generates changelog using git-cliff from conventional commits.

.DESCRIPTION
    Generates a changelog file from git commit history using git-cliff and
    conventional commit messages. The script uses the cliff.toml configuration
    file in the repository root to determine formatting and categorization rules.

    If git-cliff is not installed, the script will attempt to install it via
    cargo (Rust toolchain) if available, or provide instructions for manual
    installation.

.PARAMETER OutputFile
    Specifies the output filename for the generated changelog.
    The path is resolved relative to the repository root.
    Default value is "CHANGELOG.md".

.PARAMETER Unreleased
    If specified, generates only the unreleased changes section without
    including version tags. Useful for previewing changes before a release.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/generate-changelog.ps1

    Generates a full changelog in CHANGELOG.md.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/generate-changelog.ps1 -Unreleased

    Generates only the unreleased changes section.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/generate-changelog.ps1 -OutputFile "RELEASE_NOTES.md"

    Generates changelog with a custom output filename.

.OUTPUTS
    Creates or updates the changelog file at the specified path.

.NOTES
    This script requires git-cliff to be installed. Installation options:
    - Via cargo: cargo install git-cliff
    - Via scoop: scoop install git-cliff
    - Via winget: winget install git-cliff
    - Download from: https://github.com/orhun/git-cliff/releases

    The script uses the cliff.toml configuration file in the repository root
    to control changelog formatting, commit categorization, and filtering rules.

    Used in CI/CD pipelines and release creation workflows.

#>

param(
    [string]$OutputFile = "CHANGELOG.md",
    [switch]$Unreleased
)

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cliffConfig = Join-Path $repoRoot 'cliff.toml'
$changelogPath = Join-Path $repoRoot $OutputFile

Write-Output "Generating changelog..."

# Use Test-HasCommand for efficient command checks (if available from profile, otherwise fallback)
$testHasCommand = (Test-Path Function:Test-HasCommand) -or (Get-Command Test-HasCommand -ErrorAction SilentlyContinue)

# Check if git-cliff is available
if ($testHasCommand) {
    $hasGitCliff = Test-HasCommand git-cliff
}
else {
    $hasGitCliff = $null -ne (Get-Command git-cliff -ErrorAction SilentlyContinue)
}

if (-not $hasGitCliff) {
    Write-Output "git-cliff not found. Installing..."

    # Try to install git-cliff
    try {
        # Check if cargo is available (Rust toolchain)
        if ($testHasCommand) {
            $hasCargo = Test-HasCommand cargo
        }
        else {
            $hasCargo = $null -ne (Get-Command cargo -ErrorAction SilentlyContinue)
        }
        if ($hasCargo) {
            $cargo = Get-Command cargo -ErrorAction SilentlyContinue
            Write-Output "Installing git-cliff via cargo..."
            & cargo install git-cliff
        }
        else {
            # Try via other methods
            Write-Output "Please install git-cliff manually:"
            Write-Output "  Via cargo: cargo install git-cliff"
            Write-Output "  Via scoop: scoop install git-cliff"
            Write-Output "  Via winget: winget install git-cliff"
            Write-Output "  Download from: https://github.com/orhun/git-cliff/releases"
            exit 1
        }
    }
    catch {
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
}
else {
    Write-Error "Failed to generate changelog"
    exit $LASTEXITCODE
}
