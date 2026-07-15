<#
scripts/lib/fragment/CommandDispatcher.psm1

.SYNOPSIS
    Command-not-found dispatcher for on-demand fragment loading.

.DESCRIPTION
    Hooks PowerShell's CommandNotFoundAction to load profile fragments when a
    registered command is invoked before its fragment has been sourced. Honors
    PS_PROFILE_AUTO_LOAD_FRAGMENTS and preserves any previously registered handler.
#>

$script:DispatcherRegistered = $false
$script:PreviousCommandNotFoundAction = $null

function Get-SessionScopedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command
    }

    return Get-Command -Name $Name -Scope Global -ErrorAction SilentlyContinue
}

function Test-AutoLoadFragmentsEnabled {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($env:PS_PROFILE_AUTO_LOAD_FRAGMENTS) {
        $normalized = $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS.Trim().ToLowerInvariant()
        return ($normalized -eq '1' -or $normalized -eq 'true')
    }

    return $true
}

function Test-RegistryAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return (Get-Variable -Name 'FragmentCommandRegistry' -Scope Global -ErrorAction SilentlyContinue) -and
        ($null -ne $global:FragmentCommandRegistry)
}

function Get-AutoLoadTimeoutSeconds {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $defaultTimeout = 30
    if (-not $env:PS_PROFILE_AUTO_LOAD_TIMEOUT) {
        return $defaultTimeout
    }

    $parsed = 0
    if ([int]::TryParse($env:PS_PROFILE_AUTO_LOAD_TIMEOUT.Trim(), [ref]$parsed) -and $parsed -gt 0) {
        return $parsed
    }

    return $defaultTimeout
}

function Invoke-CommandDispatcher {
    <#
    .SYNOPSIS
        Attempts to resolve a missing command by loading its fragment.

    .DESCRIPTION
        Checks the fragment command registry for the missing command name, loads
        the owning fragment when needed, and updates CommandLookupEventArgs when
        the command becomes available.

    .PARAMETER CommandName
        Name of the command PowerShell failed to resolve.

    .PARAMETER CommandLookupEventArgs
        Event args from CommandNotFoundAction used to return the resolved command.

    .OUTPUTS
        System.Boolean. True when the command was resolved after loading a fragment.

    .EXAMPLE
        Invoke-CommandDispatcher -CommandName 'gs' -CommandLookupEventArgs $eventArgs
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$CommandName,

        $CommandLookupEventArgs
    )

    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return $false
    }

    if (-not (Test-AutoLoadFragmentsEnabled)) {
        return $false
    }

    if (-not (Test-RegistryAvailable)) {
        return $false
    }

    $null = Get-AutoLoadTimeoutSeconds

    $dispatch = {
        if (-not (Get-SessionScopedCommand -Name 'Test-CommandInRegistry')) {
            return $false
        }

        if (-not (Test-CommandInRegistry -CommandName $CommandName)) {
            return $false
        }

        $loaded = $false
        $loadFragmentCommand = Get-SessionScopedCommand -Name 'Load-FragmentForCommand'
        if ($loadFragmentCommand) {
            $loaded = [bool](& $loadFragmentCommand -CommandName $CommandName)
        }

        if (-not $loaded) {
            return $false
        }

        $resolved = Get-SessionScopedCommand -Name $CommandName
        if ($resolved -and $CommandLookupEventArgs) {
            if ($CommandLookupEventArgs.PSObject.Properties.Match('CommandFound').Count -gt 0) {
                $CommandLookupEventArgs.CommandFound = $resolved
            }
            if ($CommandLookupEventArgs.PSObject.Properties.Match('StopSearch').Count -gt 0) {
                $CommandLookupEventArgs.StopSearch = $false
            }
        }

        return $null -ne $resolved
    }

    try {
        if (Get-SessionScopedCommand -Name 'Invoke-WithWideEvent') {
            return [bool](Invoke-WithWideEvent -OperationName 'fragment-dispatcher.invoke' -Context @{
                command_name = $CommandName
            } -ScriptBlock $dispatch)
        }

        return [bool](& $dispatch)
    }
    catch {
        return $false
    }
}

function Register-CommandDispatcher {
    <#
.SYNOPSIS
        Registers the command-not-found dispatcher.

    .DESCRIPTION
        Installs the module handler as the session CommandNotFoundAction while
        preserving the previous handler for fallback. No-op when auto-loading is
        disabled or the command registry is unavailable.

    .PARAMETER Force
        Re-registers the dispatcher even when it is already active.

    .OUTPUTS
        System.Boolean. True when the dispatcher is registered.

    .EXAMPLE
    Register-CommandDispatcher
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [switch]$Force
    )

    if ($script:DispatcherRegistered -and -not $Force) {
        return $true
    }

    if (-not (Test-AutoLoadFragmentsEnabled)) {
        return $false
    }

    if (-not (Test-RegistryAvailable)) {
        return $false
    }

    try {
        $currentHandler = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
        if ($currentHandler -ne $script:DispatcherHandler) {
            $script:PreviousCommandNotFoundAction = $currentHandler
        }

        $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $script:DispatcherHandler
        $script:DispatcherRegistered = $true
        return $true
    }
    catch {
        return $false
    }
}

function Unregister-CommandDispatcher {
    <#
.SYNOPSIS
        Unregisters the command-not-found dispatcher.

    .DESCRIPTION
        Restores the previous CommandNotFoundAction handler captured during
        registration and clears the module registration flag.

    .OUTPUTS
        System.Boolean. True when a registered dispatcher was removed.

    .EXAMPLE
    Unregister-CommandDispatcher
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not $script:DispatcherRegistered) {
        return $false
    }

    try {
        $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $script:PreviousCommandNotFoundAction
        $script:DispatcherRegistered = $false
        return $true
    }
    catch {
        return $false
    }
}

function Test-CommandDispatcherRegistered {
    <#
    .SYNOPSIS
        Tests whether the command dispatcher is registered.

    .DESCRIPTION
        Returns the module-local registration flag set by Register-CommandDispatcher.

    .OUTPUTS
        System.Boolean. True when the dispatcher is currently registered.

    .EXAMPLE
        if (-not (Test-CommandDispatcherRegistered)) { Register-CommandDispatcher }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [bool]$script:DispatcherRegistered
}

$script:DispatcherHandler = {
    param(
        [string]$CommandName,
        $CommandLookupEventArgs
    )

    $handled = $false
    if (Get-Command Invoke-CommandDispatcher -ErrorAction SilentlyContinue) {
        $handled = Invoke-CommandDispatcher -CommandName $CommandName -CommandLookupEventArgs $CommandLookupEventArgs
    }

    if (-not $handled -and $script:PreviousCommandNotFoundAction) {
        try {
            & $script:PreviousCommandNotFoundAction $CommandName $CommandLookupEventArgs
        }
        catch {
            # Preserve existing handler behavior
        }
    }
}.GetNewClosure()

Export-ModuleMember -Function @(
    'Invoke-CommandDispatcher'
    'Register-CommandDispatcher'
    'Unregister-CommandDispatcher'
    'Test-CommandDispatcherRegistered'
)
