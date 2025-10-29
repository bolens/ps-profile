# ===============================================
# 05-utilities.ps1
# Utility functions migrated from utilities.ps1
# ===============================================

# Reload profile in current session
function reload { .$PROFILE }
# Edit profile in code editor
function edit-profile { code $PROFILE }
# Weather info for a location (city, zip, etc.)
function weather { Invoke-WebRequest -Uri "https://wttr.in/$args" }
# Get public IP address
function myip { (Invoke-RestMethod ifconfig.me).Trim() }
# Run speedtest-cli
function speedtest { speedtest-cli }
# History helpers
function Get-History { Get-History | Select-Object -Last 20 }
# Search history
function hg { Get-History | Select-String $args }
# Generate random password
function pwgen { -join ((1..16) | ForEach-Object { [char]((65..90) + (97..122) + (48..57) | Get-Random) }) }
# Convert Unix timestamp to DateTime
function from-epoch { param([long]$epoch) [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime() }
# Convert DateTime to Unix timestamp
function epoch { [DateTimeOffset]::Now.ToUnixTimeSeconds() }
# Get current date and time in standard format
function now { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
# Open current directory in File Explorer
function open-explorer { explorer.exe . }
# List all user-defined functions in current session
function list-functions { Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name, Definition | Format-Table -AutoSize }
# Backup current profile to timestamped .bak file
function backup-profile { Copy-Item $PROFILE ($PROFILE + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak') }














