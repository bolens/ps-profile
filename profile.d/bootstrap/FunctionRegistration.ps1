# ===============================================
# FunctionRegistration.ps1
# Function and alias registration utilities
# ===============================================

<#
.SYNOPSIS
    Registers a collision-safe function in the global scope.
.DESCRIPTION
    Creates a function unless one already exists. When ReturnScriptBlock is
    specified, the created script block is returned for reuse.
.PARAMETER Name
    Name of the function to create.
.PARAMETER Body
    Script block executed when the function runs.
.PARAMETER ReturnScriptBlock
    Returns the created script block instead of $true/$false.
.OUTPUTS
    System.Boolean or System.Management.Automation.ScriptBlock
#>
function global:Set-AgentModeFunction {
    [CmdletBinding()]
    [OutputType([bool], [System.Management.Automation.ScriptBlock])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [scriptblock]$Body,

        [switch]$ReturnScriptBlock
    )

    # Validation attributes handle null/empty checks, but keep for explicit error handling
    if (-not $Body) {
        return $false
    }

    $existing = Get-Command -Name $Name -ErrorAction SilentlyContinue
    $allowReplace = $global:AgentModeReplaceAllowed.Contains($Name)

    # Prevent accidental overwrites unless explicitly allowed (used by lazy-loading)
    if ($existing -and -not $allowReplace) {
        return $false
    }

    # Create closure to capture variables from defining scope
    $scriptBlock = $Body.GetNewClosure()
    Set-Item -Path ("Function:\global:" + $Name) -Value $scriptBlock -Force | Out-Null

    # Clean up allow-list entry after successful replacement
    if ($allowReplace) {
        [void]$global:AgentModeReplaceAllowed.Remove($Name)
    }

    # Auto-register command in fragment registry if available
    if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
        $fragmentName = $null
        # Try to get fragment name from context
        if (Get-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue) {
            $fragmentName = $global:CurrentFragmentContext
        }
        # If context is set, register the command
        if ($fragmentName) {
            try {
                $null = Register-FragmentCommand -CommandName $Name -FragmentName $fragmentName -CommandType 'Function'
            }
            catch {
                # Silently fail - registry is optional
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to register command '$Name' in registry: $($_.Exception.Message)"
                }
            }
        }
    }

    if ($ReturnScriptBlock) {
        return $scriptBlock
    }

    return $true
}

<#
.SYNOPSIS
    Registers a collision-safe alias in the global scope.
.DESCRIPTION
    Creates an alias only when it does not already exist. Optionally returns
    the alias definition string for diagnostic scenarios.
.PARAMETER Name
    Alias name to register.
.PARAMETER Target
    Target command or function the alias should invoke.
.PARAMETER ReturnDefinition
    Returns the alias definition instead of $true/$false.
.OUTPUTS
    System.Boolean or System.String
#>
function global:Set-AgentModeAlias {
    [CmdletBinding()]
    [OutputType([bool], [string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Target,

        [switch]$ReturnDefinition
    )

    # Validation attributes handle null/empty checks

    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return $false
    }

    Set-Alias -Name $Name -Value $Target -Scope Global -Force

    # Auto-register alias in fragment registry if available
    if (Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue) {
        $fragmentName = $null
        # Try to get fragment name from context
        if (Get-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue) {
            $fragmentName = $global:CurrentFragmentContext
        }
        # If context is set, register the alias
        if ($fragmentName) {
            try {
                $null = Register-FragmentCommand -CommandName $Name -FragmentName $fragmentName -CommandType 'Alias' -Target $Target
            }
            catch {
                # Silently fail - registry is optional
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to register alias '$Name' in registry: $($_.Exception.Message)"
                }
            }
        }
    }

    if ($ReturnDefinition) {
        $alias = Get-Alias -Name $Name -ErrorAction SilentlyContinue
        if ($alias) {
            return "$($alias.Name) -> $($alias.Definition)"
        }
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Registers a lazy-loading function stub.
.DESCRIPTION
    Creates a stub that runs the provided initializer on first use, allowing
    expensive setup work to be deferred. Optionally creates an alias that
    points to the stubbed function.
.PARAMETER Name
    Function name to register.
.PARAMETER Initializer
    Script block that performs initialization and defines the real function.
.PARAMETER Alias
    Optional alias name for the lazy-loaded function.
.OUTPUTS
    System.Boolean
#>
function global:Register-LazyFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [scriptblock]$Initializer,

        [ValidateNotNullOrEmpty()]
        [string]$Alias
    )

    # Validation attributes handle null/empty checks, but keep for explicit error handling
    if (-not $Initializer) {
        return $false
    }

    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return $false
    }

    # Allow this function to be replaced when the initializer runs
    [void]$global:AgentModeReplaceAllowed.Add($Name)
    $initBlock = $Initializer

    # Create stub function that runs initializer on first call, then delegates to the real function
    $stub = {
        $null = & $initBlock
        $targetName = $MyInvocation.MyCommand.Name
        if (-not (Get-Command -Name $targetName -CommandType Function -ErrorAction SilentlyContinue)) {
            throw "Initializer failed to define function '$targetName'."
        }
        & $targetName @args
    }.GetNewClosure()

    Set-Item -Path ("Function:\global:" + $Name) -Value $stub -Force | Out-Null

    if ($Alias) {
        Set-AgentModeAlias -Name $Alias -Target $Name | Out-Null
    }

    return $true
}

<#
.SYNOPSIS
    Registers a standardized wrapper function for an external tool.

.DESCRIPTION
    Creates a function that wraps an external command with standardized error handling.
    The wrapper checks for command availability using cached command detection and
    provides helpful warnings when the tool is missing.

.PARAMETER FunctionName
    Name of the function to create (usually matches the command name).

.PARAMETER CommandName
    Name of the external command to wrap.

.PARAMETER WarningMessage
    Custom warning message when command is not found. If not specified, uses default format.

.PARAMETER InstallHint
    Installation hint to display when command is missing (e.g., "Install with: scoop install bat").

.PARAMETER CommandType
    Type of command to look for. Defaults to 'Application' (external executables).

.EXAMPLE
    Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'

    Creates a 'bat' function that wraps the 'bat' command.

.EXAMPLE
    Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'

    Creates an 'fd' function that wraps the 'fd' command.
#>
function global:Register-ToolWrapper {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,

        [string]$WarningMessage,

        [string]$InstallHint,

        [System.Management.Automation.CommandTypes]$CommandType = [System.Management.Automation.CommandTypes]::Application
    )

    # Validation attributes handle null/empty checks

    # Capture variables in a hashtable for closure (more reliable than individual variables)
    $captured = @{
        CommandName    = $CommandName
        CommandType    = $CommandType
        InstallHint    = $InstallHint
        WarningMessage = $WarningMessage
    }

    # Create the wrapper function body with closure
    $body = {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            $Arguments
        )

        # Use Test-CachedCommand if available, otherwise fall back to Get-Command
        $commandAvailable = $false
        $commandInfo = $null

        if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
            $commandAvailable = Test-CachedCommand -Name $captured.CommandName
            if ($commandAvailable) {
                $commandInfo = Get-Command -Name $captured.CommandName -CommandType $captured.CommandType -ErrorAction SilentlyContinue
            }
            else {
                # Test-CachedCommand returned false, but try Get-Command anyway as fallback
                # (Test-CachedCommand might not find cmdlets/functions that Get-Command can find)
                # Try with specified CommandType first, then without restriction if that fails
                $commandInfo = Get-Command -Name $captured.CommandName -CommandType $captured.CommandType -ErrorAction SilentlyContinue
                if (-not $commandInfo) {
                    $commandInfo = Get-Command -Name $captured.CommandName -ErrorAction SilentlyContinue
                }
                $commandAvailable = $null -ne $commandInfo
            }
        }
        else {
            # Fallback to Get-Command directly
            # Try with specified CommandType first, then without restriction if that fails
            $commandInfo = Get-Command -Name $captured.CommandName -CommandType $captured.CommandType -ErrorAction SilentlyContinue
            if (-not $commandInfo) {
                $commandInfo = Get-Command -Name $captured.CommandName -ErrorAction SilentlyContinue
            }
            $commandAvailable = $null -ne $commandInfo
        }

        if ($commandAvailable -and $commandInfo) {
            # Command is available, execute it with provided arguments
            & $commandInfo @Arguments
        }
        else {
            # Command not found - use standard error handling
            if ($captured.InstallHint) {
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -Tool $captured.CommandName -InstallHint $captured.InstallHint
                }
                else {
                    Write-Warning "$($captured.CommandName) not found. $($captured.InstallHint)"
                }
            }
            elseif ($captured.WarningMessage) {
                Write-Warning $captured.WarningMessage
            }
            else {
                Write-Warning "$($captured.CommandName) not found"
            }
        }
    }

    # Check idempotency (same logic as Set-AgentModeFunction)
    $existing = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue
    if ($existing) {
        return $false
    }

    # Create closure to capture the hashtable, then set the function directly
    # This avoids the double-closure issue with Set-AgentModeFunction
    $scriptBlock = $body.GetNewClosure()
    Set-Item -Path ("Function:\global:" + $FunctionName) -Value $scriptBlock -Force | Out-Null
    
    return $true
}

<#
.SYNOPSIS
    Creates a proxy function that loads its fragment on-demand.

.DESCRIPTION
    Creates a function that automatically loads the fragment containing the command
    before executing it. This enables commands to work even if the profile hasn't
    loaded or the fragment is disabled.

.PARAMETER CommandName
    The name of the command to create a proxy for.

.PARAMETER FragmentName
    Optional fragment name. If not specified, looks up from command registry.

.EXAMPLE
    New-FragmentCommandProxy -CommandName 'Invoke-Aws'

    Creates a proxy function for Invoke-Aws that loads the aws fragment on-demand.
#>
function global:New-FragmentCommandProxy {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName
    )

    # Validation attributes handle null/empty checks

    # Check if FragmentLoader module is available
    if (-not (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue)) {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "FragmentLoader module not available, cannot create proxy for: $CommandName"
        }
        return $false
    }

    # Get fragment name if not provided
    if (-not $FragmentName) {
        if (Get-Command Get-FragmentForCommand -ErrorAction SilentlyContinue) {
            $FragmentName = Get-FragmentForCommand -CommandName $CommandName
            if (-not $FragmentName) {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Command '$CommandName' not found in registry, cannot create proxy"
                }
                return $false
            }
        }
        else {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Command registry not available, cannot create proxy for: $CommandName"
            }
            return $false
        }
    }

    # Check if function already exists (and is not a proxy)
    $existing = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if ($existing -and $existing.CommandType -eq 'Function') {
        # Check if it's already a proxy by looking for Load-FragmentForCommand in the function body
        $func = Get-Item -Path "Function:\global:$CommandName"
        if ($func.ScriptBlock.ToString() -match 'Load-FragmentForCommand') {
            # Already a proxy, skip
            return $true
        }
        # Function exists and is not a proxy - don't overwrite
        return $false
    }

    # Create proxy function
    $proxyBody = {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            $Arguments
        )

        # Load fragment if needed
        $fragmentName = $using:FragmentName
        $commandName = $using:CommandName

        if (Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue) {
            $null = Load-FragmentForCommand -CommandName $commandName
        }
        elseif (Get-Command Load-Fragment -ErrorAction SilentlyContinue) {
            $null = Load-Fragment -FragmentName $fragmentName
        }

        # Get the actual command and execute it
        $actualCommand = Get-Command -Name $commandName -ErrorAction SilentlyContinue
        if ($actualCommand) {
            & $actualCommand @Arguments
        }
        else {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.Management.Automation.CommandNotFoundException]::new("Command not found after loading fragment: $commandName"),
                        'CommandNotFoundAfterLoad',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $commandName
                    )) -OperationName 'fragment-command-proxy.execute' -Context @{
                    command_name  = $commandName
                    fragment_name = $fragmentName
                }
            }
            else {
                Write-Error "Command '$commandName' not found after loading fragment '$fragmentName'"
            }
        }
    }.GetNewClosure()

    # Set the proxy function
    Set-Item -Path ("Function:\global:" + $CommandName) -Value $proxyBody -Force | Out-Null

    if ($env:PS_PROFILE_DEBUG) {
        Write-Verbose "Created proxy function for '$CommandName' -> fragment '$FragmentName'"
    }

    return $true
}

<#
.SYNOPSIS
    Registers a function and optional aliases in a single call.

.DESCRIPTION
    Convenience function that registers a function and its aliases together.
    This reduces boilerplate when registering functions with multiple aliases.

.PARAMETER Name
    Name of the function to register.

.PARAMETER Body
    Script block for the function body.

.PARAMETER Aliases
    Array of alias names to create for this function.

.EXAMPLE
    Register-FragmentFunction -Name 'Invoke-Aws' -Body ${function:Invoke-Aws} -Aliases @('aws')

    Registers Invoke-Aws function and creates 'aws' alias.

.EXAMPLE
    Register-FragmentFunction -Name 'Get-GitStatus' -Body { git status } -Aliases @('gst', 'gs')

    Registers Get-GitStatus function with two aliases.
#>
function global:Register-FragmentFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [scriptblock]$Body,

        [string[]]$Aliases = @()
    )

    # Validation attributes handle null/empty checks, but keep for explicit error handling
    if (-not $Body) {
        return $false
    }

    # Register the function
    $functionResult = Set-AgentModeFunction -Name $Name -Body $Body
    if (-not $functionResult) {
        return $false
    }

    # Register aliases if provided
    foreach ($alias in $Aliases) {
        if (-not [string]::IsNullOrWhiteSpace($alias)) {
            Set-AgentModeAlias -Name $alias -Target $Name | Out-Null
        }
    }

    return $true
}

