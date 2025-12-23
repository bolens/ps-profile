# ===============================================
# Timestamp conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes timestamp conversion utility functions.
.DESCRIPTION
    Sets up internal functions for converting between Unix epoch timestamps and DateTime.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Timestamp {
    # Epoch/Unix Timestamp Converter
    Set-Item -Path Function:Global:_ConvertFrom-Epoch -Value {
        param([long]$Epoch, [switch]$Milliseconds)
        $epochSeconds = if ($Milliseconds) { $Epoch / 1000 } else { $Epoch }
        [DateTimeOffset]::FromUnixTimeSeconds($epochSeconds).LocalDateTime
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-Epoch -Value {
        param([DateTime]$DateTime, [switch]$Milliseconds)
        $epoch = [DateTimeOffset]::new($DateTime).ToUnixTimeSeconds()
        if ($Milliseconds) { $epoch * 1000 } else { $epoch }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts Unix epoch timestamp to DateTime.
.DESCRIPTION
    Converts a Unix epoch timestamp (seconds or milliseconds) to a DateTime object.
.PARAMETER Epoch
    The Unix epoch timestamp to convert.
.PARAMETER Milliseconds
    If specified, treats the epoch value as milliseconds instead of seconds.
.EXAMPLE
    ConvertFrom-Epoch -Epoch 1609459200
    Converts Unix timestamp to DateTime (2021-01-01 00:00:00 UTC).
.EXAMPLE
    ConvertFrom-Epoch -Epoch 1609459200000 -Milliseconds
    Converts Unix timestamp in milliseconds to DateTime.
.OUTPUTS
    System.DateTime
    The converted DateTime object.
#>
function ConvertFrom-Epoch {
    param([long]$Epoch, [switch]$Milliseconds)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertFrom-Epoch @PSBoundParameters
}
Set-Alias -Name epoch-to-date -Value ConvertFrom-Epoch -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Converts DateTime to Unix epoch timestamp.
.DESCRIPTION
    Converts a DateTime object to a Unix epoch timestamp (seconds or milliseconds).
.PARAMETER DateTime
    The DateTime to convert.
.PARAMETER Milliseconds
    If specified, returns milliseconds instead of seconds.
.EXAMPLE
    ConvertTo-Epoch -DateTime (Get-Date)
    Converts current date to Unix timestamp in seconds.
.EXAMPLE
    ConvertTo-Epoch -DateTime (Get-Date) -Milliseconds
    Converts current date to Unix timestamp in milliseconds.
.OUTPUTS
    System.Int64
    The Unix epoch timestamp.
#>
function ConvertTo-Epoch {
    param([DateTime]$DateTime, [switch]$Milliseconds)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertTo-Epoch @PSBoundParameters
}

Set-Alias -Name date-to-epoch -Value ConvertTo-Epoch -ErrorAction SilentlyContinue
