# ===============================================
# Volume unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Volume unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for volume unit conversions.
    Supports conversions between liters, gallons, fluid ounces, cubic meters, cubic feet, cubic inches, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is liters. All conversions go through liters as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsVolume {
    # Volume unit definitions (conversion factors to liters)
    $script:VolumeUnits = @{
        # Metric units
        'l' = 1; 'liter' = 1; 'liters' = 1
        'ml' = 0.001; 'milliliter' = 0.001; 'milliliters' = 0.001
        'cl' = 0.01; 'centiliter' = 0.01; 'centiliters' = 0.01
        'dl' = 0.1; 'deciliter' = 0.1; 'deciliters' = 0.1
        'dal' = 10; 'decaliter' = 10; 'decaliters' = 10
        'hl' = 100; 'hectoliter' = 100; 'hectoliters' = 100
        'kl' = 1000; 'kiloliter' = 1000; 'kiloliters' = 1000
        'm3' = 1000; 'cubic meter' = 1000; 'cubic meters' = 1000
        'cm3' = 0.001; 'cubic centimeter' = 0.001; 'cubic centimeters' = 0.001; 'cc' = 0.001; 'ccs' = 0.001
        'mm3' = 0.000001; 'cubic millimeter' = 0.000001; 'cubic millimeters' = 0.000001
        # Imperial/US units
        'fl oz' = 0.0295735; 'fluid ounce' = 0.0295735; 'fluid ounces' = 0.0295735; 'floz' = 0.0295735
        'cup' = 0.236588; 'cups' = 0.236588
        'pt' = 0.473176; 'pint' = 0.473176; 'pints' = 0.473176
        'qt' = 0.946353; 'quart' = 0.946353; 'quarts' = 0.946353
        'gal' = 3.78541; 'gallon' = 3.78541; 'gallons' = 3.78541
        'fl oz uk' = 0.0284131; 'fluid ounce uk' = 0.0284131; 'imperial fluid ounce' = 0.0284131; 'imperial fluid ounces' = 0.0284131
        'cup uk' = 0.284131; 'imperial cup' = 0.284131; 'imperial cups' = 0.284131
        'pt uk' = 0.568261; 'imperial pint' = 0.568261; 'imperial pints' = 0.568261
        'qt uk' = 1.13652; 'imperial quart' = 1.13652; 'imperial quarts' = 1.13652
        'gal uk' = 4.54609; 'imperial gallon' = 4.54609; 'imperial gallons' = 4.54609
        'tbsp' = 0.0147868; 'tablespoon' = 0.0147868; 'tablespoons' = 0.0147868
        'tsp' = 0.00492892; 'teaspoon' = 0.00492892; 'teaspoons' = 0.00492892
        'fl dr' = 0.00369669; 'fluid dram' = 0.00369669; 'fluid drams' = 0.00369669
        'gill' = 0.118294; 'gills' = 0.118294
        'barrel' = 119.24; 'barrels' = 119.24; 'bbl' = 119.24
        'barrel oil' = 158.987; 'oil barrel' = 158.987; 'oil barrels' = 158.987
        # Cubic units
        'ft3' = 28.3168; 'cubic foot' = 28.3168; 'cubic feet' = 28.3168
        'in3' = 0.0163871; 'cubic inch' = 0.0163871; 'cubic inches' = 0.0163871
        'yd3' = 764.555; 'cubic yard' = 764.555; 'cubic yards' = 764.555
    }
    
    # Helper function to convert volume
    Set-Item -Path Function:Global:_Convert-Volume -Value {
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
            if (-not $script:VolumeUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:VolumeUnits.Keys -join ', ')"
            }
            if (-not $script:VolumeUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:VolumeUnits.Keys -join ', ')"
            }
            
            # Convert to liters first, then to target unit
            $liters = $Value * $script:VolumeUnits[$fromUnitLower]
            $result = $liters / $script:VolumeUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Liters        = $liters
            }
        }
        catch {
            throw "Failed to convert volume: $_"
        }
    } -Force
    
    # Liters to other units
    Set-Item -Path Function:Global:_ConvertFrom-LitersToVolume -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Liters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Volume -Value $Liters -FromUnit 'l' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to liters
    Set-Item -Path Function:Global:_ConvertTo-LitersFromVolume -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Volume -Value $Value -FromUnit $FromUnit -ToUnit 'l'
            return $result.Liters
        }
    } -Force
    
    # Public functions and aliases
    # Convert Volume
    Set-Item -Path Function:Global:Convert-Volume -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Volume @PSBoundParameters
    } -Force
    Set-Alias -Name convert-volume -Value Convert-Volume -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name volume -Value Convert-Volume -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Liters
    Set-Item -Path Function:Global:ConvertFrom-LitersToVolume -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Liters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-LitersToVolume @PSBoundParameters
    } -Force
    Set-Alias -Name liters-to-volume -Value ConvertFrom-LitersToVolume -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Liters
    Set-Item -Path Function:Global:ConvertTo-LitersFromVolume -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-LitersFromVolume @PSBoundParameters
    } -Force
    Set-Alias -Name volume-to-liters -Value ConvertTo-LitersFromVolume -Scope Global -ErrorAction SilentlyContinue
}

