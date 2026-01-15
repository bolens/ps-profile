<#
scripts/lib/core/DateTimeFormatting.psm1

.SYNOPSIS
    Date and time formatting utilities with locale fallback support.

.DESCRIPTION
    Provides unified date and time formatting functions that automatically
    use locale-aware formatting when available, with graceful fallback to
    standard formatting. Reduces duplication of the common pattern for
    date formatting throughout the codebase.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path $PSScriptRoot 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Formatting module for fallback support
$formattingModulePath = Join-Path $PSScriptRoot 'Formatting.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $formattingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($formattingModulePath -and -not [string]::IsNullOrWhiteSpace($formattingModulePath) -and (Test-Path -LiteralPath $formattingModulePath)) {
        Import-Module $formattingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Formats a DateTime object with locale-aware formatting if available.

.DESCRIPTION
    Unified date formatting function that uses Format-LocaleDate if available,
    otherwise falls back to standard DateTime formatting. This is the recommended
    way to format dates throughout the codebase.

.PARAMETER DateTime
    The DateTime object to format.

.PARAMETER Format
    The format string to use (e.g., 'yyyy-MM-dd HH:mm:ss', 'MMMM d, yyyy').

.PARAMETER Culture
    Optional CultureInfo for fallback formatting. Defaults to InvariantCulture.

.OUTPUTS
    System.String. The formatted date string.

.EXAMPLE
    $timestamp = Format-DateTime -DateTime (Get-Date) -Format 'yyyy-MM-dd HH:mm:ss'

.EXAMPLE
    $dateStr = Format-DateTime -DateTime $dateTime -Format 'MMMM d, yyyy'
#>
function Format-DateTime {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [DateTime]$DateTime,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Format,

        [System.Globalization.CultureInfo]$Culture
    )

    # Use Formatting module if available
    if (Get-Command Format-DateWithFallback -ErrorAction SilentlyContinue) {
        $params = @{
            Date   = $DateTime
            Format = $Format
        }
        if ($Culture) {
            $params['Culture'] = $Culture
        }
        return Format-DateWithFallback @params
    }

    # Fallback to direct implementation
    if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
        return Format-LocaleDate -Date $DateTime -Format $Format
    }

    $cultureInfo = if ($Culture) {
        $Culture
    }
    else {
        [System.Globalization.CultureInfo]::InvariantCulture
    }

    return $DateTime.ToString($Format, $cultureInfo)
}

<#
.SYNOPSIS
    Formats a DateTime object in ISO 8601 format.

.DESCRIPTION
    Formats a DateTime object in ISO 8601 format (e.g., '2024-01-15T14:30:00Z').
    Always uses UTC time and invariant culture for consistency.

.PARAMETER DateTime
    The DateTime object to format. If not specified, uses current UTC time.

.PARAMETER IncludeTimeZone
    If specified, includes timezone information in the format.

.OUTPUTS
    System.String. The ISO 8601 formatted date string.

.EXAMPLE
    $isoDate = Format-DateTimeISO -DateTime (Get-Date)

.EXAMPLE
    $isoDate = Format-DateTimeISO -DateTime $dateTime -IncludeTimeZone
#>
function Format-DateTimeISO {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [DateTime]$DateTime,

        [switch]$IncludeTimeZone
    )

    if (-not $PSBoundParameters.ContainsKey('DateTime')) {
        $DateTime = [DateTime]::UtcNow
    }
    elseif ($DateTime.Kind -ne [System.DateTimeKind]::Utc) {
        $DateTime = $DateTime.ToUniversalTime()
    }

    if ($IncludeTimeZone) {
        return $DateTime.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    else {
        # ISO 8601 without timezone: yyyy-MM-ddTHH:mm:ss
        return $DateTime.ToString('yyyy-MM-ddTHH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
    }
}

<#
.SYNOPSIS
    Formats a DateTime object for log entries.

.DESCRIPTION
    Formats a DateTime object in a standard log-friendly format:
    'yyyy-MM-dd HH:mm:ss'. This is the common format used for log timestamps.

.PARAMETER DateTime
    The DateTime object to format. If not specified, uses current UTC time.

.PARAMETER UseUTC
    If specified, uses UTC time. Otherwise uses local time. Defaults to $true.

.OUTPUTS
    System.String. The formatted date string for log entries.

.EXAMPLE
    $logTimestamp = Format-DateTimeLog -DateTime (Get-Date)

.EXAMPLE
    $logTimestamp = Format-DateTimeLog -UseUTC:$false
#>
function Format-DateTimeLog {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [DateTime]$DateTime,

        [bool]$UseUTC = $true
    )

    if (-not $PSBoundParameters.ContainsKey('DateTime')) {
        $DateTime = if ($UseUTC) {
            [DateTime]::UtcNow
        }
        else {
            Get-Date
        }
    }
    elseif ($UseUTC -and $DateTime.Kind -ne [System.DateTimeKind]::Utc) {
        $DateTime = $DateTime.ToUniversalTime()
    }

    return Format-DateTime -DateTime $DateTime -Format 'yyyy-MM-dd HH:mm:ss'
}

<#
.SYNOPSIS
    Formats a DateTime object in RFC 3339 format.

.DESCRIPTION
    Formats a DateTime object in RFC 3339 format (similar to ISO 8601 but
    with specific requirements). Always uses UTC time.

.PARAMETER DateTime
    The DateTime object to format. If not specified, uses current UTC time.

.OUTPUTS
    System.String. The RFC 3339 formatted date string.

.EXAMPLE
    $rfc3339 = Format-DateTimeRFC3339 -DateTime (Get-Date)
#>
function Format-DateTimeRFC3339 {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [DateTime]$DateTime
    )

    if (-not $PSBoundParameters.ContainsKey('DateTime')) {
        $DateTime = [DateTime]::UtcNow
    }
    elseif ($DateTime.Kind -ne [System.DateTimeKind]::Utc) {
        $DateTime = $DateTime.ToUniversalTime()
    }

    # RFC 3339 format: yyyy-MM-ddTHH:mm:ssZ
    return $DateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

<#
.SYNOPSIS
    Formats a DateTime object in a human-readable format.

.DESCRIPTION
    Formats a DateTime object in a human-readable format using locale-aware
    formatting if available. Falls back to standard formatting otherwise.

.PARAMETER DateTime
    The DateTime object to format.

.PARAMETER Format
    Optional format string. If not specified, uses a default human-readable format.

.OUTPUTS
    System.String. The human-readable formatted date string.

.EXAMPLE
    $humanDate = Format-DateTimeHuman -DateTime (Get-Date)

.EXAMPLE
    $humanDate = Format-DateTimeHuman -DateTime $dateTime -Format 'MMMM d, yyyy'
#>
function Format-DateTimeHuman {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [DateTime]$DateTime,

        [string]$Format
    )

    $formatString = if ($Format) {
        $Format
    }
    else {
        'MMMM d, yyyy'
    }

    return Format-DateTime -DateTime $DateTime -Format $formatString
}

# Export functions
Export-ModuleMember -Function @(
    'Format-DateTime',
    'Format-DateTimeISO',
    'Format-DateTimeLog',
    'Format-DateTimeRFC3339',
    'Format-DateTimeHuman'
)

