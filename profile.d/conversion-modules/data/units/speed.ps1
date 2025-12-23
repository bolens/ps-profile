# ===============================================
# Speed unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Speed unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for speed unit conversions.
    Supports conversions between meters per second, kilometers per hour, miles per hour, knots, feet per second, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is meters per second. All conversions go through m/s as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsSpeed {
    # Speed unit definitions (conversion factors to meters per second)
    $script:SpeedUnits = @{
        # Metric units
        'm/s' = 1; 'meter per second' = 1; 'meters per second' = 1; 'mps' = 1
        'km/h' = 0.277778; 'kilometer per hour' = 0.277778; 'kilometers per hour' = 0.277778; 'kmph' = 0.277778; 'kph' = 0.277778
        'km/s' = 1000; 'kilometer per second' = 1000; 'kilometers per second' = 1000; 'kmps' = 1000
        'cm/s' = 0.01; 'centimeter per second' = 0.01; 'centimeters per second' = 0.01
        'mm/s' = 0.001; 'millimeter per second' = 0.001; 'millimeters per second' = 0.001
        # Imperial/US units
        'mph' = 0.44704; 'mile per hour' = 0.44704; 'miles per hour' = 0.44704
        'ft/s' = 0.3048; 'foot per second' = 0.3048; 'feet per second' = 0.3048; 'fps' = 0.3048
        'in/s' = 0.0254; 'inch per second' = 0.0254; 'inches per second' = 0.0254; 'ips' = 0.0254
        'yd/s' = 0.9144; 'yard per second' = 0.9144; 'yards per second' = 0.9144; 'yps' = 0.9144
        # Nautical units
        'knot' = 0.514444; 'knots' = 0.514444; 'kt' = 0.514444; 'kn' = 0.514444; 'nautical mile per hour' = 0.514444; 'nautical miles per hour' = 0.514444
        # Other units
        'mach' = 343; 'mach number' = 343; 'mach 1' = 343
        'c' = 299792458; 'speed of light' = 299792458; 'lightspeed' = 299792458
    }
    
    # Helper function to convert speed
    Set-Item -Path Function:Global:_Convert-Speed -Value {
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
            
            # Check if units are valid
            if (-not $script:SpeedUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:SpeedUnits.Keys -join ', ')"
            }
            if (-not $script:SpeedUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:SpeedUnits.Keys -join ', ')"
            }
            
            # Convert to m/s first, then to target unit
            $mps = $Value * $script:SpeedUnits[$fromUnitLower]
            $result = $mps / $script:SpeedUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value           = $result
                Unit            = $ToUnit
                OriginalValue   = $Value
                OriginalUnit    = $FromUnit
                MetersPerSecond = $mps
            }
        }
        catch {
            throw "Failed to convert speed: $_"
        }
    } -Force
    
    # Meters per second to other units
    Set-Item -Path Function:Global:_ConvertFrom-MetersPerSecondToSpeed -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$MetersPerSecond,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Speed -Value $MetersPerSecond -FromUnit 'm/s' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to meters per second
    Set-Item -Path Function:Global:_ConvertTo-MetersPerSecondFromSpeed -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Speed -Value $Value -FromUnit $FromUnit -ToUnit 'm/s'
            return $result.MetersPerSecond
        }
    } -Force
    
    # Public functions and aliases
    # Convert Speed
    Set-Item -Path Function:Global:Convert-Speed -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Speed @PSBoundParameters
    } -Force
    Set-Alias -Name convert-speed -Value Convert-Speed -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name speed -Value Convert-Speed -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Meters per second
    Set-Item -Path Function:Global:ConvertFrom-MetersPerSecondToSpeed -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$MetersPerSecond,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-MetersPerSecondToSpeed @PSBoundParameters
    } -Force
    Set-Alias -Name mps-to-speed -Value ConvertFrom-MetersPerSecondToSpeed -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Meters per second
    Set-Item -Path Function:Global:ConvertTo-MetersPerSecondFromSpeed -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-MetersPerSecondFromSpeed @PSBoundParameters
    } -Force
    Set-Alias -Name speed-to-mps -Value ConvertTo-MetersPerSecondFromSpeed -Scope Global -ErrorAction SilentlyContinue
}

