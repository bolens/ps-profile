# ===============================================
# Fuel economy unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Fuel economy unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for fuel economy unit conversions.
    Supports conversions between mpg (US/UK), L/100km, and km/L.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is liters per 100 kilometers. Inverse units require special handling.
#>
function Initialize-FileConversion-CoreUnitsFuelEconomy {
    $script:FuelEconomyUnitMap = @{
        'l/100km' = 'l100km'; 'l100km' = 'l100km'; 'liters per 100km' = 'l100km'; 'liters per 100 kilometers' = 'l100km'
        'km/l' = 'kmpl'; 'kmpl' = 'kmpl'; 'kilometers per liter' = 'kmpl'; 'km per liter' = 'kmpl'
        'mpg' = 'mpgus'; 'mpg us' = 'mpgus'; 'miles per gallon' = 'mpgus'; 'miles per gallon us' = 'mpgus'
        'mpg uk' = 'mpguk'; 'mpg imperial' = 'mpguk'; 'miles per imperial gallon' = 'mpguk'
    }

    Set-Item -Path Function:Global:_ConvertTo-LitersPer100KmFromFuelEconomy -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )

        $fromUnitLower = $FromUnit.ToLower()
        if (-not $script:FuelEconomyUnitMap.ContainsKey($fromUnitLower)) {
            throw "Invalid source unit: '$FromUnit'."
        }

        switch ($script:FuelEconomyUnitMap[$fromUnitLower]) {
            'l100km' { return $Value }
            'kmpl' {
                if ($Value -eq 0) { throw 'Cannot convert from zero km/L.' }
                return 100 / $Value
            }
            'mpgus' {
                if ($Value -eq 0) { throw 'Cannot convert from zero mpg.' }
                return 235.214583 / $Value
            }
            'mpguk' {
                if ($Value -eq 0) { throw 'Cannot convert from zero mpg (UK).' }
                return 282.480936 / $Value
            }
        }

        throw "Unsupported fuel economy unit: '$FromUnit'."
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-LitersPer100KmToFuelEconomy -Value {
        param(
            [Parameter(Mandatory)]
            [double]$LitersPer100Km,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )

        $toUnitLower = $ToUnit.ToLower()
        if (-not $script:FuelEconomyUnitMap.ContainsKey($toUnitLower)) {
            throw "Invalid target unit: '$ToUnit'."
        }

        switch ($script:FuelEconomyUnitMap[$toUnitLower]) {
            'l100km' { return $LitersPer100Km }
            'kmpl' {
                if ($LitersPer100Km -eq 0) { throw 'Cannot convert to km/L from zero L/100km.' }
                return 100 / $LitersPer100Km
            }
            'mpgus' {
                if ($LitersPer100Km -eq 0) { throw 'Cannot convert to mpg from zero L/100km.' }
                return 235.214583 / $LitersPer100Km
            }
            'mpguk' {
                if ($LitersPer100Km -eq 0) { throw 'Cannot convert to mpg (UK) from zero L/100km.' }
                return 282.480936 / $LitersPer100Km
            }
        }

        throw "Unsupported fuel economy unit: '$ToUnit'."
    } -Force

    Set-Item -Path Function:Global:_Convert-FuelEconomy -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )

        try {
            $litersPer100Km = _ConvertTo-LitersPer100KmFromFuelEconomy -Value $Value -FromUnit $FromUnit
            $result = _ConvertFrom-LitersPer100KmToFuelEconomy -LitersPer100Km $litersPer100Km -ToUnit $ToUnit

            return [PSCustomObject]@{
                Value             = $result
                Unit              = $ToUnit
                OriginalValue     = $Value
                OriginalUnit      = $FromUnit
                LitersPer100Km    = $litersPer100Km
            }
        }
        catch {
            throw "Failed to convert fuel economy: $_"
        }
    } -Force

    Set-Item -Path Function:Global:Convert-FuelEconomy -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-FuelEconomy @PSBoundParameters
    } -Force
    Set-Alias -Name fueleconomy -Value Convert-FuelEconomy -Scope Global -ErrorAction SilentlyContinue
}
