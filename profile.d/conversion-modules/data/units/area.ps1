# ===============================================
# Area unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Area unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for area unit conversions.
    Supports conversions between square meters, square feet, square inches, acres, hectares, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is square meters. All conversions go through m² as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsArea {
    # Area unit definitions (conversion factors to square meters)
    $script:AreaUnits = @{
        # Metric units
        'm2' = 1; 'square meter' = 1; 'square meters' = 1; 'sq m' = 1; 'sqm' = 1
        'km2' = 1000000; 'square kilometer' = 1000000; 'square kilometers' = 1000000; 'sq km' = 1000000; 'sqkm' = 1000000
        'cm2' = 0.0001; 'square centimeter' = 0.0001; 'square centimeters' = 0.0001; 'sq cm' = 0.0001; 'sqcm' = 0.0001
        'mm2' = 0.000001; 'square millimeter' = 0.000001; 'square millimeters' = 0.000001; 'sq mm' = 0.000001; 'sqmm' = 0.000001
        'ha' = 10000; 'hectare' = 10000; 'hectares' = 10000
        'are' = 100; 'ares' = 100
        # Imperial/US units
        'ft2' = 0.092903; 'square foot' = 0.092903; 'square feet' = 0.092903; 'sq ft' = 0.092903; 'sqft' = 0.092903
        'in2' = 0.00064516; 'square inch' = 0.00064516; 'square inches' = 0.00064516; 'sq in' = 0.00064516; 'sqin' = 0.00064516
        'yd2' = 0.836127; 'square yard' = 0.836127; 'square yards' = 0.836127; 'sq yd' = 0.836127; 'sqyd' = 0.836127
        'mi2' = 2589988.11; 'square mile' = 2589988.11; 'square miles' = 2589988.11; 'sq mi' = 2589988.11; 'sqmi' = 2589988.11
        'acre' = 4046.86; 'acres' = 4046.86
        'rood' = 1011.71; 'roods' = 1011.71
        'perch' = 25.2929; 'perches' = 25.2929; 'rod2' = 25.2929; 'square rod' = 25.2929; 'square rods' = 25.2929
        # Other units
        'township' = 93239571.9721; 'townships' = 93239571.9721
        'section' = 2589988.11; 'sections' = 2589988.11
    }
    
    # Helper function to convert area
    Set-Item -Path Function:Global:_Convert-Area -Value {
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
            if (-not $script:AreaUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:AreaUnits.Keys -join ', ')"
            }
            if (-not $script:AreaUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:AreaUnits.Keys -join ', ')"
            }
            
            # Convert to square meters first, then to target unit
            $squareMeters = $Value * $script:AreaUnits[$fromUnitLower]
            $result = $squareMeters / $script:AreaUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                SquareMeters  = $squareMeters
            }
        }
        catch {
            throw "Failed to convert area: $_"
        }
    } -Force
    
    # Square meters to other units
    Set-Item -Path Function:Global:_ConvertFrom-SquareMetersToArea -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$SquareMeters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Area -Value $SquareMeters -FromUnit 'm2' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to square meters
    Set-Item -Path Function:Global:_ConvertTo-SquareMetersFromArea -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Area -Value $Value -FromUnit $FromUnit -ToUnit 'm2'
            return $result.SquareMeters
        }
    } -Force
    
    # Public functions and aliases
    # Convert Area
    Set-Item -Path Function:Global:Convert-Area -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Area @PSBoundParameters
    } -Force
    Set-Alias -Name convert-area -Value Convert-Area -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name area -Value Convert-Area -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Square meters
    Set-Item -Path Function:Global:ConvertFrom-SquareMetersToArea -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$SquareMeters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-SquareMetersToArea @PSBoundParameters
    } -Force
    Set-Alias -Name m2-to-area -Value ConvertFrom-SquareMetersToArea -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Square meters
    Set-Item -Path Function:Global:ConvertTo-SquareMetersFromArea -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-SquareMetersFromArea @PSBoundParameters
    } -Force
    Set-Alias -Name area-to-m2 -Value ConvertTo-SquareMetersFromArea -Scope Global -ErrorAction SilentlyContinue
}

