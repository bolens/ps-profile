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

# Import ModuleImport first (bootstrap)
# Note: Adjust the path based on script location:
# - scripts/checks/: Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
# - scripts/utils/*/: Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
# - scripts/git/: Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Initialize script environment with common modules and paths
# This replaces multiple Import-LibModule calls and Get-RepoRoot error handling
$env = Initialize-ScriptEnvironment `
    -ScriptPath $PSScriptRoot `
    -ImportModules @('ExitCodes', 'PathResolution', 'Logging') `
    -GetRepoRoot `
    -DisableNameChecking `
    -ExitOnError

$repoRoot = $env.RepoRoot

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


