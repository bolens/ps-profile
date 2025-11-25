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
#>
function ConvertFrom-Epoch { param([long]$epoch) [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime() }
Set-Alias -Name from-epoch -Value ConvertFrom-Epoch -ErrorAction SilentlyContinue

# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Converts DateTime to Unix timestamp.
.DESCRIPTION
    Converts a DateTime object or string to a Unix timestamp (seconds since epoch).
#>
function ConvertTo-Epoch { param([DateTime]$date = (Get-Date)) [DateTimeOffset]::new($date).ToUnixTimeSeconds() }
Set-Alias -Name to-epoch -Value ConvertTo-Epoch -ErrorAction SilentlyContinue

# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Gets current Unix timestamp.
.DESCRIPTION
    Returns the current date and time as a Unix timestamp (seconds since epoch).
#>
function Get-Epoch { [DateTimeOffset]::Now.ToUnixTimeSeconds() }
Set-Alias -Name epoch -Value Get-Epoch -ErrorAction SilentlyContinue

# Get current date and time in standard format
<#
.SYNOPSIS
    Shows current date and time.
.DESCRIPTION
    Displays the current date and time in a standard format.
#>
function Get-DateTime { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
Set-Alias -Name now -Value Get-DateTime -ErrorAction SilentlyContinue

