#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Runs markdownlint on all markdown files.


.DESCRIPTION
    Runs the checkout-installed markdownlint-cli version declared in package.json.
    Install it with pnpm install --frozen-lockfile --ignore-scripts.
    Set MARKDOWNLINT_VERSION to opt into a separate exact version via npx.
    The explicit npx override resolves dependencies outside the checkout lockfile.


.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): markdownlint passed
    - 1 (EXIT_VALIDATION_FAILURE): markdownlint found errors
    - 2 (EXIT_SETUP_ERROR): Invalid version or unable to start markdownlint-cli

    Version Control:
    - Set MARKDOWNLINT_VERSION environment variable to use a specific version
    - Default version: package.json devDependencies.markdownlint-cli

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\run-markdownlint.ps1

    Runs markdownlint on all markdown files in the repository.


.EXAMPLE
    $env:MARKDOWNLINT_VERSION = '0.40.0'
    pwsh -NoProfile -File scripts\utils\code-quality\run-markdownlint.ps1

    Runs markdownlint using version 0.40.0.
#>

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

$ErrorActionPreference = 'Stop'
$markdownlint = $null
try {
    $version = $env:MARKDOWNLINT_VERSION
    if (-not $version) {
        $repoRoot = Get-RepoRoot -ScriptPath $PSCommandPath
        $package = Read-JsonFile -Path (Join-Path $repoRoot 'package.json') -ErrorAction Stop
        $version = $package.devDependencies.'markdownlint-cli'
    }
    [System.Management.Automation.SemanticVersion]$parsedVersion = $null
    if ($version -isnot [string] -or
        -not [System.Management.Automation.SemanticVersion]::TryParse($version, [ref]$parsedVersion) -or
        $version -cne $parsedVersion.ToString()) {
        throw 'Specify an exact semantic version in package.json or MARKDOWNLINT_VERSION.'
    }

    if (-not $env:MARKDOWNLINT_VERSION) {
        $launcher = if ($IsWindows) { 'markdownlint.cmd' } else { 'markdownlint' }
        $localCommand = Join-Path $repoRoot "node_modules/.bin/$launcher"
        $localManifest = Join-Path $repoRoot 'node_modules/markdownlint-cli/package.json'
        if ((Test-Path -LiteralPath $localCommand -PathType Leaf) -and (Test-Path -LiteralPath $localManifest -PathType Leaf)) {
            $installed = Read-JsonFile -Path $localManifest -ErrorAction Stop
            if ($installed.version -ceq $version) {
                $markdownlint = $localCommand
            }
        }
        if (-not $markdownlint) {
            throw 'Install the locked checkout dependencies with pnpm install --frozen-lockfile --ignore-scripts.'
        }
    }
    else {
        $npx = Get-Command npx -ErrorAction Stop
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Cannot prepare markdownlint-cli: $($_.Exception.Message)"
}

Write-ScriptMessage -Message "Running markdownlint (version: $version)..."
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
        & $markdownlint @markdownArgs
    }
    else {
        & $npx --yes --ignore-scripts "markdownlint-cli@$version" @markdownArgs
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
