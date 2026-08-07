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

.PARAMETER PassThru
    Returns an exit result instead of terminating the current process.


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

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/generate-changelog.ps1

    Generates a full changelog in CHANGELOG.md.


.EXAMPLE
    pwsh -NoProfile -File scripts/utils/generate-changelog.ps1 -Unreleased

    Generates only the unreleased changes section.


.EXAMPLE
    pwsh -NoProfile -File scripts/utils/generate-changelog.ps1 -OutputFile "RELEASE_NOTES.md"

    Generates changelog with a custom output filename.

#>

param(
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile = "CHANGELOG.md",
    [switch]$Unreleased,

    [scriptblock]$CommandTestAction = {
        param($CommandName)
        Test-CommandAvailable -CommandName $CommandName
    },

    [scriptblock]$CargoInstallAction = {
        & cargo install git-cliff
        $LASTEXITCODE
    },

    [scriptblock]$GitCliffAction = {
        param($Arguments)
        & git-cliff @Arguments
        $LASTEXITCODE
    },

    [Nullable[bool]]$NonInteractive,

    [switch]$PassThru
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

function Complete-ChangelogGeneration {
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [string]$Message,

        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($PassThru) {
        [PSCustomObject]@{
            ExitCode    = $ExitCode
            Message     = $Message
            ErrorRecord = $ErrorRecord
        }
        return
    }

    Exit-WithCode -ExitCode $ExitCode -Message $Message -ErrorRecord $ErrorRecord
}

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $cliffConfig = Join-Path $repoRoot 'cliff.toml'
    $changelogPath = Join-Path $repoRoot $OutputFile
}
catch {
    Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    return
}

Write-ScriptMessage -Message "Generating changelog..."

# Check if git-cliff is available
$hasGitCliff = & $CommandTestAction -CommandName 'git-cliff'

if (-not $hasGitCliff) {
    # Never auto-install in CI/unit tests — cargo/winget can prompt or run for minutes.
    $nonInteractive = if ($null -ne $NonInteractive) { [bool]$NonInteractive } else {
        $env:PS_PROFILE_NONINTERACTIVE -eq '1' -or
        $env:PS_PROFILE_TEST_MODE -eq '1' -or
        $env:CI -eq 'true' -or
        $env:GITHUB_ACTIONS -eq 'true'
    }
    if ($nonInteractive) {
        Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -Message 'git-cliff is required but not installed (auto-install disabled in non-interactive mode)'
        return
    }

    Write-ScriptMessage -Message "git-cliff not found. Installing..."

    # Try to install git-cliff
    try {
        # Check if cargo is available (Rust toolchain)
        $hasCargo = & $CommandTestAction -CommandName 'cargo'
        if ($hasCargo) {
            Write-ScriptMessage -Message "Installing git-cliff via cargo..."
            $cargoExitCode = & $CargoInstallAction
            if ($cargoExitCode -ne 0) {
                Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -Message "Failed to install git-cliff via cargo"
                return
            }
        }
        else {
            # Try via other methods
            Write-ScriptMessage -Message "Please install git-cliff manually:"
            Write-ScriptMessage -Message "  Via cargo: cargo install git-cliff"
            Write-ScriptMessage -Message "  Via scoop: scoop install git-cliff"
            Write-ScriptMessage -Message "  Via winget: winget install git-cliff"
            Write-ScriptMessage -Message "  Download from: https://github.com/orhun/git-cliff/releases"
            Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -Message "git-cliff is required but not installed"
            return
        }
    }
    catch {
        Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
        return
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
    $gitCliffExitCode = & $GitCliffAction -Arguments $args

    if ($gitCliffExitCode -eq 0) {
        Complete-ChangelogGeneration -ExitCode $EXIT_SUCCESS -Message "Changelog generated successfully: $changelogPath"
        return
    }
    else {
        Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -Message "Failed to generate changelog (exit code: $gitCliffExitCode)"
        return
    }
}
catch {
    Complete-ChangelogGeneration -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    return
}
