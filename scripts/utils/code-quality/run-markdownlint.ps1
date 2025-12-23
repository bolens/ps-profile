#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
scripts/utils/run-markdownlint.ps1

.SYNOPSIS
    Runs markdownlint on all markdown files.

.DESCRIPTION
    Checks if markdownlint-cli is installed and runs it on all markdown files,
    excluding node_modules and Modules directories. If markdownlint-cli is not
    found, attempts to install it globally via npm. Exits with error code 1 if
    any linting errors are found.

    The markdownlint-cli version can be controlled via the MARKDOWNLINT_VERSION
    environment variable. Defaults to 0.35.0 if not specified.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-markdownlint.ps1

    Runs markdownlint on all markdown files in the repository.

.EXAMPLE
    $env:MARKDOWNLINT_VERSION = '0.40.0'
    pwsh -NoProfile -File scripts\utils\run-markdownlint.ps1

    Runs markdownlint using version 0.40.0.

.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): markdownlint passed
    - 1 (EXIT_VALIDATION_FAILURE): markdownlint found errors
    - 2 (EXIT_SETUP_ERROR): Failed to install or run markdownlint-cli

    Version Control:
    - Set MARKDOWNLINT_VERSION environment variable to use a specific version
    - Default version: 0.35.0
#>

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'NodeJs' -ScriptPath $PSScriptRoot -DisableNameChecking -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

# Get markdownlint-cli version from environment variable or use default
$markdownlintVersion = if ($env:MARKDOWNLINT_VERSION) {
    $env:MARKDOWNLINT_VERSION
}
else {
    '0.35.0'  # Default version
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
try {
    if ($markdownlint) {
        markdownlint '**/*.md' --ignore node_modules --ignore '**/Modules/**'
    }
    else {
        npx --yes "markdownlint-cli@$markdownlintVersion" '**/*.md' --ignore node_modules --ignore '**/Modules/**'
    }

    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "markdownlint found errors"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "markdownlint passed!"


try {
    if ($markdownlint) {
        markdownlint '**/*.md' --ignore node_modules --ignore '**/Modules/**'
    }
    else {
        npx --yes "markdownlint-cli@$markdownlintVersion" '**/*.md' --ignore node_modules --ignore '**/Modules/**'
    }

    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "markdownlint found errors"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "markdownlint passed!"


