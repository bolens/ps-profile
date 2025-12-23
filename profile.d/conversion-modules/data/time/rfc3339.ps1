# ===============================================
# RFC 3339 date/time conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes RFC 3339 date/time conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for RFC 3339 date/time format conversions.
    RFC 3339 is a profile of ISO 8601 with specific formatting requirements.
    Supports conversions between RFC 3339 and DateTime objects, Unix timestamps, ISO 8601, and human-readable formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    RFC 3339 format: yyyy-MM-ddTHH:mm:ss[.fff]Z or yyyy-MM-ddTHH:mm:ss[.fff]+HH:mm
    RFC 3339 requires timezone information (Z for UTC or +/-HH:mm offset).
#>
function Initialize-FileConversion-CoreTimeRfc3339 {
    # RFC 3339 to DateTime
    Set-Item -Path Function:Global:_ConvertFrom-Rfc3339ToDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Rfc3339String
        )
        process {
            try {
                # RFC 3339 is a subset of ISO 8601, so we can parse it the same way
                $dateTime = [DateTimeOffset]::Parse($Rfc3339String, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
                return $dateTime.DateTime
            }
            catch {
                throw "Failed to parse RFC 3339 string: $_"
            }
        }
    } -Force

    # DateTime to RFC 3339
    Set-Item -Path Function:Global:_ConvertTo-Rfc3339FromDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime,
            [switch]$IncludeMilliseconds,
            [switch]$UseLocalTimezone
        )
        process {
            try {
                if ($UseLocalTimezone) {
                    $offset = [TimeZoneInfo]::Local.GetUtcOffset($DateTime)
                    $dateTimeOffset = [DateTimeOffset]::new($DateTime, $offset)
                }
                else {
                    # Treat as UTC - use FromDateTime to handle timezone properly
                    if ($DateTime.Kind -eq [DateTimeKind]::Utc) {
                        $dateTimeOffset = [DateTimeOffset]::new($DateTime)
                    }
                    else {
                        # Assume UTC if kind is unspecified
                        $utcDateTime = [DateTime]::SpecifyKind($DateTime, [DateTimeKind]::Utc)
                        $dateTimeOffset = [DateTimeOffset]::new($utcDateTime)
                    }
                }
                if ($IncludeMilliseconds) {
                    $format = 'yyyy-MM-ddTHH:mm:ss.fffK'
                }
                else {
                    $format = 'yyyy-MM-ddTHH:mm:ssK'
                }
                return $dateTimeOffset.ToString($format)
            }
            catch {
                throw "Failed to convert DateTime to RFC 3339: $_"
            }
        }
    } -Force

    # Unix Timestamp to RFC 3339
    Set-Item -Path Function:Global:_ConvertTo-Rfc3339FromUnixTimestamp -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$UnixTimestamp,
            [switch]$IncludeMilliseconds
        )
        process {
            try {
                # Unix timestamps are always UTC, so convert directly
                $epoch = [DateTimeOffset]::FromUnixTimeSeconds([long]$UnixTimestamp)
                if ($IncludeMilliseconds) {
                    # Handle milliseconds if present
                    $milliseconds = ($UnixTimestamp - [long]$UnixTimestamp) * 1000
                    if ($milliseconds -gt 0) {
                        $epoch = $epoch.AddMilliseconds($milliseconds)
                    }
                    return $epoch.ToString('yyyy-MM-ddTHH:mm:ss.fffK')
                }
                else {
                    return $epoch.ToString('yyyy-MM-ddTHH:mm:ssK')
                }
            }
            catch {
                throw "Failed to convert Unix timestamp to RFC 3339: $_"
            }
        }
    } -Force

    # RFC 3339 to Unix Timestamp
    Set-Item -Path Function:Global:_ConvertFrom-Rfc3339ToUnixTimestamp -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Rfc3339String
        )
        process {
            try {
                # Parse as DateTimeOffset to preserve timezone information
                $dateTimeOffset = [DateTimeOffset]::Parse($Rfc3339String, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
                # Convert to Unix timestamp (always UTC)
                $unixSeconds = $dateTimeOffset.ToUnixTimeSeconds()
                # Add milliseconds if present
                $milliseconds = $dateTimeOffset.Millisecond
                $unixTimestamp = [double]$unixSeconds
                if ($milliseconds -gt 0) {
                    $unixTimestamp += $milliseconds / 1000.0
                }
                return $unixTimestamp
            }
            catch {
                throw "Failed to convert RFC 3339 to Unix timestamp: $_"
            }
        }
    } -Force

    # ISO 8601 to RFC 3339
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
                $dateTime = _ConvertFrom-Rfc3339ToDateTime -Rfc3339String $Rfc3339String
                return _ConvertTo-Iso8601FromDateTime -DateTime $dateTime
            }
            catch {
                throw "Failed to convert RFC 3339 to ISO 8601: $_"
            }
        }
    } -Force

    # RFC 3339 to Human-readable
    Set-Item -Path Function:Global:_ConvertFrom-Rfc3339ToHumanReadable -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Rfc3339String,
            [string]$Format = 'F'
        )
        process {
            try {
                $dateTime = _ConvertFrom-Rfc3339ToDateTime -Rfc3339String $Rfc3339String
                return $dateTime.ToString($Format)
            }
            catch {
                throw "Failed to convert RFC 3339 to human-readable format: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert RFC 3339 to DateTime
<#
.SYNOPSIS
    Converts an RFC 3339 date/time string to a DateTime object.
.DESCRIPTION
    Converts an RFC 3339 formatted date/time string to a DateTime object.
    RFC 3339 is a profile of ISO 8601 with specific formatting requirements.
.PARAMETER Rfc3339String
    The RFC 3339 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Rfc3339ToDateTime
    
    Converts an RFC 3339 string to a DateTime object.
.EXAMPLE
    '2021-01-01T12:30:45.123+05:00' | ConvertFrom-Rfc3339ToDateTime
    
    Converts an RFC 3339 string with timezone and milliseconds.
.OUTPUTS
    System.DateTime
    Returns a DateTime object representing the RFC 3339 date/time.
#>
function ConvertFrom-Rfc3339ToDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Rfc3339String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Rfc3339ToDateTime @PSBoundParameters
}
Set-Alias -Name rfc3339-to-datetime -Value ConvertFrom-Rfc3339ToDateTime -ErrorAction SilentlyContinue

# Convert DateTime to RFC 3339
<#
.SYNOPSIS
    Converts a DateTime object to RFC 3339 format.
.DESCRIPTION
    Converts a DateTime object to RFC 3339 formatted date/time string.
    RFC 3339 requires timezone information (Z for UTC or +/-HH:mm offset).
.PARAMETER DateTime
    The DateTime object to convert.
.PARAMETER IncludeMilliseconds
    Include milliseconds in the output format.
.PARAMETER UseLocalTimezone
    Use local timezone offset instead of UTC.
.EXAMPLE
    Get-Date | ConvertTo-Rfc3339FromDateTime
    
    Converts current date/time to RFC 3339 format.
.EXAMPLE
    Get-Date | ConvertTo-Rfc3339FromDateTime -IncludeMilliseconds
    
    Converts current date/time to RFC 3339 format with milliseconds.
.OUTPUTS
    System.String
    Returns an RFC 3339 formatted date/time string.
#>
function ConvertTo-Rfc3339FromDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime,
        [switch]$IncludeMilliseconds,
        [switch]$UseLocalTimezone
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Rfc3339FromDateTime @PSBoundParameters
}
Set-Alias -Name datetime-to-rfc3339 -Value ConvertTo-Rfc3339FromDateTime -ErrorAction SilentlyContinue

# Convert Unix Timestamp to RFC 3339
<#
.SYNOPSIS
    Converts a Unix timestamp to RFC 3339 format.
.DESCRIPTION
    Converts a Unix timestamp (seconds since epoch) to RFC 3339 formatted date/time string.
.PARAMETER UnixTimestamp
    The Unix timestamp to convert.
.PARAMETER IncludeMilliseconds
    Include milliseconds in the output format.
.EXAMPLE
    1609459200 | ConvertTo-Rfc3339FromUnixTimestamp
    
    Converts Unix timestamp to RFC 3339 format.
.OUTPUTS
    System.String
    Returns an RFC 3339 formatted date/time string.
#>
function ConvertTo-Rfc3339FromUnixTimestamp {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$UnixTimestamp,
        [switch]$IncludeMilliseconds
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-Rfc3339FromUnixTimestamp @PSBoundParameters
}
Set-Alias -Name unix-to-rfc3339 -Value ConvertTo-Rfc3339FromUnixTimestamp -ErrorAction SilentlyContinue

# Convert RFC 3339 to Unix Timestamp
<#
.SYNOPSIS
    Converts an RFC 3339 date/time string to a Unix timestamp.
.DESCRIPTION
    Converts an RFC 3339 formatted date/time string to a Unix timestamp (seconds since epoch).
.PARAMETER Rfc3339String
    The RFC 3339 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Rfc3339ToUnixTimestamp
    
    Converts RFC 3339 string to Unix timestamp.
.OUTPUTS
    System.Double
    Returns a Unix timestamp (seconds since epoch).
#>
function ConvertFrom-Rfc3339ToUnixTimestamp {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Rfc3339String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Rfc3339ToUnixTimestamp @PSBoundParameters
}
Set-Alias -Name rfc3339-to-unix -Value ConvertFrom-Rfc3339ToUnixTimestamp -ErrorAction SilentlyContinue

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

# Convert RFC 3339 to Human-readable
<#
.SYNOPSIS
    Converts an RFC 3339 date/time string to a human-readable format.
.DESCRIPTION
    Converts an RFC 3339 formatted date/time string to a human-readable date/time format.
.PARAMETER Rfc3339String
    The RFC 3339 formatted date/time string to convert.
.PARAMETER Format
    The format string to use (default: 'F' for full date/time).
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertFrom-Rfc3339ToHumanReadable
    
    Converts RFC 3339 string to human-readable format.
.OUTPUTS
    System.String
    Returns a human-readable date/time string.
#>
function ConvertFrom-Rfc3339ToHumanReadable {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Rfc3339String,
        [string]$Format = 'F'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Rfc3339ToHumanReadable @PSBoundParameters
}
Set-Alias -Name rfc3339-to-human -Value ConvertFrom-Rfc3339ToHumanReadable -ErrorAction SilentlyContinue

