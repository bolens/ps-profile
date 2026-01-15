<#
scripts/lib/core/Formatting.psm1

.SYNOPSIS
    Conditional formatting utilities with fallback support.

.DESCRIPTION
    Provides functions for conditional formatting that gracefully fall back
    when optional formatting commands (like Format-LocaleDate) are not available.
    This reduces duplication of the common pattern: check if command exists,
    use it if available, otherwise use fallback.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Formats a date with locale-aware formatting if available, otherwise uses fallback.

.DESCRIPTION
    Attempts to use Format-LocaleDate if available, otherwise falls back to
    standard DateTime formatting. This is a common pattern used throughout
    the codebase for date formatting.

.PARAMETER Date
    The DateTime object to format.

.PARAMETER Format
    The format string to use (e.g., 'yyyy-MM-dd HH:mm:ss').

.PARAMETER FallbackFormat
    Optional fallback format string. If not specified, uses the same Format parameter.

.PARAMETER Culture
    Optional CultureInfo for fallback formatting. Defaults to InvariantCulture.

.OUTPUTS
    System.String. The formatted date string.

.EXAMPLE
    $timestamp = Format-DateWithFallback -Date (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'

.EXAMPLE
    $dateStr = Format-DateWithFallback -Date $dateTime -Format 'MMMM d, yyyy'
#>
function Format-DateWithFallback {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [DateTime]$Date,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Format,

        [string]$FallbackFormat,

        [System.Globalization.CultureInfo]$Culture
    )

    # Use locale-aware formatting if available
    # Only use Format-LocaleDate if Format parameter is valid (not 'invalid' or empty)
    $localeCmd = Get-Command Format-LocaleDate -ErrorAction SilentlyContinue
    if ($localeCmd -and $Format -and $Format -ne 'invalid' -and -not [string]::IsNullOrWhiteSpace($Format)) {
        try {
            return Format-LocaleDate -Date $Date -Format $Format
        }
        catch {
            # If Format-LocaleDate fails, fall through to standard formatting
            # This handles cases where Format-LocaleDate exists but doesn't support the format
        }
    }

    # Fallback to standard formatting
    $fallback = if ($FallbackFormat) {
        $FallbackFormat
    }
    else {
        $Format
    }

    $cultureInfo = if ($Culture) {
        $Culture
    }
    else {
        [System.Globalization.CultureInfo]::InvariantCulture
    }

    return $Date.ToString($fallback, $cultureInfo)
}

<#
.SYNOPSIS
    Formats a number with locale-aware formatting if available, otherwise uses fallback.

.DESCRIPTION
    Attempts to use Format-LocaleNumber if available, otherwise falls back to
    standard number formatting.

.PARAMETER Number
    The number to format.

.PARAMETER Format
    Optional format string (e.g., 'N2' for number with 2 decimal places).
    If not specified, uses default formatting.

.PARAMETER Culture
    Optional CultureInfo for fallback formatting. Defaults to InvariantCulture.

.OUTPUTS
    System.String. The formatted number string.

.EXAMPLE
    $formatted = Format-NumberWithFallback -Number 1234.56 -Format 'N2'
#>
function Format-NumberWithFallback {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [double]$Number,

        [string]$Format,

        [System.Globalization.CultureInfo]$Culture
    )

    # Use locale-aware formatting if available
    if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
        if ($Format) {
            return Format-LocaleNumber -Number $Number -Format $Format
        }
        else {
            return Format-LocaleNumber -Number $Number
        }
    }

    # Fallback to standard formatting
    $cultureInfo = if ($Culture) {
        $Culture
    }
    else {
        [System.Globalization.CultureInfo]::InvariantCulture
    }

    if ($Format) {
        return $Number.ToString($Format, $cultureInfo)
    }
    else {
        return $Number.ToString($cultureInfo)
    }
}

<#
.SYNOPSIS
    Invokes a command if it exists, otherwise uses a fallback value or scriptblock.

.DESCRIPTION
    Generic pattern for conditional command execution with fallback. Checks if
    a command exists, executes it if available, otherwise uses the fallback.

.PARAMETER CommandName
    The name of the command to check for and execute.

.PARAMETER Arguments
    Arguments to pass to the command if it exists.

.PARAMETER FallbackValue
    Value to return if command does not exist.

.PARAMETER FallbackScriptBlock
    ScriptBlock to execute if command does not exist. Takes precedence over FallbackValue.

.PARAMETER ErrorAction
    Error action to use when checking for command. Defaults to SilentlyContinue.

.OUTPUTS
    The result of the command execution or fallback value.

.EXAMPLE
    $result = Invoke-CommandWithFallback -CommandName 'Format-LocaleDate' `
        -Arguments @{ Date = (Get-Date); Format = 'yyyy-MM-dd' } `
        -FallbackScriptBlock { param($d, $f) $d.ToString($f) }

.EXAMPLE
    $value = Invoke-CommandWithFallback -CommandName 'Get-CustomValue' `
        -FallbackValue 'default'
#>
function Invoke-CommandWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [hashtable]$Arguments,

        # Note: Uses [object] intentionally to accept any fallback value type
        # (strings, numbers, hashtables, etc.) for maximum flexibility
        [object]$FallbackValue,

        [scriptblock]$FallbackScriptBlock
    )

    # Check if command exists
    $errorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) { $PSBoundParameters['ErrorAction'] } else { 'SilentlyContinue' }
    $command = Get-Command -Name $CommandName -ErrorAction $errorAction
    if ($null -ne $command) {
        # Execute command with arguments
        if ($Arguments) {
            return & $CommandName @Arguments
        }
        else {
            return & $CommandName
        }
    }

    # Use fallback
    if ($null -ne $FallbackScriptBlock) {
        if ($Arguments) {
            return & $FallbackScriptBlock @Arguments
        }
        else {
            return & $FallbackScriptBlock
        }
    }

    return $FallbackValue
}

<#
.SYNOPSIS
    Gets a command if it exists, otherwise returns a fallback value.

.DESCRIPTION
    Returns the command object if it exists, otherwise returns the fallback value.
    Useful for conditional command usage patterns.

.PARAMETER CommandName
    The name of the command to get.

.PARAMETER FallbackValue
    Value to return if command does not exist.

.PARAMETER ErrorAction
    Error action to use when checking for command. Defaults to SilentlyContinue.

.OUTPUTS
    System.Management.Automation.CommandInfo or the fallback value.

.EXAMPLE
    $formatCmd = Get-CommandWithFallback -CommandName 'Format-LocaleDate' -FallbackValue $null
    if ($formatCmd) {
        Format-LocaleDate -Date (Get-Date)
    }
#>
function Get-CommandWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,
        [ValidateNotNullOrEmpty()]

        # Note: Uses [object] intentionally to accept any fallback value type
        # (strings, numbers, hashtables, etc.) for maximum flexibility
        [object]$FallbackValue = $null
    )

    $errorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) { $PSBoundParameters['ErrorAction'] } else { 'SilentlyContinue' }
    $command = Get-Command -Name $CommandName -ErrorAction $errorAction
    if ($null -ne $command) {
        return $command
    }

    return $FallbackValue
}

# Export functions
Export-ModuleMember -Function @(
    'Format-DateWithFallback',
    'Format-NumberWithFallback',
    'Invoke-CommandWithFallback',
    'Get-CommandWithFallback'
)
