# ===============================================
# TestSupportCoreFunctions.ps1
# Canonical TestSupport helpers restored between test files
# ===============================================

function Remove-TestFunction {
    <#
    .SYNOPSIS
        Removes a test stub function from both session and global function drives.

    .DESCRIPTION
        PowerShell can expose the same global function as Function:\Name and
        Function:\global:Name. Removing only one path leaves a leaked stub that
        pollutes later tests in combined Pester runs.

    .PARAMETER Name
        Function name(s) to remove.

    .EXAMPLE
        Remove-TestFunction -Name 'Test-ValidString'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Name
    )

    process {
        foreach ($functionName in $Name) {
            if ([string]::IsNullOrWhiteSpace($functionName)) {
                continue
            }

            Remove-Item -Path "Function:\$functionName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$functionName" -Force -ErrorAction SilentlyContinue
        }
    }
}

function Mark-TestCommandsUnavailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$CommandNames
    )

    foreach ($command in $CommandNames) {
        if (Get-Command Set-TestCommandAvailabilityState -ErrorAction SilentlyContinue) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            continue
        }

        if (-not (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:TestCachedCommandCache = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
        }

        if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
        }

        Remove-TestFunction -Name $command
        Remove-Item -Path "Alias:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Alias:\global:$command" -Force -ErrorAction SilentlyContinue

        $removed = $null
        $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}

function Register-TestFragmentAliases {
    <#
    .SYNOPSIS
        Force-registers profile aliases when host binaries would shadow Set-AgentModeAlias.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AliasTargets
    )

    foreach ($entry in $AliasTargets.GetEnumerator()) {
        if (Get-Command $entry.Value -CommandType Function -ErrorAction SilentlyContinue) {
            Set-Alias -Name $entry.Key -Value $entry.Value -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Import-ProfileFragmentWithShadowedCommands {
    <#
    .SYNOPSIS
        Loads a profile fragment after hiding host commands that would shadow aliases.

    .DESCRIPTION
        Removes aliases/functions for the given command names, marks them unavailable
        in the test command cache, dot-sources the fragment, then force-registers aliases
        when host binaries would otherwise prevent Set-AgentModeAlias from succeeding.

    .PARAMETER FragmentPath
        Path to the profile fragment to load.

    .PARAMETER ShadowCommandNames
        Command names to hide before loading the fragment.

    .PARAMETER AliasTargets
        Optional map of alias name to profile function for force-registration after load.

    .PARAMETER FragmentName
        Optional fragment idempotency name to clear before reload.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentPath,

        [Parameter(Mandatory)]
        [string[]]$ShadowCommandNames,

        [hashtable]$AliasTargets,

        [string]$FragmentName
    )

    Mark-TestCommandsUnavailable -CommandNames $ShadowCommandNames

    if ($FragmentName -and (Get-Command Clear-FragmentLoaded -ErrorAction SilentlyContinue)) {
        Clear-FragmentLoaded -FragmentName $FragmentName -ErrorAction SilentlyContinue
    }

    . $FragmentPath

    if ($AliasTargets) {
        foreach ($entry in $AliasTargets.GetEnumerator()) {
            if (Get-Command $entry.Value -CommandType Function -ErrorAction SilentlyContinue) {
                Set-Alias -Name $entry.Key -Value $entry.Value -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
}
