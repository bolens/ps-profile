# ===============================================
# Unix Timestamp conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Unix Timestamp conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Unix Timestamp (epoch time) conversions.
    Supports conversions between Unix timestamps and DateTime objects, ISO 8601, RFC 3339, and human-readable formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Unix timestamps represent seconds since January 1, 1970 UTC (Unix epoch).
    Supports both integer and floating-point timestamps (with milliseconds).
#>
function Initialize-FileConversion-CoreTimeUnix {
    # Unix Timestamp to DateTime
    Set-Item -Path Function:Global:_ConvertFrom-UnixTimestampToDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$UnixTimestamp
        )
        process {
            try {
                # Unix epoch: January 1, 1970 00:00:00 UTC
                $epoch = [DateTimeOffset]::FromUnixTimeSeconds([long]$UnixTimestamp)
                return $epoch.DateTime
            }
            catch {
                # Try with milliseconds if seconds conversion fails
                try {
                    $epoch = [DateTimeOffset]::FromUnixTimeMilliseconds([long]($UnixTimestamp * 1000))
                    return $epoch.DateTime
                }
                catch {
                    throw "Failed to convert Unix timestamp to DateTime: $_"
                }
            }
        }
    } -Force

    # DateTime to Unix Timestamp
    Set-Item -Path Function:Global:_ConvertTo-UnixTimestampFromDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime
        )
        process {
            try {
                $dateTimeOffset = [DateTimeOffset]::new($DateTime)
                return [long]$dateTimeOffset.ToUnixTimeSeconds()
            }
            catch {
                throw "Failed to convert DateTime to Unix timestamp: $_"
            }
        }
    } -Force

    # Unix Timestamp to ISO 8601
    Set-Item -Path Function:Global:_ConvertFrom-UnixTimestampToIso8601 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$UnixTimestamp
        )
        process {
            try {
                $dateTime = _ConvertFrom-UnixTimestampToDateTime -UnixTimestamp $UnixTimestamp
                return $dateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            }
            catch {
                throw "Failed to convert Unix timestamp to ISO 8601: $_"
            }
        }
    } -Force

    # ISO 8601 to Unix Timestamp
    Set-Item -Path Function:Global:_ConvertTo-UnixTimestampFromIso8601 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Iso8601String
        )
        process {
            try {
                $dateTime = [DateTime]::Parse($Iso8601String, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
                return _ConvertTo-UnixTimestampFromDateTime -DateTime $dateTime
            }
            catch {
                throw "Failed to convert ISO 8601 to Unix timestamp: $_"
            }
        }
    } -Force

    # Unix Timestamp to Human-readable
    Set-Item -Path Function:Global:_ConvertFrom-UnixTimestampToHumanReadable -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$UnixTimestamp,
            [string]$Format = 'F'
        )
        process {
            try {
                $dateTime = _ConvertFrom-UnixTimestampToDateTime -UnixTimestamp $UnixTimestamp
                return $dateTime.ToString($Format)
            }
            catch {
                throw "Failed to convert Unix timestamp to human-readable format: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert Unix Timestamp to DateTime
<#
.SYNOPSIS
    Converts a Unix timestamp to a DateTime object.
.DESCRIPTION
    Converts a Unix timestamp (seconds since January 1, 1970 UTC) to a DateTime object.
.PARAMETER UnixTimestamp
    The Unix timestamp to convert (as integer or floating-point number).
.EXAMPLE
    1609459200 | ConvertFrom-UnixTimestampToDateTime
    
    Converts the Unix timestamp 1609459200 to a DateTime object.
.EXAMPLE
    1609459200.5 | ConvertFrom-UnixTimestampToDateTime
    
    Converts a Unix timestamp with fractional seconds.
.OUTPUTS
    System.DateTime
    Returns a DateTime object representing the timestamp.
#>
function ConvertFrom-UnixTimestampToDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$UnixTimestamp
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UnixTimestampToDateTime @PSBoundParameters
}
Set-Alias -Name unix-to-datetime -Value ConvertFrom-UnixTimestampToDateTime -ErrorAction SilentlyContinue

# Convert DateTime to Unix Timestamp
<#
.SYNOPSIS
    Converts a DateTime object to a Unix timestamp.
.DESCRIPTION
    Converts a DateTime object to a Unix timestamp (seconds since January 1, 1970 UTC).
.PARAMETER DateTime
    The DateTime object to convert.
.EXAMPLE
    Get-Date | ConvertTo-UnixTimestampFromDateTime
    
    Converts the current date/time to a Unix timestamp.
.EXAMPLE
    [DateTime]::Parse('2021-01-01') | ConvertTo-UnixTimestampFromDateTime
    
    Converts a specific date to a Unix timestamp.
.OUTPUTS
    System.Int64
    Returns a Unix timestamp as a long integer.
#>
function ConvertTo-UnixTimestampFromDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-UnixTimestampFromDateTime @PSBoundParameters
}
Set-Alias -Name datetime-to-unix -Value ConvertTo-UnixTimestampFromDateTime -ErrorAction SilentlyContinue

# Convert Unix Timestamp to ISO 8601
<#
.SYNOPSIS
    Converts a Unix timestamp to ISO 8601 format.
.DESCRIPTION
    Converts a Unix timestamp to ISO 8601 date/time format string.
.PARAMETER UnixTimestamp
    The Unix timestamp to convert.
.EXAMPLE
    1609459200 | ConvertFrom-UnixTimestampToIso8601
    
    Converts the Unix timestamp to ISO 8601 format.
.OUTPUTS
    System.String
    Returns an ISO 8601 formatted date/time string.
#>
function ConvertFrom-UnixTimestampToIso8601 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$UnixTimestamp
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UnixTimestampToIso8601 @PSBoundParameters
}
Set-Alias -Name unix-to-iso8601 -Value ConvertFrom-UnixTimestampToIso8601 -ErrorAction SilentlyContinue

# Convert ISO 8601 to Unix Timestamp
<#
.SYNOPSIS
    Converts an ISO 8601 date/time string to a Unix timestamp.
.DESCRIPTION
    Converts an ISO 8601 formatted date/time string to a Unix timestamp.
.PARAMETER Iso8601String
    The ISO 8601 formatted date/time string to convert.
.EXAMPLE
    '2021-01-01T00:00:00Z' | ConvertTo-UnixTimestampFromIso8601
    
    Converts an ISO 8601 string to a Unix timestamp.
.OUTPUTS
    System.Int64
    Returns a Unix timestamp as a long integer.
#>
function ConvertTo-UnixTimestampFromIso8601 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Iso8601String
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-UnixTimestampFromIso8601 @PSBoundParameters
}
Set-Alias -Name iso8601-to-unix -Value ConvertTo-UnixTimestampFromIso8601 -ErrorAction SilentlyContinue

# Convert Unix Timestamp to Human-readable
<#
.SYNOPSIS
    Converts a Unix timestamp to a human-readable date/time string.
.DESCRIPTION
    Converts a Unix timestamp to a human-readable date/time format.
.PARAMETER UnixTimestamp
    The Unix timestamp to convert.
.PARAMETER Format
    The format string to use (default: 'F' for full date/time).
    See DateTime.ToString() format strings for options.
.EXAMPLE
    1609459200 | ConvertFrom-UnixTimestampToHumanReadable
    
    Converts the Unix timestamp to a human-readable format.
.EXAMPLE
    1609459200 | ConvertFrom-UnixTimestampToHumanReadable -Format 'yyyy-MM-dd'
    
    Converts the Unix timestamp using a custom format.
.OUTPUTS
    System.String
    Returns a human-readable date/time string.
#>
function ConvertFrom-UnixTimestampToHumanReadable {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$UnixTimestamp,
        [string]$Format = 'F'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UnixTimestampToHumanReadable @PSBoundParameters
}
Set-Alias -Name unix-to-readable -Value ConvertFrom-UnixTimestampToHumanReadable -ErrorAction SilentlyContinue

