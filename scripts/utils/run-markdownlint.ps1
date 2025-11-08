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

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-markdownlint.ps1

    Runs markdownlint on all markdown files in the repository.
#>

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

$ErrorActionPreference = 'Stop'

# Check if markdownlint-cli is installed
$markdownlint = Get-Command markdownlint -ErrorAction SilentlyContinue
$npx = Get-Command npx -ErrorAction SilentlyContinue

if (-not $markdownlint -and -not $npx) {
    Write-ScriptMessage -Message "markdownlint-cli not found. Installing..."
    try {
        npm install -g markdownlint-cli@0.35.0
        if ($LASTEXITCODE -ne 0) {
            Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to install markdownlint-cli"
        }
        $markdownlint = Get-Command markdownlint -ErrorAction SilentlyContinue
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

Write-ScriptMessage -Message "Running markdownlint..."
try {
    if ($markdownlint) {
        markdownlint '**/*.md' --ignore node_modules --ignore '**/Modules/**'
    }
    else {
        npx --yes markdownlint-cli@0.35.0 '**/*.md' --ignore node_modules --ignore '**/Modules/**'
    }

    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "markdownlint found errors"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "markdownlint passed!"

