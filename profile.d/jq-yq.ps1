# ===============================================
# jq-yq.ps1
# jq and yq helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    jq and yq helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for converting JSON and YAML formats.
    Functions check for jq/yq availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.JqYq
    Author: PowerShell Profile
#>

# jq to JSON converter - convert JSON to compact JSON
<#
.SYNOPSIS
    Converts JSON to compact JSON format using jq.

.DESCRIPTION
    Uses jq to convert JSON files to compact (single-line) JSON format.

.PARAMETER File
    Path to the JSON file to convert.

.EXAMPLE
    Convert-JqToJson -File "data.json"

.EXAMPLE
    Convert-JqToJson -File "config.json"
#>
function Convert-JqToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$File
    )
    
    if (Test-CachedCommand jq) {
        jq -c . $File
    }
    else {
        Write-MissingToolWarning -Tool 'jq' -InstallHint 'Install with: scoop install jq'
    }
}

# yq to JSON converter - convert YAML to JSON
<#
.SYNOPSIS
    Converts YAML to JSON format using yq.

.DESCRIPTION
    Uses yq to convert YAML files to JSON format.

.PARAMETER File
    Path to the YAML file to convert.

.EXAMPLE
    Convert-YqToJson -File "config.yaml"

.EXAMPLE
    Convert-YqToJson -File "data.yaml"
#>
function Convert-YqToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$File
    )
    
    if (Test-CachedCommand yq) {
        yq eval -o=json $File
    }
    else {
        Write-MissingToolWarning -Tool 'yq' -InstallHint 'Install with: scoop install yq'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jq2json' -Target 'Convert-JqToJson'
    Set-AgentModeAlias -Name 'yq2json' -Target 'Convert-YqToJson'
}
else {
    Set-Alias -Name 'jq2json' -Value 'Convert-JqToJson' -ErrorAction SilentlyContinue
    Set-Alias -Name 'yq2json' -Value 'Convert-YqToJson' -ErrorAction SilentlyContinue
}
