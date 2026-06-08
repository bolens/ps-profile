# ===============================================
# Unit conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes unit conversion utility functions.
.DESCRIPTION
    Sets up internal functions for converting between different units (file sizes, time intervals).
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Units {
    # Unit Converter
    Set-Item -Path Function:Global:_Convert-Units -Value {
        param(
            [double]$Value,
            [string]$FromUnit,
            [string]$ToUnit
        )
        # File size conversions
        $fileSizeUnits = @{
            'B' = 1; 'bytes' = 1
            'KB' = 1024; 'kilobytes' = 1024
            'MB' = 1024KB; 'megabytes' = 1024KB
            'GB' = 1024MB; 'gigabytes' = 1024MB
            'TB' = 1024GB; 'terabytes' = 1024GB
            'PB' = 1024TB; 'petabytes' = 1024TB
        }
        # Time conversions
        $timeUnits = @{
            'ms' = 0.001; 'milliseconds' = 0.001
            's' = 1; 'seconds' = 1; 'sec' = 1
            'm' = 60; 'minutes' = 60; 'min' = 60
            'h' = 3600; 'hours' = 3600; 'hr' = 3600; 'hrs' = 3600
            'd' = 86400; 'days' = 86400; 'day' = 86400
            'w' = 604800; 'weeks' = 604800; 'week' = 604800
        }
        try {
            $fromUnitLower = $FromUnit.ToLower()
            $toUnitLower = $ToUnit.ToLower()

            $fileSizeUnitNames = @('b', 'bytes', 'byte', 'kb', 'kilobytes', 'kilobyte', 'mb', 'megabytes', 'megabyte', 'gb', 'gigabytes', 'gigabyte', 'tb', 'terabytes', 'terabyte', 'pb', 'petabytes', 'petabyte', 'kib', 'mib', 'gib', 'tib', 'pib', 'bit', 'bits', 'kbit', 'mbit', 'gbit')
            $timeUnitNames = @('ns', 'nanosecond', 'nanoseconds', 'us', 'microsecond', 'microseconds', 'µs', 'ms', 'milliseconds', 'millisecond', 's', 'seconds', 'second', 'sec', 'm', 'minutes', 'minute', 'min', 'h', 'hours', 'hour', 'hr', 'hrs', 'd', 'days', 'day', 'w', 'weeks', 'week', 'fortnight', 'fortnights', 'month', 'months', 'year', 'years', 'yr', 'yrs')

            if ($fileSizeUnitNames -contains $fromUnitLower -and $fileSizeUnitNames -contains $toUnitLower) {
                if (Get-Command Convert-DataSize -ErrorAction SilentlyContinue) {
                    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
                    $converted = Convert-DataSize -Value $Value -FromUnit $FromUnit -ToUnit $ToUnit
                    return [PSCustomObject]@{
                        Value         = $converted.Value
                        Unit          = $converted.Unit
                        OriginalValue = $converted.OriginalValue
                        OriginalUnit  = $converted.OriginalUnit
                    }
                }
                $bytes = $Value * $fileSizeUnits[$fromUnitLower]
                $result = $bytes / $fileSizeUnits[$toUnitLower]
                return [PSCustomObject]@{
                    Value         = $result
                    Unit          = $ToUnit
                    OriginalValue = $Value
                    OriginalUnit  = $FromUnit
                }
            }
            elseif ($timeUnitNames -contains $fromUnitLower -and $timeUnitNames -contains $toUnitLower) {
                if (Get-Command Convert-Duration -ErrorAction SilentlyContinue) {
                    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
                    $converted = Convert-Duration -Value $Value -FromUnit $FromUnit -ToUnit $ToUnit
                    return [PSCustomObject]@{
                        Value         = $converted.Value
                        Unit          = $converted.Unit
                        OriginalValue = $converted.OriginalValue
                        OriginalUnit  = $converted.OriginalUnit
                    }
                }
                $seconds = $Value * $timeUnits[$fromUnitLower]
                $result = $seconds / $timeUnits[$toUnitLower]
                return [PSCustomObject]@{
                    Value         = $result
                    Unit          = $ToUnit
                    OriginalValue = $Value
                    OriginalUnit  = $FromUnit
                }
            }
            else {
                throw "Unsupported unit conversion from '$FromUnit' to '$ToUnit'"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.data.units.convert' -Context @{
                    from_unit = $FromUnit
                    to_unit   = $ToUnit
                    value     = $Value
                }
            }
            else {
                Write-Error "Failed to convert units: $_"
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts values between different units.

.DESCRIPTION
    Converts values between file size units (B, KB, MB, GB, TB, PB, bits) and time units (ns through years).
    Delegates to Convert-DataSize and Convert-Duration when the file conversion modules are loaded.

.PARAMETER Value
    The numeric value to convert.

.PARAMETER FromUnit
    The unit of the input value (e.g., "MB", "hours").

.PARAMETER ToUnit
    The unit to convert to (e.g., "KB", "minutes").

.OUTPUTS
    PSCustomObject
    Object containing Value, Unit, OriginalValue, and OriginalUnit properties.

.EXAMPLE
    Convert-Units -Value 1024 -FromUnit "KB" -ToUnit "MB"
    Converts 1024 KB to MB (1 MB).

.EXAMPLE
    Convert-Units -Value 3600 -FromUnit "seconds" -ToUnit "hours"
    Converts 3600 seconds to hours (1 hour).
#>
function Convert-Units {
    param(
        [double]$Value,
        [string]$FromUnit,
        [string]$ToUnit
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Convert-Units @PSBoundParameters
}
Set-AgentModeAlias -Name 'unit-convert' -Target 'Convert-Units'