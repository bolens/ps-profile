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
Set-AgentModeAlias -Name 'weather' -Target 'Get-Weather'
# Get public IP address
<#
.SYNOPSIS
    Shows public IP address.
.DESCRIPTION
    Retrieves and displays the current public IP address.
#>
function Get-MyIP { (Invoke-RestMethod ifconfig.me).Trim() }
Set-AgentModeAlias -Name 'myip' -Target 'Get-MyIP'
# Run speedtest-cli
<#
.SYNOPSIS
    Runs internet speed test.
.DESCRIPTION
    Executes speedtest-cli to measure internet connection speed.
#>
function Start-SpeedTest { & (Get-Command speedtest.exe).Source --accept-license }
Set-AgentModeAlias -Name 'speedtest' -Target 'Start-SpeedTest'