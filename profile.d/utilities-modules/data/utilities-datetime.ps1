# ===============================================
# DateTime utility functions
# Epoch conversion and date/time formatting
# ===============================================

# Convert Unix timestamp to DateTime
<#
.SYNOPSIS
    Converts Unix timestamp to DateTime.
.DESCRIPTION
    Converts a Unix timestamp (seconds since epoch) to a local DateTime.
.EXAMPLE
    ConvertFrom-Epoch -epoch 1700000000
.PARAMETER epoch
    Unix timestamp in seconds since 1970-01-01 UTC.

#>
function ConvertFrom-Epoch { param([long]$epoch) [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime() }
Set-AgentModeAlias -Name 'from-epoch' -Target 'ConvertFrom-Epoch'
# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Converts DateTime to Unix timestamp.
.DESCRIPTION
    Converts a DateTime object or string to a Unix timestamp (seconds since epoch).
.EXAMPLE
    ConvertTo-Epoch -date (Get-Date '2024-01-01')
.PARAMETER date
    DateTime value to convert. Defaults to the current local time.

#>
function ConvertTo-Epoch { param([DateTime]$date = (Get-Date)) [DateTimeOffset]::new($date).ToUnixTimeSeconds() }
Set-AgentModeAlias -Name 'to-epoch' -Target 'ConvertTo-Epoch'
# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Gets current Unix timestamp.
.DESCRIPTION
    Returns the current date and time as a Unix timestamp (seconds since epoch).
#>
function Get-Epoch { [DateTimeOffset]::Now.ToUnixTimeSeconds() }
Set-AgentModeAlias -Name 'epoch' -Target 'Get-Epoch'
# Get current date and time in standard format
<#
.SYNOPSIS
    Shows current date and time.
.DESCRIPTION
    Displays the current date and time in a standard format.
#>
function Get-DateTime {
    # Use DateTimeFormatting module if available for unified date formatting
    if (Get-Command Format-DateTime -ErrorAction SilentlyContinue) {
        Format-DateTime -DateTime (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
    }
    elseif (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
        # Fallback to Format-LocaleDate if DateTimeFormatting not available
        Format-LocaleDate (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'
    }
    else {
        # Final fallback to standard format
        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
Set-AgentModeAlias -Name 'now' -Target 'Get-DateTime'