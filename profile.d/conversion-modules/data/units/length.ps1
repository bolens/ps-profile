# ===============================================
# Length unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Length unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for length unit conversions.
    Supports conversions between meters, feet, inches, miles, kilometers, centimeters, millimeters, yards, nautical miles, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is meters. All conversions go through meters as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsLength {
    # Length unit definitions (conversion factors to meters)
    $script:LengthUnits = @{
        # Metric units
        'm' = 1; 'meter' = 1; 'meters' = 1
        'km' = 1000; 'kilometer' = 1000; 'kilometers' = 1000
        'cm' = 0.01; 'centimeter' = 0.01; 'centimeters' = 0.01
        'mm' = 0.001; 'millimeter' = 0.001; 'millimeters' = 0.001
        'um' = 0.000001; 'micrometer' = 0.000001; 'micrometers' = 0.000001; 'micron' = 0.000001; 'microns' = 0.000001
        'nm' = 0.000000001; 'nanometer' = 0.000000001; 'nanometers' = 0.000000001
        'dm' = 0.1; 'decimeter' = 0.1; 'decimeters' = 0.1
        'dam' = 10; 'decameter' = 10; 'decameters' = 10
        'hm' = 100; 'hectometer' = 100; 'hectometers' = 100
        # Imperial/US units
        'ft' = 0.3048; 'foot' = 0.3048; 'feet' = 0.3048
        'in' = 0.0254; 'inch' = 0.0254; 'inches' = 0.0254
        'yd' = 0.9144; 'yard' = 0.9144; 'yards' = 0.9144
        'mi' = 1609.344; 'mile' = 1609.344; 'miles' = 1609.344
        'nmi' = 1852; 'nautical mile' = 1852; 'nautical miles' = 1852
        'furlong' = 201.168; 'furlongs' = 201.168
        'rod' = 5.0292; 'rods' = 5.0292
        'chain' = 20.1168; 'chains' = 20.1168
        'league' = 4828.032; 'leagues' = 4828.032
        # Astronomical units
        'au' = 149597870700; 'astronomical unit' = 149597870700; 'astronomical units' = 149597870700
        'ly' = 9460730472580800; 'light year' = 9460730472580800; 'light years' = 9460730472580800
        'pc' = 30856775814913673; 'parsec' = 30856775814913673; 'parsecs' = 30856775814913673
    }
    
    # Helper function to convert length
    Set-Item -Path Function:Global:_Convert-Length -Value {
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
            if (-not $script:LengthUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:LengthUnits.Keys -join ', ')"
            }
            if (-not $script:LengthUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:LengthUnits.Keys -join ', ')"
            }
            
            # Convert to meters first, then to target unit
            $meters = $Value * $script:LengthUnits[$fromUnitLower]
            $result = $meters / $script:LengthUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Meters        = $meters
            }
        }
        catch {
            throw "Failed to convert length: $_"
        }
    } -Force
    
    # Meters to other units
    Set-Item -Path Function:Global:_ConvertFrom-MetersToLength -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Meters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Length -Value $Meters -FromUnit 'm' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to meters
    Set-Item -Path Function:Global:_ConvertTo-MetersFromLength -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Length -Value $Value -FromUnit $FromUnit -ToUnit 'm'
            return $result.Meters
        }
    } -Force
    
    # Public functions and aliases
    # Convert Length
    Set-Item -Path Function:Global:Convert-Length -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Length @PSBoundParameters
    } -Force
    Set-Alias -Name convert-length -Value Convert-Length -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name length -Value Convert-Length -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Meters
    Set-Item -Path Function:Global:ConvertFrom-MetersToLength -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Meters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-MetersToLength @PSBoundParameters
    } -Force
    Set-Alias -Name meters-to-length -Value ConvertFrom-MetersToLength -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Meters
    Set-Item -Path Function:Global:ConvertTo-MetersFromLength -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-MetersFromLength @PSBoundParameters
    } -Force
    Set-Alias -Name length-to-meters -Value ConvertTo-MetersFromLength -Scope Global -ErrorAction SilentlyContinue
}

