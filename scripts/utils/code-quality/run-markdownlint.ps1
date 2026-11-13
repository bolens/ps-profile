#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Runs markdownlint on all markdown files.


.DESCRIPTION
    Checks if markdownlint-cli is installed and runs it on all markdown files,
    excluding node_modules and Modules directories. If markdownlint-cli is not
    found, attempts to install it globally via npm. Exits with error code 1 if
    any linting errors are found.

    The markdownlint-cli version can be controlled via the MARKDOWNLINT_VERSION
    environment variable. Otherwise, the exact version in package.json is used.


.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): markdownlint passed
    - 1 (EXIT_VALIDATION_FAILURE): markdownlint found errors
    - 2 (EXIT_SETUP_ERROR): Failed to install or run markdownlint-cli

    Version Control:
    - Set MARKDOWNLINT_VERSION environment variable to use a specific version
    - Default version: package.json devDependencies.markdownlint-cli

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-markdownlint.ps1

    Runs markdownlint on all markdown files in the repository.


.EXAMPLE
    $env:MARKDOWNLINT_VERSION = '0.40.0'
    pwsh -NoProfile -File scripts\utils\run-markdownlint.ps1

    Runs markdownlint using version 0.40.0.
#>

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'NodeJs' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

$ErrorActionPreference = 'Stop'

# Keep the local fallback and its log aligned with the canonical dependency pin.
$markdownlintVersion = if ($env:MARKDOWNLINT_VERSION) {
    $env:MARKDOWNLINT_VERSION
}
else {
    try {
        $repoRoot = Get-RepoRoot -ScriptPath $PSCommandPath
        $package = Read-JsonFile -Path (Join-Path $repoRoot 'package.json') -ErrorAction Stop
        $version = $package.devDependencies.'markdownlint-cli'
        [System.Management.Automation.SemanticVersion]$parsedVersion = $null
        if ($version -isnot [string] -or
            -not [System.Management.Automation.SemanticVersion]::TryParse($version, [ref]$parsedVersion) -or
            $version -ne $parsedVersion.ToString()) {
            throw 'package.json must pin markdownlint-cli to an exact semantic version'
        }
        $version
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Cannot resolve the canonical markdownlint-cli version: $($_.Exception.Message)"
    }
}

# Check if markdownlint-cli is installed
$markdownlint = Get-Command markdownlint -ErrorAction SilentlyContinue
$npx = Get-Command npx -ErrorAction SilentlyContinue

if (-not $markdownlint -and -not $npx) {
    Write-ScriptMessage -Message "markdownlint-cli not found. Installing version $markdownlintVersion..."
    try {
        npm install -g "markdownlint-cli@$markdownlintVersion"
        if ($LASTEXITCODE -ne 0) {
            Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to install markdownlint-cli@$markdownlintVersion"
        }
        $markdownlint = Get-Command markdownlint -ErrorAction SilentlyContinue
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

Write-ScriptMessage -Message "Running markdownlint (version: $markdownlintVersion)..."
# Keep ignores aligned with CI / local hooks (skip generated reports and test fixtures).
$markdownArgs = @(
    '**/*.md'
    '--ignore', 'node_modules'
    '--ignore', '**/Modules/**'
    '--ignore', '**/tests/**'
    '--ignore', '**/docs/test-verification-reports/**'
    '--ignore', '**/docs/api/**'
)
try {
    if ($markdownlint) {
        & markdownlint @markdownArgs
    }
    else {
        & npx --yes "markdownlint-cli@$markdownlintVersion" @markdownArgs
    }

    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "markdownlint found errors"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$successMessage = "markdownlint passed!"
if ($env:PS_PROFILE_TEST_MODE -eq '1') {
    Write-ScriptMessage -Message $successMessage
}
else {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message $successMessage
}
