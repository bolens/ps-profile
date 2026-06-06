# ===============================================
# Time duration unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Time duration unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for time duration unit conversions.
    Supports conversions between nanoseconds, microseconds, milliseconds, seconds, minutes, hours, days, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is seconds. All conversions go through seconds as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsTime {
    $script:TimeUnits = @{
        'ns' = 0.000000001; 'nanosecond' = 0.000000001; 'nanoseconds' = 0.000000001
        'us' = 0.000001; 'microsecond' = 0.000001; 'microseconds' = 0.000001; 'µs' = 0.000001
        'ms' = 0.001; 'millisecond' = 0.001; 'milliseconds' = 0.001
        's' = 1; 'sec' = 1; 'second' = 1; 'seconds' = 1
        'min' = 60; 'minute' = 60; 'minutes' = 60; 'm' = 60
        'h' = 3600; 'hr' = 3600; 'hour' = 3600; 'hours' = 3600; 'hrs' = 3600
        'd' = 86400; 'day' = 86400; 'days' = 86400
        'w' = 604800; 'week' = 604800; 'weeks' = 604800
        'fortnight' = 1209600; 'fortnights' = 1209600
        'month' = 2629800; 'months' = 2629800
        'year' = 31557600; 'years' = 31557600; 'yr' = 31557600; 'yrs' = 31557600
    }

    Set-Item -Path Function:Global:_Convert-Duration -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )

        try {
            $fromUnitLower = $FromUnit.ToLower()
            $toUnitLower = $ToUnit.ToLower()

            if (-not $script:TimeUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:TimeUnits.Keys -join ', ')"
            }
            if (-not $script:TimeUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:TimeUnits.Keys -join ', ')"
            }

            $seconds = $Value * $script:TimeUnits[$fromUnitLower]
            $result = $seconds / $script:TimeUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Seconds       = $seconds
            }
        }
        catch {
            throw "Failed to convert duration: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-SecondsToTimeUnit -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Seconds,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Duration -Value $Seconds -FromUnit 's' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-SecondsFromTimeUnit -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Duration -Value $Value -FromUnit $FromUnit -ToUnit 's'
            return $result.Seconds
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Duration -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Duration @PSBoundParameters
    } -Force
    Set-Alias -Name duration-units -Value Convert-Duration -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-SecondsToTimeUnit -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Seconds,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-SecondsToTimeUnit @PSBoundParameters
    } -Force
    Set-Alias -Name seconds-to-time -Value ConvertFrom-SecondsToTimeUnit -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-SecondsFromTimeUnit -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-SecondsFromTimeUnit @PSBoundParameters
    } -Force
    Set-Alias -Name time-to-seconds -Value ConvertTo-SecondsFromTimeUnit -Scope Global -ErrorAction SilentlyContinue
}
