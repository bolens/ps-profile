# ===============================================
# 05-utilities.ps1
# Utility functions migrated from utilities.ps1
# ===============================================

# Reload profile in current session
<#
.SYNOPSIS
    Reloads the PowerShell profile.
.DESCRIPTION
    Dots-sources the current profile file to reload all functions and settings.
#>
function reload { .$PROFILE }
# Edit profile in code editor
<#
.SYNOPSIS
    Opens the profile in VS Code.
.DESCRIPTION
    Launches VS Code to edit the current PowerShell profile file.
#>
function edit-profile { code $PROFILE }
# Weather info for a location (city, zip, etc.)
<#
.SYNOPSIS
    Shows weather information.
.DESCRIPTION
    Retrieves and displays weather information for a specified location using wttr.in.
#>
function weather { Invoke-WebRequest -Uri "https://wttr.in/$args" }
# Get public IP address
<#
.SYNOPSIS
    Shows public IP address.
.DESCRIPTION
    Retrieves and displays the current public IP address.
#>
function myip { (Invoke-RestMethod ifconfig.me).Trim() }
# Run speedtest-cli
<#
.SYNOPSIS
    Runs internet speed test.
.DESCRIPTION
    Executes speedtest-cli to measure internet connection speed.
#>
function speedtest { speedtest-cli }
# History helpers
<#
.SYNOPSIS
    Shows recent command history.
.DESCRIPTION
    Displays the last 20 commands from the PowerShell command history.
#>
function Get-History { Get-History | Select-Object -Last 20 }
# Search history
<#
.SYNOPSIS
    Searches command history.
.DESCRIPTION
    Searches through PowerShell command history for the specified pattern.
#>
function hg { Get-History | Select-String $args }
# Generate random password
<#
.SYNOPSIS
    Generates a random password.
.DESCRIPTION
    Creates a 16-character random password using alphanumeric characters.
#>
function pwgen { -join ((1..16) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) }) }
# Convert Unix timestamp to DateTime
<#
.SYNOPSIS
    Converts Unix timestamp to DateTime.
.DESCRIPTION
    Converts a Unix timestamp (seconds since epoch) to a local DateTime.
#>
function from-epoch { param([long]$epoch) [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime() }
# Convert DateTime to Unix timestamp
<#
.SYNOPSIS
    Gets current Unix timestamp.
.DESCRIPTION
    Returns the current date and time as a Unix timestamp (seconds since epoch).
#>
function epoch { [DateTimeOffset]::Now.ToUnixTimeSeconds() }
# Get current date and time in standard format
<#
.SYNOPSIS
    Shows current date and time.
.DESCRIPTION
    Displays the current date and time in a standard format.
#>
function now { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
# Open current directory in File Explorer
<#
.SYNOPSIS
    Opens current directory in File Explorer.
.DESCRIPTION
    Launches Windows File Explorer in the current directory.
#>
function open-explorer { explorer.exe . }
# List all user-defined functions in current session
<#
.SYNOPSIS
    Lists user-defined functions.
.DESCRIPTION
    Displays all user-defined functions in the current PowerShell session.
#>
function list-functions { Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name, Definition | Format-Table -AutoSize }
# Backup current profile to timestamped .bak file
<#
.SYNOPSIS
    Creates a backup of the profile.
.DESCRIPTION
    Creates a timestamped backup copy of the current PowerShell profile.
#>
function backup-profile { Copy-Item $PROFILE ($PROFILE + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak') }
