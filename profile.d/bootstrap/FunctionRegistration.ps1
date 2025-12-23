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
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Body,

        [switch]$ReturnScriptBlock
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or -not $Body) {
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
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Target,

        [switch]$ReturnDefinition
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Target)) {
        return $false
    }

    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return $false
    }

    Set-Alias -Name $Name -Value $Target -Scope Global -Force

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
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Initializer,

        [string]$Alias
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or -not $Initializer) {
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
        [AllowNull()]
        [AllowEmptyString()]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$CommandName,

        [string]$WarningMessage,

        [string]$InstallHint,

        [System.Management.Automation.CommandTypes]$CommandType = [System.Management.Automation.CommandTypes]::Application
    )

    if ([string]::IsNullOrWhiteSpace($FunctionName) -or [string]::IsNullOrWhiteSpace($CommandName)) {
        return $false
    }

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

