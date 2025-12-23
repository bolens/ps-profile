# ===============================================
# Temperature unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Temperature unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for temperature unit conversions.
    Supports conversions between Celsius, Fahrenheit, and Kelvin.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Temperature conversions require special handling as they have different zero points.
    Base unit is Kelvin for absolute temperature, but conversions are direct between all three scales.
#>
function Initialize-FileConversion-CoreUnitsTemperature {
    # Helper function to convert temperature
    Set-Item -Path Function:Global:_Convert-Temperature -Value {
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
            
            # Normalize unit names
            $validUnits = @('c', 'celsius', 'f', 'fahrenheit', 'k', 'kelvin', 'rankine', 'r')
            $unitMap = @{
                'c' = 'celsius'; 'celsius' = 'celsius'
                'f' = 'fahrenheit'; 'fahrenheit' = 'fahrenheit'
                'k' = 'kelvin'; 'kelvin' = 'kelvin'
                'r' = 'rankine'; 'rankine' = 'rankine'
            }
            
            if (-not $unitMap.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: Celsius (C), Fahrenheit (F), Kelvin (K), Rankine (R)"
            }
            if (-not $unitMap.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: Celsius (C), Fahrenheit (F), Kelvin (K), Rankine (R)"
            }
            
            $fromNormalized = $unitMap[$fromUnitLower]
            $toNormalized = $unitMap[$toUnitLower]
            
            # If same unit, return as-is
            if ($fromNormalized -eq $toNormalized) {
                return [PSCustomObject]@{
                    Value         = $Value
                    Unit          = $ToUnit
                    OriginalValue = $Value
                    OriginalUnit  = $FromUnit
                    Celsius       = $null
                    Fahrenheit    = $null
                    Kelvin        = $null
                }
            }
            
            # Convert to Kelvin first (absolute temperature)
            $kelvin = switch ($fromNormalized) {
                'celsius' { $Value + 273.15 }
                'fahrenheit' { ($Value - 32) * 5 / 9 + 273.15 }
                'kelvin' { $Value }
                'rankine' { $Value * 5 / 9 }
            }
            
            # Convert from Kelvin to target unit
            $result = switch ($toNormalized) {
                'celsius' { $kelvin - 273.15 }
                'fahrenheit' { ($kelvin - 273.15) * 9 / 5 + 32 }
                'kelvin' { $kelvin }
                'rankine' { $kelvin * 9 / 5 }
            }
            
            # Calculate all three scales for reference
            $celsius = $kelvin - 273.15
            $fahrenheit = ($kelvin - 273.15) * 9 / 5 + 32
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Celsius       = $celsius
                Fahrenheit    = $fahrenheit
                Kelvin        = $kelvin
            }
        }
        catch {
            throw "Failed to convert temperature: $_"
        }
    } -Force
    
    # Celsius to other units
    Set-Item -Path Function:Global:_ConvertFrom-CelsiusToTemperature -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Celsius,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Temperature -Value $Celsius -FromUnit 'C' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to Celsius
    Set-Item -Path Function:Global:_ConvertTo-CelsiusFromTemperature -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Temperature -Value $Value -FromUnit $FromUnit -ToUnit 'C'
            return $result.Celsius
        }
    } -Force
    
    # Public functions and aliases
    # Convert Temperature
    Set-Item -Path Function:Global:Convert-Temperature -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Temperature @PSBoundParameters
    } -Force
    Set-Alias -Name convert-temperature -Value Convert-Temperature -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name temp -Value Convert-Temperature -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Celsius
    Set-Item -Path Function:Global:ConvertFrom-CelsiusToTemperature -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Celsius,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-CelsiusToTemperature @PSBoundParameters
    } -Force
    Set-Alias -Name celsius-to-temp -Value ConvertFrom-CelsiusToTemperature -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Celsius
    Set-Item -Path Function:Global:ConvertTo-CelsiusFromTemperature -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-CelsiusFromTemperature @PSBoundParameters
    } -Force
    Set-Alias -Name temp-to-celsius -Value ConvertTo-CelsiusFromTemperature -Scope Global -ErrorAction SilentlyContinue
}

