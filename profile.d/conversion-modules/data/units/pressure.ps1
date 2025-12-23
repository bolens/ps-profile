# ===============================================
# Pressure unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Pressure unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for pressure unit conversions.
    Supports conversions between pascals, psi, bar, atmospheres, torr, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is pascals. All conversions go through pascals as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsPressure {
    # Pressure unit definitions (conversion factors to pascals)
    $script:PressureUnits = @{
        # SI units
        'pa' = 1; 'pascal' = 1; 'pascals' = 1
        'kpa' = 1000; 'kilopascal' = 1000; 'kilopascals' = 1000
        'mpa' = 1000000; 'megapascal' = 1000000; 'megapascals' = 1000000
        'gpa' = 1000000000; 'gigapascal' = 1000000000; 'gigapascals' = 1000000000
        'hpa' = 100; 'hectopascal' = 100; 'hectopascals' = 100
        # Bar units
        'bar' = 100000; 'bars' = 100000
        'mbar' = 100; 'millibar' = 100; 'millibars' = 100
        'kbar' = 100000000; 'kilobar' = 100000000; 'kilobars' = 100000000
        # Imperial/US units
        'psi' = 6894.76; 'pound per square inch' = 6894.76; 'pounds per square inch' = 6894.76; 'pound-force per square inch' = 6894.76
        'psf' = 47.8803; 'pound per square foot' = 47.8803; 'pounds per square foot' = 47.8803; 'pound-force per square foot' = 47.8803
        # Atmospheric units
        'atm' = 101325; 'atmosphere' = 101325; 'atmospheres' = 101325; 'standard atmosphere' = 101325; 'standard atmospheres' = 101325
        'torr' = 133.322; 'torrs' = 133.322; 'mmhg' = 133.322; 'millimeter of mercury' = 133.322; 'millimeters of mercury' = 133.322
        'inhg' = 3386.39; 'inch of mercury' = 3386.39; 'inches of mercury' = 3386.39
        'inh2o' = 249.089; 'inch of water' = 249.089; 'inches of water' = 249.089; 'in h2o' = 249.089
        'mmh2o' = 9.80665; 'millimeter of water' = 9.80665; 'millimeters of water' = 9.80665
        'cmh2o' = 98.0665; 'centimeter of water' = 98.0665; 'centimeters of water' = 98.0665
        # Other units
        'ba' = 0.1; 'barye' = 0.1; 'baryes' = 0.1
        'pieze' = 1000; 'piezes' = 1000
    }
    
    # Helper function to convert pressure
    Set-Item -Path Function:Global:_Convert-Pressure -Value {
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
            if (-not $script:PressureUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:PressureUnits.Keys -join ', ')"
            }
            if (-not $script:PressureUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:PressureUnits.Keys -join ', ')"
            }
            
            # Convert to pascals first, then to target unit
            $pascals = $Value * $script:PressureUnits[$fromUnitLower]
            $result = $pascals / $script:PressureUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Pascals       = $pascals
            }
        }
        catch {
            throw "Failed to convert pressure: $_"
        }
    } -Force
    
    # Pascals to other units
    Set-Item -Path Function:Global:_ConvertFrom-PascalsToPressure -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Pascals,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Pressure -Value $Pascals -FromUnit 'pa' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to pascals
    Set-Item -Path Function:Global:_ConvertTo-PascalsFromPressure -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Pressure -Value $Value -FromUnit $FromUnit -ToUnit 'pa'
            return $result.Pascals
        }
    } -Force
    
    # Public functions and aliases
    # Convert Pressure
    Set-Item -Path Function:Global:Convert-Pressure -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Pressure @PSBoundParameters
    } -Force
    Set-Alias -Name convert-pressure -Value Convert-Pressure -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name pressure -Value Convert-Pressure -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Pascals
    Set-Item -Path Function:Global:ConvertFrom-PascalsToPressure -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Pascals,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-PascalsToPressure @PSBoundParameters
    } -Force
    Set-Alias -Name pa-to-pressure -Value ConvertFrom-PascalsToPressure -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Pascals
    Set-Item -Path Function:Global:ConvertTo-PascalsFromPressure -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-PascalsFromPressure @PSBoundParameters
    } -Force
    Set-Alias -Name pressure-to-pa -Value ConvertTo-PascalsFromPressure -Scope Global -ErrorAction SilentlyContinue
}

