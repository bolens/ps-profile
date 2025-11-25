<#
scripts/utils/dependencies/modules/ModuleUpdateHistory.psm1

.SYNOPSIS
    Module update history tracking utilities.

.DESCRIPTION
    Provides functions for tracking and saving module update history.
#>

<#
.SYNOPSIS
    Saves update history to track update records over time.

.DESCRIPTION
    Maintains a history file with all update checks and their results.

.PARAMETER ReportData
    Report data object with update information.

.PARAMETER RepoRoot
    Repository root directory path.
#>
function Save-UpdateHistory {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ReportData,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $historyFile = Join-Path $RepoRoot 'scripts' 'data' 'module-update-history.json'
    $historyDir = Split-Path -Path $historyFile -Parent
    Ensure-DirectoryExists -Path $historyDir

    $history = @()
    if (Test-Path $historyFile) {
        try {
            $existingContent = Get-Content -Path $historyFile -Raw -Encoding UTF8
            $history = $existingContent | ConvertFrom-Json
            if (-not $history) {
                $history = @()
            }
        }
        catch {
            Write-ScriptMessage -Message "Failed to read existing history file, creating new one: $($_.Exception.Message)" -IsWarning
            $history = @()
        }
    }

    # Add current report to history
    $historyEntry = [PSCustomObject]@{
        Timestamp        = $ReportData.Timestamp
        ModulesChecked   = $ReportData.ModulesChecked
        UpdatesAvailable = $ReportData.UpdatesAvailable
        ModulesUpdated   = $ReportData.ModulesUpdated
        Updates          = $ReportData.Updates
    }

    $history += $historyEntry

    # Keep only last 100 entries to prevent file from growing too large
    if ($history.Count -gt 100) {
        $history = $history | Select-Object -Last 100
    }

    try {
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $historyFile -Encoding UTF8
        Write-ScriptMessage -Message "Update history saved to: $historyFile" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to save update history: $($_.Exception.Message)" -IsWarning
    }
}

Export-ModuleMember -Function @(
    'Save-UpdateHistory'
)

