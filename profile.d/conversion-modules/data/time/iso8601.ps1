# ===============================================
# ISO 8601 date/time conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes ISO 8601 date/time conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ISO 8601 date/time format conversions.
    Supports conversions between ISO 8601 and DateTime objects, Unix timestamps, RFC 3339, and human-readable formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    ISO 8601 is an international standard for date and time representation.
    Supports various ISO 8601 formats including with/without timezone, with/without milliseconds.
#>
function Initialize-FileConversion-CoreTimeIso8601 {
    # ISO 8601 to DateTime
    Set-Item -Path Function:Global:_ConvertFrom-Iso8601ToDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Iso8601String
        )
        process {
            try {
                # Try parsing with RoundtripKind to preserve timezone information
                $dateTime = [DateTime]::Parse($Iso8601String, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
                return $dateTime
            }
            catch {
                # Try alternative parsing methods
                try {
                    $dateTime = [DateTimeOffset]::Parse($Iso8601String, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
                    return $dateTime.DateTime
                }
                catch {
                    throw "Failed to parse ISO 8601 string: $_"
                }
            }
        }
    } -Force

    # DateTime to ISO 8601
    Set-Item -Path Function:Global:_ConvertTo-Iso8601FromDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime,
            [switch]$IncludeMilliseconds,
            [switch]$IncludeTimezone
        )
        process {
            try {
                if ($IncludeTimezone) {
                    $dateTimeOffset = [DateTimeOffset]::new($DateTime)
                    if ($IncludeMilliseconds) {
                        return $dateTimeOffset.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
                    }
                    else {
                        return $dateTimeOffset.ToString('yyyy-MM-ddTHH:mm:ssK')
                    }
                }
                else {
                    if ($IncludeMilliseconds) {
                        return $DateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    }
                    else {
                        return $DateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
                    }
                }
            }
            catch {
                throw "Failed to convert DateTime to ISO 8601: $_"
            }
        }
    } -Force

    # ISO 8601 to Unix Timestamp
    Set-Item -Path Function:Global:_ConvertFrom-Iso8601ToUnixTimestamp -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Iso8601String
        )
        process {
            try {
                $dateTime = _ConvertFrom-Iso8601ToDateTime -Iso8601String $Iso8601String
                return _ConvertTo-UnixTimestampFromDateTime -DateTime $dateTime
            }
            catch {
                throw "Failed to convert ISO 8601 to Unix timestamp: $_"
            }
        }
    } -Force

    # Unix Timestamp to ISO 8601
    Set-Item -Path Function:Global:_ConvertTo-Iso8601FromUnixTimestamp -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$UnixTimestamp,
            [switch]$IncludeMilliseconds,
            [switch]$IncludeTimezone
        )
        process {
            try {
                $dateTime = _ConvertFrom-UnixTimestampToDateTime -UnixTimestamp $UnixTimestamp
                return _ConvertTo-Iso8601FromDateTime -DateTime $dateTime -IncludeMilliseconds:$IncludeMilliseconds -IncludeTimezone:$IncludeTimezone
            }
            catch {
                throw "Failed to convert Unix timestamp to ISO 8601: $_"
            }
        }
    } -Force

    # ISO 8601 to RFC 3339 (RFC 3339 is a profile of ISO 8601)
    Set-Item -Path Function:Global:_ConvertFrom-Iso8601ToRfc3339 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Iso8601String
        )
        process {
            try {
                # RFC 3339 is essentially ISO 8601 with some restrictions
                # Most ISO 8601 strings are valid RFC 3339, but we normalize it
                $dateTime = _ConvertFrom-Iso8601ToDateTime -Iso8601String $Iso8601String
                $dateTimeOffset = [DateTimeOffset]::new($dateTime)
                return $dateTimeOffset.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
            }
            catch {
                throw "Failed to convert ISO 8601 to RFC 3339: $_"
            }
        }
    } -Force

    # RFC 3339 to ISO 8601
    Set-Item -Path Function:Global:_ConvertTo-Iso8601FromRfc3339 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Rfc3339String
        )
        process {
            try {
                # RFC 3339 is a subset of ISO 8601, so we can parse it the same way
                return _ConvertFrom-Iso8601ToDateTime -Iso8601String $Rfc3339String | _ConvertTo-Iso8601FromDateTime
            }
            catch {
                throw "Failed to convert RFC 3339 to ISO 8601: $_"
            }
        }
    } -Force

    # ISO 8601 to Human-readable
    Set-Item -Path Function:Global:_ConvertFrom-Iso8601ToHumanReadable -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Iso8601String,
            [string]$Format = 'F'
        )
        process {
            try {
                $dateTime = _ConvertFrom-Iso8601ToDateTime -Iso8601String $Iso8601String
                return $dateTime.ToString($Format)
            }
            catch {
                throw "Failed to convert ISO 8601 to human-readable format: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ISO 8601 to DateTime
<#
.SYNOPSIS
    Converts an ISO 8601 date/time string to a DateTime object.
.DESCRIPTION
    Converts an ISO 8601 formatted date/time string to a DateTime object.
    Supports various ISO 8601 formats including with/without timezone and milliseconds.
.PARAMETER Iso8601String
    The ISO 8601 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToDateTime
    
    Converts an ISO 8601 string to a DateTime object.
.EXAMPLE
    '2021-01-01T12:30:45.123+05:00' | ConvertFrom-Iso8601ToDateTime
    
    Converts an ISO 8601 string with timezone and milliseconds.
.OUTPUTS
    System.DateTime
    Returns a DateTime object representing the ISO 8601 date/time.
#>
function ConvertFrom-Iso8601ToDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Iso8601String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Iso8601ToDateTime @PSBoundParameters
}
Set-Alias -Name iso8601-to-datetime -Value ConvertFrom-Iso8601ToDateTime -ErrorAction SilentlyContinue

# Convert DateTime to ISO 8601
<#
.SYNOPSIS
    Converts a DateTime object to ISO 8601 format.
.DESCRIPTION
    Converts a DateTime object to an ISO 8601 formatted date/time string.
.PARAMETER DateTime
    The DateTime object to convert.
.PARAMETER IncludeMilliseconds
    Include milliseconds in the output (default: false).
.PARAMETER IncludeTimezone
    Include timezone information in the output (default: false).
.EXAMPLE
    Get-Date | ConvertTo-Iso8601FromDateTime
    
    Converts the current date/time to ISO 8601 format.
.EXAMPLE
    Get-Date | ConvertTo-Iso8601FromDateTime -IncludeMilliseconds -IncludeTimezone
    
    Converts with milliseconds and timezone information.
.OUTPUTS
    System.String
    Returns an ISO 8601 formatted date/time string.
#>
function ConvertTo-Iso8601FromDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime,
        [switch]$IncludeMilliseconds,
        [switch]$IncludeTimezone
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Iso8601FromDateTime @PSBoundParameters
}
Set-Alias -Name datetime-to-iso8601 -Value ConvertTo-Iso8601FromDateTime -ErrorAction SilentlyContinue

# Convert ISO 8601 to Unix Timestamp
<#
.SYNOPSIS
    Converts an ISO 8601 date/time string to a Unix timestamp.
.DESCRIPTION
    Converts an ISO 8601 formatted date/time string to a Unix timestamp.
.PARAMETER Iso8601String
    The ISO 8601 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToUnixTimestamp
    
    Converts an ISO 8601 string to a Unix timestamp.
.OUTPUTS
    System.Int64
    Returns a Unix timestamp as a long integer.
#>
function ConvertFrom-Iso8601ToUnixTimestamp {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Iso8601String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Iso8601ToUnixTimestamp @PSBoundParameters
}
Set-Alias -Name iso8601-to-unix -Value ConvertFrom-Iso8601ToUnixTimestamp -ErrorAction SilentlyContinue

# Convert Unix Timestamp to ISO 8601
<#
.SYNOPSIS
    Converts a Unix timestamp to ISO 8601 format.
.DESCRIPTION
    Converts a Unix timestamp to an ISO 8601 formatted date/time string.
.PARAMETER UnixTimestamp
    The Unix timestamp to convert.
.PARAMETER IncludeMilliseconds
    Include milliseconds in the output (default: false).
.PARAMETER IncludeTimezone
    Include timezone information in the output (default: false).
.EXAMPLE
    1609459200 | ConvertTo-Iso8601FromUnixTimestamp
    
    Converts a Unix timestamp to ISO 8601 format.
.OUTPUTS
    System.String
    Returns an ISO 8601 formatted date/time string.
#>
function ConvertTo-Iso8601FromUnixTimestamp {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$UnixTimestamp,
        [switch]$IncludeMilliseconds,
        [switch]$IncludeTimezone
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Iso8601FromUnixTimestamp @PSBoundParameters
}
Set-Alias -Name unix-to-iso8601 -Value ConvertTo-Iso8601FromUnixTimestamp -ErrorAction SilentlyContinue

# Convert ISO 8601 to RFC 3339
<#
.SYNOPSIS
    Converts an ISO 8601 date/time string to RFC 3339 format.
.DESCRIPTION
    Converts an ISO 8601 formatted date/time string to RFC 3339 format.
    RFC 3339 is a profile of ISO 8601 with some restrictions.
.PARAMETER Iso8601String
    The ISO 8601 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToRfc3339
    
    Converts an ISO 8601 string to RFC 3339 format.
.OUTPUTS
    System.String
    Returns an RFC 3339 formatted date/time string.
#>
function ConvertFrom-Iso8601ToRfc3339 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Iso8601String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Iso8601ToRfc3339 @PSBoundParameters
}
Set-Alias -Name iso8601-to-rfc3339 -Value ConvertFrom-Iso8601ToRfc3339 -ErrorAction SilentlyContinue

# Convert RFC 3339 to ISO 8601
<#
.SYNOPSIS
    Converts an RFC 3339 date/time string to ISO 8601 format.
.DESCRIPTION
    Converts an RFC 3339 formatted date/time string to ISO 8601 format.
    RFC 3339 is a profile of ISO 8601, so conversion is straightforward.
.PARAMETER Rfc3339String
    The RFC 3339 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertTo-Iso8601FromRfc3339
    
    Converts an RFC 3339 string to ISO 8601 format.
.OUTPUTS
    System.String
    Returns an ISO 8601 formatted date/time string.
#>
function ConvertTo-Iso8601FromRfc3339 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Rfc3339String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Iso8601FromRfc3339 @PSBoundParameters
}
Set-Alias -Name rfc3339-to-iso8601 -Value ConvertTo-Iso8601FromRfc3339 -ErrorAction SilentlyContinue

# Convert ISO 8601 to Human-readable
<#
.SYNOPSIS
    Converts an ISO 8601 date/time string to a human-readable format.
.DESCRIPTION
    Converts an ISO 8601 formatted date/time string to a human-readable date/time format.
.PARAMETER Iso8601String
    The ISO 8601 formatted date/time string to convert.
.PARAMETER Format
    The format string to use (default: 'F' for full date/time).
    See DateTime.ToString() format strings for options.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToHumanReadable
    
    Converts an ISO 8601 string to a human-readable format.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToHumanReadable -Format 'yyyy-MM-dd'
    
    Converts using a custom format.
.OUTPUTS
    System.String
    Returns a human-readable date/time string.
#>
function ConvertFrom-Iso8601ToHumanReadable {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Iso8601String,
        [string]$Format = 'F'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Iso8601ToHumanReadable @PSBoundParameters
}
Set-Alias -Name iso8601-to-readable -Value ConvertFrom-Iso8601ToHumanReadable -ErrorAction SilentlyContinue

