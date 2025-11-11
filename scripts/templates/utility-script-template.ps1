<#
.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description of the script's functionality, including any important
    notes about usage, dependencies, or behavior.

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    .\utility-script-template.ps1 -ParameterName "value"
    Example of how to use the script.

.NOTES
    Author: Your Name
    Date: $(Get-Date -Format 'yyyy-MM-dd')
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ParameterName = "default"
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Write-Error "Failed to determine repository root: $_"
    exit $EXIT_SETUP_ERROR
}

# Main script logic here
Write-ScriptMessage -Message "Starting script execution..." -LogLevel Info

try {
    # Your script logic here
    
    Write-ScriptMessage -Message "Script completed successfully" -LogLevel Info
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Write-ScriptMessage -Message "Script failed: $_" -LogLevel Error
    Exit-WithCode -ExitCode $EXIT_OTHER_ERROR
}

