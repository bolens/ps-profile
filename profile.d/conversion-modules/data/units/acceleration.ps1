# ===============================================
# Acceleration unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Acceleration unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for acceleration unit conversions.
    Supports conversions between m/s², ft/s², standard gravity, and gal.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is meters per second squared. All conversions go through m/s² as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsAcceleration {
    $script:AccelerationUnits = @{
        'm/s2' = 1; 'm/s^2' = 1; 'meter per second squared' = 1; 'meters per second squared' = 1
        'km/s2' = 1000; 'kilometer per second squared' = 1000
        'ft/s2' = 0.3048; 'foot per second squared' = 0.3048; 'feet per second squared' = 0.3048; 'fps2' = 0.3048
        'in/s2' = 0.0254; 'inch per second squared' = 0.0254; 'inches per second squared' = 0.0254
        'g' = 9.80665; 'standard gravity' = 9.80665; 'gravities' = 9.80665
        'gal' = 0.01; 'galileo' = 0.01; 'galileos' = 0.01; 'cm/s2' = 0.01; 'centimeter per second squared' = 0.01
        'mm/s2' = 0.001; 'millimeter per second squared' = 0.001
    }

    Set-Item -Path Function:Global:_Convert-Acceleration -Value {
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

            if (-not $script:AccelerationUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:AccelerationUnits.Keys -join ', ')"
            }
            if (-not $script:AccelerationUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:AccelerationUnits.Keys -join ', ')"
            }

            $metersPerSecondSquared = $Value * $script:AccelerationUnits[$fromUnitLower]
            $result = $metersPerSecondSquared / $script:AccelerationUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value                    = $result
                Unit                     = $ToUnit
                OriginalValue            = $Value
                OriginalUnit             = $FromUnit
                MetersPerSecondSquared   = $metersPerSecondSquared
            }
        }
        catch {
            throw "Failed to convert acceleration: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-MetersPerSecondSquaredToAcceleration -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$MetersPerSecondSquared,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Acceleration -Value $MetersPerSecondSquared -FromUnit 'm/s2' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-MetersPerSecondSquaredFromAcceleration -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Acceleration -Value $Value -FromUnit $FromUnit -ToUnit 'm/s2'
            return $result.MetersPerSecondSquared
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Acceleration -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Acceleration @PSBoundParameters
    } -Force
    Set-Alias -Name acceleration -Value Convert-Acceleration -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-MetersPerSecondSquaredToAcceleration -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$MetersPerSecondSquared,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-MetersPerSecondSquaredToAcceleration @PSBoundParameters
    } -Force
    Set-Alias -Name m-s2-to-acceleration -Value ConvertFrom-MetersPerSecondSquaredToAcceleration -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-MetersPerSecondSquaredFromAcceleration -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-MetersPerSecondSquaredFromAcceleration @PSBoundParameters
    } -Force
    Set-Alias -Name acceleration-to-m-s2 -Value ConvertTo-MetersPerSecondSquaredFromAcceleration -Scope Global -ErrorAction SilentlyContinue
}
