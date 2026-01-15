# ===============================================
# TextSearch.ps1
# Text search utilities
# ===============================================

# Pattern search in files (Unix 'grep' equivalent)
<#
.SYNOPSIS
    Searches for patterns in files.
.DESCRIPTION
    Searches for text patterns in files using Select-String.
#>
function Find-String {
    param([string]$Pattern, [string]$Path)

    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                    [System.ArgumentException]::new("Pattern parameter is required"),
                    'PatternRequired',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $null
                )) -OperationName 'textsearch.find-string' -Context @{}
        }
        else {
            Write-Error "Pattern parameter is required"
        }
        return
    }

    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        Invoke-WithWideEvent -OperationName 'textsearch.find-string' -Context @{
            pattern  = $Pattern
            has_path = ($null -ne $Path)
            path     = $Path
        } -ScriptBlock {
            if ($Path) {
                if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
                    throw "Path not found: $Path"
                }
                Select-String -Pattern $Pattern -Path $Path -ErrorAction Stop
            }
            else {
                $input | Select-String -Pattern $Pattern -ErrorAction Stop
            }
        }
    }
    else {
        try {
            if ($Path) {
                if (-not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
                    Write-Error "Path not found: $Path"
                    return
                }
                Select-String -Pattern $Pattern -Path $Path -ErrorAction Stop
            }
            else {
                $input | Select-String -Pattern $Pattern -ErrorAction Stop
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Error "Access denied reading path '$Path': $($_.Exception.Message)"
            throw
        }
        catch {
            Write-Error "Failed to search for pattern '$Pattern': $($_.Exception.Message)"
            throw
        }
    }
}
Set-Alias -Name pgrep -Value Find-String -ErrorAction SilentlyContinue

