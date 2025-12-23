# ===============================================
# Energy unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Energy unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for energy unit conversions.
    Supports conversions between joules, calories, kilowatt-hours, BTUs, electronvolts, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is joules. All conversions go through joules as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsEnergy {
    # Energy unit definitions (conversion factors to joules)
    $script:EnergyUnits = @{
        # SI units
        'j' = 1; 'joule' = 1; 'joules' = 1
        'kj' = 1000; 'kilojoule' = 1000; 'kilojoules' = 1000
        'mj' = 1000000; 'megajoule' = 1000000; 'megajoules' = 1000000
        'gj' = 1000000000; 'gigajoule' = 1000000000; 'gigajoules' = 1000000000
        'tj' = 1000000000000; 'terajoule' = 1000000000000; 'terajoules' = 1000000000000
        # Calories
        'cal' = 4.184; 'calorie' = 4.184; 'calories' = 4.184
        'kcal' = 4184; 'kilocalorie' = 4184; 'kilocalories' = 4184; 'calorie (food)' = 4184; 'calories (food)' = 4184
        # Electrical units
        'kwh' = 3600000; 'kilowatt hour' = 3600000; 'kilowatt hours' = 3600000; 'kilowatt-hour' = 3600000; 'kilowatt-hours' = 3600000
        'wh' = 3600; 'watt hour' = 3600; 'watt hours' = 3600; 'watt-hour' = 3600; 'watt-hours' = 3600
        'mwh' = 3600000000; 'megawatt hour' = 3600000000; 'megawatt hours' = 3600000000; 'megawatt-hour' = 3600000000; 'megawatt-hours' = 3600000000
        # Thermal units
        'btu' = 1055.06; 'british thermal unit' = 1055.06; 'british thermal units' = 1055.06
        'therm' = 105506000; 'therms' = 105506000
        'quad' = 1.05506E+18; 'quads' = 1.05506E+18
        # Atomic/particle physics
        'ev' = 1.602176634E-19; 'electronvolt' = 1.602176634E-19; 'electronvolts' = 1.602176634E-19
        'kev' = 1.602176634E-16; 'kiloelectronvolt' = 1.602176634E-16; 'kiloelectronvolts' = 1.602176634E-16
        'mev' = 1.602176634E-13; 'megaelectronvolt' = 1.602176634E-13; 'megaelectronvolts' = 1.602176634E-13
        'gev' = 1.602176634E-10; 'gigaelectronvolt' = 1.602176634E-10; 'gigaelectronvolts' = 1.602176634E-10
        'tev' = 1.602176634E-7; 'teraelectronvolt' = 1.602176634E-7; 'teraelectronvolts' = 1.602176634E-7
        # Other units
        'erg' = 0.0000001; 'ergs' = 0.0000001
        'ft-lb' = 1.35582; 'foot pound' = 1.35582; 'foot pounds' = 1.35582; 'ft lbf' = 1.35582; 'foot-pound' = 1.35582; 'foot-pounds' = 1.35582
        'in-lb' = 0.112985; 'inch pound' = 0.112985; 'inch pounds' = 0.112985; 'inch-pound' = 0.112985; 'inch-pounds' = 0.112985
    }
    
    # Helper function to convert energy
    Set-Item -Path Function:Global:_Convert-Energy -Value {
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
            if (-not $script:EnergyUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:EnergyUnits.Keys -join ', ')"
            }
            if (-not $script:EnergyUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:EnergyUnits.Keys -join ', ')"
            }
            
            # Convert to joules first, then to target unit
            $joules = $Value * $script:EnergyUnits[$fromUnitLower]
            $result = $joules / $script:EnergyUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Joules        = $joules
            }
        }
        catch {
            throw "Failed to convert energy: $_"
        }
    } -Force
    
    # Joules to other units
    Set-Item -Path Function:Global:_ConvertFrom-JoulesToEnergy -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Joules,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Energy -Value $Joules -FromUnit 'j' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to joules
    Set-Item -Path Function:Global:_ConvertTo-JoulesFromEnergy -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Energy -Value $Value -FromUnit $FromUnit -ToUnit 'j'
            return $result.Joules
        }
    } -Force
    
    # Public functions and aliases
    # Convert Energy
    Set-Item -Path Function:Global:Convert-Energy -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Energy @PSBoundParameters
    } -Force
    Set-Alias -Name convert-energy -Value Convert-Energy -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name energy -Value Convert-Energy -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Joules
    Set-Item -Path Function:Global:ConvertFrom-JoulesToEnergy -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Joules,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-JoulesToEnergy @PSBoundParameters
    } -Force
    Set-Alias -Name joules-to-energy -Value ConvertFrom-JoulesToEnergy -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Joules
    Set-Item -Path Function:Global:ConvertTo-JoulesFromEnergy -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-JoulesFromEnergy @PSBoundParameters
    } -Force
    Set-Alias -Name energy-to-joules -Value ConvertTo-JoulesFromEnergy -Scope Global -ErrorAction SilentlyContinue
}

