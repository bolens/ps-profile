# ===============================================
# Power unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Power unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for power unit conversions.
    Supports conversions between watts, kilowatts, horsepower, BTU/h, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is watts. All conversions go through watts as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsPower {
    $script:PowerUnits = @{
        # SI units
        'w' = 1; 'watt' = 1; 'watts' = 1
        'kw' = 1000; 'kilowatt' = 1000; 'kilowatts' = 1000
        'megw' = 1000000; 'megawatt' = 1000000; 'megawatts' = 1000000
        'gw' = 1000000000; 'gigawatt' = 1000000000; 'gigawatts' = 1000000000
        'tw' = 1000000000000; 'terawatt' = 1000000000000; 'terawatts' = 1000000000000
        'milliw' = 0.001; 'milliwatt' = 0.001; 'milliwatts' = 0.001
        # Mechanical / imperial
        'hp' = 745.699872; 'horsepower' = 745.699872; 'hp mechanical' = 745.699872; 'hp mech' = 745.699872
        'hp metric' = 735.49875; 'metric horsepower' = 735.49875; 'ps' = 735.49875
        'ft-lbf/s' = 1.3558179483; 'ft lbf/s' = 1.3558179483; 'foot-pound per second' = 1.3558179483
        # Thermal
        'btu/h' = 0.29307107; 'btu per hour' = 0.29307107; 'btu/hr' = 0.29307107
        'kbtu/h' = 293.07107; 'kbtu per hour' = 293.07107
    }

    Set-Item -Path Function:Global:_Convert-Power -Value {
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

            if (-not $script:PowerUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:PowerUnits.Keys -join ', ')"
            }
            if (-not $script:PowerUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:PowerUnits.Keys -join ', ')"
            }

            $watts = $Value * $script:PowerUnits[$fromUnitLower]
            $result = $watts / $script:PowerUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Watts         = $watts
            }
        }
        catch {
            throw "Failed to convert power: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WattsToPower -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Watts,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Power -Value $Watts -FromUnit 'w' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-WattsFromPower -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Power -Value $Value -FromUnit $FromUnit -ToUnit 'w'
            return $result.Watts
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Power -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Power @PSBoundParameters
    } -Force
    Set-Alias -Name power -Value Convert-Power -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-WattsToPower -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Watts,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-WattsToPower @PSBoundParameters
    } -Force
    Set-Alias -Name watts-to-power -Value ConvertFrom-WattsToPower -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-WattsFromPower -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-WattsFromPower @PSBoundParameters
    } -Force
    Set-Alias -Name power-to-watts -Value ConvertTo-WattsFromPower -Scope Global -ErrorAction SilentlyContinue
}
