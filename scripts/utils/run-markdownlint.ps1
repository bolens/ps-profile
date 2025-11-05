#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Runs markdownlint on all markdown files.

.DESCRIPTION
    Checks if markdownlint-cli is installed and runs it on all markdown files,
    excluding node_modules.

.EXAMPLE
    .\scripts\utils\run-markdownlint.ps1
#>

$ErrorActionPreference = 'Stop'

# Check if markdownlint-cli is installed
$markdownlint = Get-Command markdownlint -ErrorAction SilentlyContinue
$npx = Get-Command npx -ErrorAction SilentlyContinue

if (-not $markdownlint -and -not $npx) {
    Write-Information "markdownlint-cli not found. Installing..." -InformationAction Continue
    npm install -g markdownlint-cli@0.35.0
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install markdownlint-cli"
        exit 1
    }
    $markdownlint = Get-Command markdownlint -ErrorAction SilentlyContinue
}

Write-Information "Running markdownlint..." -InformationAction Continue
if ($markdownlint) {
    markdownlint '**/*.md' --ignore node_modules --ignore '**/Modules/**'
}
else {
    npx --yes markdownlint-cli@0.35.0 '**/*.md' --ignore node_modules --ignore '**/Modules/**'
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "markdownlint found errors"
    exit 1
}

Write-Information "markdownlint passed!" -InformationAction Continue

