<#
scripts/utils/generate-changelog.ps1

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
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile = "CHANGELOG.md",
    [switch]$Unreleased
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $cliffConfig = Join-Path $repoRoot 'cliff.toml'
    $changelogPath = Join-Path $repoRoot $OutputFile
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

Write-ScriptMessage -Message "Generating changelog..."

# Check if git-cliff is available
$hasGitCliff = Test-CommandAvailable -CommandName 'git-cliff'

if (-not $hasGitCliff) {
    Write-ScriptMessage -Message "git-cliff not found. Installing..."

    # Try to install git-cliff
    try {
        # Check if cargo is available (Rust toolchain)
        $hasCargo = Test-CommandAvailable -CommandName 'cargo'
        if ($hasCargo) {
            $cargo = Get-Command cargo -ErrorAction SilentlyContinue
            Write-ScriptMessage -Message "Installing git-cliff via cargo..."
            & cargo install git-cliff
            if ($LASTEXITCODE -ne 0) {
                Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to install git-cliff via cargo"
            }
        }
        else {
            # Try via other methods
            Write-ScriptMessage -Message "Please install git-cliff manually:"
            Write-ScriptMessage -Message "  Via cargo: cargo install git-cliff"
            Write-ScriptMessage -Message "  Via scoop: scoop install git-cliff"
            Write-ScriptMessage -Message "  Via winget: winget install git-cliff"
            Write-ScriptMessage -Message "  Download from: https://github.com/orhun/git-cliff/releases"
            Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "git-cliff is required but not installed"
        }
    }
    catch {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
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

Write-ScriptMessage -Message "Running: git-cliff $($args -join ' ')"
try {
    & git-cliff @args

    if ($LASTEXITCODE -eq 0) {
        Exit-WithCode -ExitCode [ExitCode]::Success -Message "Changelog generated successfully: $changelogPath"
    }
    else {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to generate changelog (exit code: $LASTEXITCODE)"
    }
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}
