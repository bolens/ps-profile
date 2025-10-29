# Repro script for testing profile loading in agent mode
# This script loads the PowerShell profile to test agent mode functionality

Write-Output "Starting profile repro in agent mode..."

# Set environment to simulate agent mode if needed
$env:GITHUB_ACTIONS = 'true'

# Load the profile
. $PSScriptRoot\..\Microsoft.PowerShell_profile.ps1

Write-Output "Profile loaded successfully."
