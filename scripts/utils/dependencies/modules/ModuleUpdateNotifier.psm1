<#
scripts/utils/dependencies/modules/ModuleUpdateNotifier.psm1

.SYNOPSIS
    Module update notification utilities.

.DESCRIPTION
    Provides functions for sending email notifications about module updates.
#>

<#
.SYNOPSIS
    Sends email notification about module updates.

.DESCRIPTION
    Sends an email notification with update information. Can be configured to only send when updates are available.

.PARAMETER ReportData
    Report data object with update information.

.PARAMETER UpdatesAvailable
    Boolean indicating if updates are available.

.PARAMETER EmailTo
    Email addresses to send notifications to.

.PARAMETER EmailFrom
    Email address to send notifications from.

.PARAMETER EmailSmtpServer
    SMTP server address.

.PARAMETER EmailSmtpPort
    SMTP server port.

.PARAMETER EmailSmtpCredential
    Credential for SMTP authentication.

.PARAMETER EmailOnlyOnUpdates
    Whether to only send email when updates are available.
#>
function Send-UpdateNotification {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ReportData,

        [Parameter(Mandatory)]
        [bool]$UpdatesAvailable,

        [string[]]$EmailTo = @(),

        [string]$EmailFrom = $null,

        [string]$EmailSmtpServer = "localhost",

        [int]$EmailSmtpPort = 25,

        [System.Management.Automation.PSCredential]$EmailSmtpCredential = $null,

        [switch]$EmailOnlyOnUpdates
    )

    if ($EmailTo.Count -eq 0) {
        return
    }

    if (-not $EmailFrom) {
        Write-ScriptMessage -Message "EmailFrom is required when using EmailTo" -IsWarning
        return
    }

    if ($EmailOnlyOnUpdates -and -not $UpdatesAvailable) {
        Write-Verbose "EmailOnlyOnUpdates is set and no updates available. Skipping email."
        return
    }

    try {
        $subject = if ($UpdatesAvailable) {
            "PowerShell Module Updates Available - $($ReportData.UpdatesAvailable) module(s)"
        }
        else {
            "PowerShell Module Update Check - All modules up to date"
        }

        $body = @"
PowerShell Module Update Report
Generated: $($ReportData.Timestamp)

Modules Checked: $($ReportData.ModulesChecked)
Updates Available: $($ReportData.UpdatesAvailable)
Modules Updated: $($ReportData.ModulesUpdated)

"@

        if ($UpdatesAvailable -and $ReportData.Updates.Count -gt 0) {
            $body += "`nAvailable Updates:`n"
            $body += "==================`n"
            foreach ($update in $ReportData.Updates) {
                $status = if ($update.Updated) { "[UPDATED]" } else { "[PENDING]" }
                $body += "$status $($update.Name): $($update.CurrentVersion) -> $($update.LatestVersion) ($($update.Source))`n"
            }
        }
        else {
            $body += "`nAll modules are up to date.`n"
        }

        $mailParams = @{
            To          = $EmailTo
            From        = $EmailFrom
            Subject     = $subject
            Body        = $body
            SmtpServer  = $EmailSmtpServer
            Port        = $EmailSmtpPort
            ErrorAction = 'Stop'
        }

        if ($EmailSmtpCredential) {
            $mailParams['Credential'] = $EmailSmtpCredential
        }

        Send-MailMessage @mailParams
        Write-ScriptMessage -Message "Email notification sent to: $($EmailTo -join ', ')" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to send email notification: $($_.Exception.Message)" -IsWarning
    }
}

Export-ModuleMember -Function @(
    'Send-UpdateNotification'
)

