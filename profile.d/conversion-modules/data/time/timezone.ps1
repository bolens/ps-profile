# ===============================================
# Timezone conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Timezone conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for timezone conversions.
    Supports conversions between different timezones and standard date/time formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Uses .NET TimeZoneInfo for timezone conversions.
#>
function Initialize-FileConversion-CoreTimeTimezone {
    # Convert DateTime between timezones
    Set-Item -Path Function:Global:_Convert-TimeZone -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime,
            [Parameter(Mandatory)]
            [string]$SourceTimeZone,
            [Parameter(Mandatory)]
            [string]$TargetTimeZone
        )
        process {
            try {
                # Get timezone info
                $sourceTz = if ($SourceTimeZone -eq 'UTC' -or $SourceTimeZone -eq 'GMT') {
                    [TimeZoneInfo]::Utc
                }
                else {
                    [TimeZoneInfo]::FindSystemTimeZoneById($SourceTimeZone)
                }
                
                $targetTz = if ($TargetTimeZone -eq 'UTC' -or $TargetTimeZone -eq 'GMT') {
                    [TimeZoneInfo]::Utc
                }
                else {
                    [TimeZoneInfo]::FindSystemTimeZoneById($TargetTimeZone)
                }
                
                # Create DateTimeOffset with source timezone
                $sourceOffset = $sourceTz.GetUtcOffset($DateTime)
                $dateTimeOffset = New-Object DateTimeOffset($DateTime, $sourceOffset)
                
                # Convert to target timezone
                $targetOffset = [TimeZoneInfo]::ConvertTime($dateTimeOffset, $targetTz)
                return $targetOffset.DateTime
            }
            catch {
                throw "Failed to convert timezone: $_"
            }
        }
    } -Force

    # Get DateTime in specific timezone
    Set-Item -Path Function:Global:_ConvertTo-TimeZone -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime,
            [Parameter(Mandatory)]
            [string]$TimeZone
        )
        process {
            try {
                $tz = if ($TimeZone -eq 'UTC' -or $TimeZone -eq 'GMT') {
                    [TimeZoneInfo]::Utc
                }
                else {
                    [TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
                }
                
                # Assume input is in local time, convert to target timezone
                $dateTimeOffset = New-Object DateTimeOffset($DateTime, [TimeZoneInfo]::Local.GetUtcOffset($DateTime))
                $targetOffset = [TimeZoneInfo]::ConvertTime($dateTimeOffset, $tz)
                return $targetOffset.DateTime
            }
            catch {
                throw "Failed to convert to timezone: $_"
            }
        }
    } -Force

    # Get DateTime from specific timezone
    Set-Item -Path Function:Global:_ConvertFrom-TimeZone -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime,
            [Parameter(Mandatory)]
            [string]$TimeZone
        )
        process {
            try {
                $tz = if ($TimeZone -eq 'UTC' -or $TimeZone -eq 'GMT') {
                    [TimeZoneInfo]::Utc
                }
                else {
                    [TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
                }
                
                # Treat input as being in specified timezone, convert to local
                $dateTimeOffset = New-Object DateTimeOffset($DateTime, $tz.GetUtcOffset($DateTime))
                $localOffset = [TimeZoneInfo]::ConvertTime($dateTimeOffset, [TimeZoneInfo]::Local)
                return $localOffset.DateTime
            }
            catch {
                throw "Failed to convert from timezone: $_"
            }
        }
    } -Force

    # List available timezones
    Set-Item -Path Function:Global:_Get-TimeZones -Value {
        try {
            return [TimeZoneInfo]::GetSystemTimeZones() | ForEach-Object {
                [PSCustomObject]@{
                    Id            = $_.Id
                    DisplayName   = $_.DisplayName
                    StandardName  = $_.StandardName
                    DaylightName  = $_.DaylightName
                    BaseUtcOffset = $_.BaseUtcOffset
                }
            }
        }
        catch {
            throw "Failed to get timezones: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert DateTime between timezones
<#
.SYNOPSIS
    Converts a DateTime between two timezones.
.DESCRIPTION
    Converts a DateTime object from one timezone to another.
    Uses .NET TimeZoneInfo for timezone conversions.
.PARAMETER DateTime
    The DateTime object to convert.
.PARAMETER SourceTimeZone
    The source timezone ID (e.g., "Eastern Standard Time", "UTC", "GMT").
.PARAMETER TargetTimeZone
    The target timezone ID (e.g., "Pacific Standard Time", "UTC", "GMT").
.EXAMPLE
    Get-Date | Convert-TimeZone -SourceTimeZone "Eastern Standard Time" -TargetTimeZone "Pacific Standard Time"
    
    Converts the current date/time from Eastern to Pacific timezone.
.EXAMPLE
    [DateTime]::Now | Convert-TimeZone -SourceTimeZone "UTC" -TargetTimeZone "Eastern Standard Time"
    
    Converts UTC time to Eastern timezone.
.OUTPUTS
    System.DateTime
    Returns a DateTime object in the target timezone.
#>
function Convert-TimeZone {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime,
        [Parameter(Mandatory)]
        [string]$SourceTimeZone,
        [Parameter(Mandatory)]
        [string]$TargetTimeZone
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Convert-TimeZone @PSBoundParameters
}
Set-Alias -Name convert-timezone -Value Convert-TimeZone -ErrorAction SilentlyContinue

# Convert DateTime to specific timezone
<#
.SYNOPSIS
    Converts a DateTime to a specific timezone.
.DESCRIPTION
    Converts a DateTime object (assumed to be in local time) to a specific timezone.
.PARAMETER DateTime
    The DateTime object to convert (assumed to be in local time).
.PARAMETER TimeZone
    The target timezone ID (e.g., "Eastern Standard Time", "UTC", "GMT").
.EXAMPLE
    Get-Date | ConvertTo-TimeZone -TimeZone "UTC"
    
    Converts the current local date/time to UTC.
.OUTPUTS
    System.DateTime
    Returns a DateTime object in the target timezone.
#>
function ConvertTo-TimeZone {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime,
        [Parameter(Mandatory)]
        [string]$TimeZone
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TimeZone @PSBoundParameters
}
Set-Alias -Name datetime-to-timezone -Value ConvertTo-TimeZone -ErrorAction SilentlyContinue

# Convert DateTime from specific timezone
<#
.SYNOPSIS
    Converts a DateTime from a specific timezone to local time.
.DESCRIPTION
    Converts a DateTime object (assumed to be in the specified timezone) to local time.
.PARAMETER DateTime
    The DateTime object to convert (assumed to be in the specified timezone).
.PARAMETER TimeZone
    The source timezone ID (e.g., "Eastern Standard Time", "UTC", "GMT").
.EXAMPLE
    [DateTime]::Parse("2024-01-15 12:00:00") | ConvertFrom-TimeZone -TimeZone "UTC"
    
    Converts a UTC date/time to local time.
.OUTPUTS
    System.DateTime
    Returns a DateTime object in local time.
#>
function ConvertFrom-TimeZone {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime,
        [Parameter(Mandatory)]
        [string]$TimeZone
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TimeZone @PSBoundParameters
}
Set-Alias -Name timezone-to-datetime -Value ConvertFrom-TimeZone -ErrorAction SilentlyContinue

# Get available timezones
<#
.SYNOPSIS
    Gets a list of available timezones.
.DESCRIPTION
    Returns a list of all available timezones on the system.
.EXAMPLE
    Get-TimeZones
    
    Lists all available timezones.
.OUTPUTS
    PSCustomObject[]
    Returns an array of timezone objects with Id, DisplayName, StandardName, DaylightName, and BaseUtcOffset properties.
#>
function Get-TimeZones {
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Get-TimeZones
}
Set-Alias -Name list-timezones -Value Get-TimeZones -ErrorAction SilentlyContinue

