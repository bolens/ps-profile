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
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null
)

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

# Default to profile.d relative to the repository root
if (-not $Path) {
    try {
        $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
        $Path = Join-Path $repoRoot 'profile.d'
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

Write-ScriptMessage -Message "Running security scan on: $Path"

# Ensure PSScriptAnalyzer is available
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Security-focused rules
$securityRules = @(
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingUserNameAndPasswordParams',
    'PSUsePSCredentialType',
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingPositionalParameters'
)

# Use List for better performance than array concatenation
$securityIssues = [System.Collections.Generic.List[PSCustomObject]]::new()

Get-ChildItem -Path $Path -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-ScriptMessage -Message "Security scanning $file"

    try {
        $results = Invoke-ScriptAnalyzer -Path $file -IncludeRule $securityRules -Severity Error, Warning -ErrorAction Stop
        if ($results) {
            foreach ($result in $results) {
                $securityIssues.Add([PSCustomObject]@{
                        File     = (Resolve-Path -Relative $result.ScriptPath)
                        Rule     = $result.RuleName
                        Severity = $result.Severity
                        Line     = $result.Line
                        Message  = $result.Message
                    })
            }
        }
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to scan $file`: $($_.Exception.Message)" -ErrorRecord $_
    }
}

if ($securityIssues.Count -gt 0) {
    Write-ScriptMessage -Message "`nSecurity Issues Found:"
    $securityIssues | Format-Table -AutoSize
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($securityIssues.Count) security-related issues"
}
else {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Security scan completed: no issues found"
}