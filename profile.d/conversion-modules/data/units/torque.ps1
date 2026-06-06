# ===============================================
# Torque unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Torque unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for torque unit conversions.
    Supports conversions between newton-meters, pound-feet, pound-inches, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is newton-meters. All conversions go through N·m as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsTorque {
    $script:TorqueUnits = @{
        'nm' = 1; 'n m' = 1; 'newton meter' = 1; 'newton meters' = 1; 'newton-metre' = 1; 'newton-metres' = 1
        'knm' = 1000; 'kilonewton meter' = 1000; 'kilonewton meters' = 1000
        'lb-ft' = 1.3558179483; 'lbf-ft' = 1.3558179483; 'pound foot' = 1.3558179483; 'pound feet' = 1.3558179483; 'ft-lb' = 1.3558179483
        'lb-in' = 0.112984829; 'lbf-in' = 0.112984829; 'pound inch' = 0.112984829; 'pound inches' = 0.112984829; 'in-lb' = 0.112984829
        'kgf-m' = 9.80665; 'kgf m' = 9.80665; 'kilogram-force meter' = 9.80665; 'kilogram-force meters' = 9.80665
        'kgf-cm' = 0.0980665; 'kilogram-force centimeter' = 0.0980665; 'kilogram-force centimeters' = 0.0980665
        'ozf-in' = 0.0070615518; 'ounce-force inch' = 0.0070615518; 'ounce-force inches' = 0.0070615518
    }

    Set-Item -Path Function:Global:_Convert-Torque -Value {
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

            if (-not $script:TorqueUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:TorqueUnits.Keys -join ', ')"
            }
            if (-not $script:TorqueUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:TorqueUnits.Keys -join ', ')"
            }

            $newtonMeters = $Value * $script:TorqueUnits[$fromUnitLower]
            $result = $newtonMeters / $script:TorqueUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                NewtonMeters  = $newtonMeters
            }
        }
        catch {
            throw "Failed to convert torque: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-NewtonMetersToTorque -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$NewtonMeters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Torque -Value $NewtonMeters -FromUnit 'nm' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-NewtonMetersFromTorque -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Torque -Value $Value -FromUnit $FromUnit -ToUnit 'nm'
            return $result.NewtonMeters
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Torque -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Torque @PSBoundParameters
    } -Force
    Set-Alias -Name torque -Value Convert-Torque -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-NewtonMetersToTorque -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$NewtonMeters,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-NewtonMetersToTorque @PSBoundParameters
    } -Force
    Set-Alias -Name nm-to-torque -Value ConvertFrom-NewtonMetersToTorque -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-NewtonMetersFromTorque -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-NewtonMetersFromTorque @PSBoundParameters
    } -Force
    Set-Alias -Name torque-to-nm -Value ConvertTo-NewtonMetersFromTorque -Scope Global -ErrorAction SilentlyContinue
}
