# ===============================================
# Density unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Density unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for density unit conversions.
    Supports conversions between kg/m³, g/cm³, lb/ft³, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is kilograms per cubic meter. All conversions go through kg/m³ as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsDensity {
    $script:DensityUnits = @{
        'kg/m3' = 1; 'kg/m^3' = 1; 'kilogram per cubic meter' = 1; 'kilograms per cubic meter' = 1
        'g/cm3' = 1000; 'g/cm^3' = 1000; 'gram per cubic centimeter' = 1000; 'grams per cubic centimeter' = 1000
        'g/l' = 1; 'g/liter' = 1; 'grams per liter' = 1; 'g/litre' = 1
        'g/ml' = 1000; 'grams per milliliter' = 1000
        'mg/ml' = 1; 'milligrams per milliliter' = 1
        'lb/ft3' = 16.018463; 'lb/ft^3' = 16.018463; 'pound per cubic foot' = 16.018463; 'pounds per cubic foot' = 16.018463
        'lb/in3' = 27679.90471; 'lb/in^3' = 27679.90471; 'pound per cubic inch' = 27679.90471; 'pounds per cubic inch' = 27679.90471
        'oz/in3' = 1729.99404; 'ounce per cubic inch' = 1729.99404
        'slug/ft3' = 515.378818; 'slug per cubic foot' = 515.378818
    }

    Set-Item -Path Function:Global:_Convert-Density -Value {
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

            if (-not $script:DensityUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:DensityUnits.Keys -join ', ')"
            }
            if (-not $script:DensityUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:DensityUnits.Keys -join ', ')"
            }

            $kgPerCubicMeter = $Value * $script:DensityUnits[$fromUnitLower]
            $result = $kgPerCubicMeter / $script:DensityUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value             = $result
                Unit              = $ToUnit
                OriginalValue     = $Value
                OriginalUnit      = $FromUnit
                KilogramsPerCubicMeter = $kgPerCubicMeter
            }
        }
        catch {
            throw "Failed to convert density: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-KilogramsPerCubicMeterToDensity -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$KilogramsPerCubicMeter,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Density -Value $KilogramsPerCubicMeter -FromUnit 'kg/m3' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-KilogramsPerCubicMeterFromDensity -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Density -Value $Value -FromUnit $FromUnit -ToUnit 'kg/m3'
            return $result.KilogramsPerCubicMeter
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Density -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Density @PSBoundParameters
    } -Force
    Set-Alias -Name density -Value Convert-Density -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-KilogramsPerCubicMeterToDensity -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$KilogramsPerCubicMeter,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-KilogramsPerCubicMeterToDensity @PSBoundParameters
    } -Force
    Set-Alias -Name kg-m3-to-density -Value ConvertFrom-KilogramsPerCubicMeterToDensity -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-KilogramsPerCubicMeterFromDensity -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-KilogramsPerCubicMeterFromDensity @PSBoundParameters
    } -Force
    Set-Alias -Name density-to-kg-m3 -Value ConvertTo-KilogramsPerCubicMeterFromDensity -Scope Global -ErrorAction SilentlyContinue
}
