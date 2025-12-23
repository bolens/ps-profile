# ===============================================
# AssumedCommands.ps1
# Assumed command management utilities
# ===============================================

<#
.SYNOPSIS
    Adds command names that should always be treated as available.
.DESCRIPTION
    Registers command names, typically optional tools, that the profile should
    treat as present even when they are not discoverable on the current PATH.
.PARAMETER Name
    One or more command names to mark as assumed available.
.OUTPUTS
    System.Boolean
#>
function global:Add-AssumedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    if (-not $global:AssumedAvailableCommands) {
        return $false
    }

    $added = $false

    foreach ($entry in $Name) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $normalized = $entry.Trim()
        if ($global:AssumedAvailableCommands.TryAdd($normalized, $true) -or $global:AssumedAvailableCommands.ContainsKey($normalized)) {
            $added = $true
        }
    }

    return $added
}

<#
.SYNOPSIS
    Removes command names from the assumed available command list.
.DESCRIPTION
    Clears previously added assumed commands so future detection reverts to
    standard provider checks.
.PARAMETER Name
    One or more command names to remove from the assumed command list.
.OUTPUTS
    System.Boolean
#>
function global:Remove-AssumedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    if (-not $global:AssumedAvailableCommands) {
        return $false
    }

    $removed = $false

    foreach ($entry in $Name) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $normalized = $entry.Trim()
        $removedEntry = $null
        if ($global:AssumedAvailableCommands.TryRemove($normalized, [ref]$removedEntry)) {
            $removed = $true
        }
    }

    return $removed
}

<#
.SYNOPSIS
    Retrieves the list of assumed available commands.
.OUTPUTS
    System.String[]
#>
function global:Get-AssumedCommands {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    if (-not $global:AssumedAvailableCommands) {
        return @()
    }

    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in $global:AssumedAvailableCommands.Keys) {
        $result.Add($key)
    }
    $array = $result.ToArray()
    return , $array
}

# Load assumed commands from environment variable (comma/semicolon/space-separated)
# These commands will be treated as available even if not found on PATH
if ($env:PS_PROFILE_ASSUME_COMMANDS) {
    $tokens = $env:PS_PROFILE_ASSUME_COMMANDS -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($tokens) {
        Add-AssumedCommand -Name $tokens | Out-Null
    }
}

