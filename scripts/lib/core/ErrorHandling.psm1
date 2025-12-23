<#
scripts/lib/core/ErrorHandling.psm1

.SYNOPSIS
    Error handling utilities for consistent error action preference handling.

.DESCRIPTION
    Provides functions for extracting ErrorAction preference from PSBoundParameters
    and executing operations with consistent error handling. Reduces duplication of
    the common pattern for handling ErrorAction preference across modules.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Gets the ErrorAction preference from PSBoundParameters.

.DESCRIPTION
    Extracts the ErrorAction preference from PSBoundParameters with a default value.
    This is a common pattern used throughout the codebase for handling ErrorAction
    in functions with CmdletBinding.

.PARAMETER PSBoundParameters
    The PSBoundParameters hashtable from the calling function.

.PARAMETER Default
    The default ErrorAction value if not specified. Defaults to 'Stop'.

.OUTPUTS
    System.Management.Automation.ActionPreference. The ErrorAction preference value.

.EXAMPLE
    $errorActionPreference = Get-ErrorActionPreference -PSBoundParameters $PSBoundParameters

.EXAMPLE
    $errorActionPreference = Get-ErrorActionPreference -PSBoundParameters $PSBoundParameters -Default 'SilentlyContinue'
#>
function Get-ErrorActionPreference {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ActionPreference])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PSBoundParameters,

        [System.Management.Automation.ActionPreference]$Default = 'Stop'
    )

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        return $PSBoundParameters['ErrorAction']
    }

    return $Default
}

<#
.SYNOPSIS
    Executes a scriptblock with error handling based on ErrorAction preference.

.DESCRIPTION
    Executes a scriptblock and handles errors according to the specified ErrorAction
    preference. Provides consistent error handling across modules.

.PARAMETER ScriptBlock
    The scriptblock to execute.

.PARAMETER ErrorAction
    The ErrorAction preference. Defaults to 'Stop'.

.PARAMETER ErrorMessage
    Optional custom error message if execution fails.

.OUTPUTS
    The result of the scriptblock execution, or $null if ErrorAction is SilentlyContinue and execution fails.

.EXAMPLE
    $result = Invoke-WithErrorHandling -ScriptBlock { Get-Content $file } -ErrorAction 'Stop'

.EXAMPLE
    $result = Invoke-WithErrorHandling -ScriptBlock { Import-Module $module } -ErrorAction 'SilentlyContinue'
#>
function Invoke-WithErrorHandling {
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [System.Management.Automation.ActionPreference]$ErrorActionPreference = 'Stop',

        [string]$ErrorMessage
    )

    try {
        return & $ScriptBlock
    }
    catch {
        if ($ErrorActionPreference -eq 'Stop') {
            if ($ErrorMessage) {
                throw $ErrorMessage
            }
            throw
        }
        elseif ($ErrorActionPreference -eq 'Continue') {
            Write-Error -Message ($ErrorMessage ?? $_.Exception.Message) -Exception $_.Exception -ErrorAction Continue
            return $null
        }
        else {
            # SilentlyContinue or other - return null without error
            return $null
        }
    }
}

<#
.SYNOPSIS
    Writes an error or throws based on ErrorAction preference.

.DESCRIPTION
    Provides a consistent way to handle errors based on ErrorAction preference.
    Throws if ErrorAction is 'Stop', otherwise writes an error.

.PARAMETER Message
    The error message.

.PARAMETER ErrorAction
    The ErrorAction preference. Defaults to 'Stop'.

.PARAMETER Exception
    Optional exception object to include.

.PARAMETER ErrorId
    Optional error ID.

.PARAMETER Category
    Optional error category.

.OUTPUTS
    None. Throws if ErrorAction is 'Stop', otherwise writes error.

.EXAMPLE
    Write-ErrorOrThrow -Message "File not found: $path" -ErrorAction 'Stop'

.EXAMPLE
    Write-ErrorOrThrow -Message "Module not found" -ErrorAction 'SilentlyContinue'
#>
function Write-ErrorOrThrow {
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [System.Management.Automation.ActionPreference]$ErrorActionPreference = 'Stop',

        [Exception]$Exception,

        [string]$ErrorId,

        [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
    )

    if ($ErrorActionPreference -eq 'Stop') {
        if ($Exception) {
            throw $Exception
        }
        throw $Message
    }
    else {
        $errorParams = @{
            Message     = $Message
            ErrorAction = $ErrorActionPreference
            Category    = $Category
        }
        if ($Exception) {
            $errorParams['Exception'] = $Exception
        }
        if ($ErrorId) {
            $errorParams['ErrorId'] = $ErrorId
        }
        Write-Error @errorParams
    }
}

Export-ModuleMember -Function @(
    'Get-ErrorActionPreference',
    'Invoke-WithErrorHandling',
    'Write-ErrorOrThrow'
)

