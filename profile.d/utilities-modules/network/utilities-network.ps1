# ===============================================
# Network utility functions
# Weather, IP address, speed test
# ===============================================

# Weather info for a location (city, zip, etc.)
<#
.SYNOPSIS
    Shows weather information.
.DESCRIPTION
    Retrieves and displays weather information for a specified location using wttr.in.
#>
function Get-Weather { Invoke-WebRequest -Uri "https://wttr.in/$args" }
Set-Alias -Name weather -Value Get-Weather -ErrorAction SilentlyContinue

# Get public IP address
<#
.SYNOPSIS
    Shows public IP address.
.DESCRIPTION
    Retrieves and displays the current public IP address.
#>
function Get-MyIP { (Invoke-RestMethod ifconfig.me).Trim() }
Set-Alias -Name myip -Value Get-MyIP -ErrorAction SilentlyContinue

# Run speedtest-cli
<#
.SYNOPSIS
    Runs internet speed test.
.DESCRIPTION
    Executes speedtest-cli to measure internet connection speed.
#>
function Start-SpeedTest { & (Get-Command speedtest.exe).Source --accept-license }
Set-Alias -Name speedtest -Value Start-SpeedTest -ErrorAction SilentlyContinue

