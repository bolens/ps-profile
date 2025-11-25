<#
scripts/utils/security/modules/SecurityReporter.psm1

.SYNOPSIS
    Security scan reporting utilities.

.DESCRIPTION
    Provides functions for processing and reporting security scan results.
#>

<#
.SYNOPSIS
    Processes security scan results and separates them by severity.

.DESCRIPTION
    Processes security issues and separates them into blocking issues (errors) and warnings.

.PARAMETER SecurityIssues
    Array of security issue objects.

.OUTPUTS
    Hashtable with BlockingIssues, WarningIssues, and ScanErrors properties.
#>
function Get-SecurityScanResults {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$SecurityIssues
    )

    # Resolve relative paths for display
    foreach ($issue in $SecurityIssues) {
        try {
            $relativePath = Resolve-Path -Relative $issue.File -ErrorAction SilentlyContinue
            if ($relativePath) {
                $issue.File = $relativePath
            }
        }
        catch {
            # Keep absolute path if relative resolution fails
        }
    }

    # Check for scan errors
    $scanErrors = $SecurityIssues | Where-Object { $_.Rule -eq 'ScanError' }
    if ($scanErrors.Count -gt 0) {
        foreach ($error in $scanErrors) {
            Write-ScriptMessage -Message "Failed to scan $($error.File): $($error.Message)" -IsWarning
        }
    }

    $blockingIssues = $SecurityIssues | Where-Object { $_.Severity -eq 'Error' }
    $warningIssues = $SecurityIssues | Where-Object { $_.Severity -ne 'Error' }

    return @{
        BlockingIssues = $blockingIssues
        WarningIssues  = $warningIssues
        ScanErrors     = $scanErrors
    }
}

<#
.SYNOPSIS
    Displays security scan results to the console.

.DESCRIPTION
    Outputs formatted security scan results with color-coded severity levels.

.PARAMETER Results
    Security scan results hashtable from Get-SecurityScanResults.

.OUTPUTS
    None. Outputs to console.
#>
function Write-SecurityReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Results
    )

    $blockingIssues = $Results.BlockingIssues
    $warningIssues = $Results.WarningIssues

    if ($blockingIssues.Count -gt 0) {
        Write-ScriptMessage -Message "`nSecurity Issues (Errors):"
        $blockingIssues | Format-Table -AutoSize

        if ($warningIssues.Count -gt 0) {
            Write-ScriptMessage -Message "`nSecurity Warnings:" -LogLevel Info
            $warningIssues | Format-Table -AutoSize
        }
    }
    elseif ($warningIssues.Count -gt 0) {
        Write-ScriptMessage -Message "`nSecurity Warnings:" -LogLevel Info
        $warningIssues | Format-Table -AutoSize
    }
}

Export-ModuleMember -Function Get-SecurityScanResults, Write-SecurityReport

