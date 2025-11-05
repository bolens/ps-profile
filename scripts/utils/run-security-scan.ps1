<#
scripts/utils/run-security-scan.ps1

.SYNOPSIS
    Runs security-focused analysis on PowerShell scripts using PSScriptAnalyzer.

.DESCRIPTION
    Runs security-focused analysis on PowerShell scripts using PSScriptAnalyzer with
    security-specific rules. Checks for common security issues like plain text passwords,
    use of Invoke-Expression, and other security anti-patterns.

.PARAMETER Path
    The path to scan. Defaults to profile.d directory relative to repository root.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-security-scan.ps1

    Runs security scan on all PowerShell files in the profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-security-scan.ps1 -Path scripts

    Runs security scan on all PowerShell files in the scripts directory.
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

Write-Output "Running security scan on: $Path"

# Ensure PSScriptAnalyzer is available
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Output "PSScriptAnalyzer not found. Installing to CurrentUser scope..."
    try {
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to install PSScriptAnalyzer: $($_.Exception.Message)"
        exit 2
    }
}

Import-Module -Name PSScriptAnalyzer -Force -ErrorAction Stop

# Security-focused rules
$securityRules = @(
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingUserNameAndPasswordParams',
    'PSUsePSCredentialType',
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingPositionalParameters'
)

$securityIssues = @()

Get-ChildItem -Path $Path -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Security scanning $file"

    $results = Invoke-ScriptAnalyzer -Path $file -IncludeRule $securityRules -Severity Error, Warning
    if ($results) {
        $securityIssues += $results | ForEach-Object {
            [PSCustomObject]@{
                File     = (Resolve-Path -Relative $_.ScriptPath)
                Rule     = $_.RuleName
                Severity = $_.Severity
                Line     = $_.Line
                Message  = $_.Message
            }
        }
    }
}

if ($securityIssues.Count -gt 0) {
    Write-Output "`nSecurity Issues Found:"
    $securityIssues | Format-Table -AutoSize
    Write-Error "Found $($securityIssues.Count) security-related issues"
    exit 1
}
else {
    Write-Output "Security scan completed: no issues found"
    exit 0
}