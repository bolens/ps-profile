# ===============================================
# Angle unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Angle unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for angle unit conversions.
    Supports conversions between degrees, radians, gradians, and turns.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is radians. All conversions go through radians as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsAngle {
    # Angle unit definitions (conversion factors to radians)
    $script:AngleUnits = @{
        # Common units
        'rad' = 1; 'radian' = 1; 'radians' = 1
        'deg' = 0.0174533; 'degree' = 0.0174533; 'degrees' = 0.0174533; '°' = 0.0174533
        'grad' = 0.015708; 'gradian' = 0.015708; 'gradians' = 0.015708; 'gon' = 0.015708; 'gons' = 0.015708
        'turn' = 6.28319; 'turns' = 6.28319; 'revolution' = 6.28319; 'revolutions' = 6.28319; 'rev' = 6.28319; 'rot' = 6.28319; 'rotation' = 6.28319; 'rotations' = 6.28319
        'circle' = 6.28319; 'circles' = 6.28319
        # Arc units
        'arcmin' = 0.000290888; 'arc minute' = 0.000290888; 'arc minutes' = 0.000290888; 'minute of arc' = 0.000290888; 'minutes of arc' = 0.000290888; '''' = 0.000290888
        'arcsec' = 0.00000484814; 'arc second' = 0.00000484814; 'arc seconds' = 0.00000484814; 'second of arc' = 0.00000484814; 'seconds of arc' = 0.00000484814; '"' = 0.00000484814
        'mil' = 0.000981748; 'mils' = 0.000981748; 'angular mil' = 0.000981748; 'angular mils' = 0.000981748
    }
    
    # Helper function to convert angle
    Set-Item -Path Function:Global:_Convert-Angle -Value {
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
            
            # Handle special characters
            if ($FromUnit -eq '°') { $fromUnitLower = 'deg' }
            if ($FromUnit -eq '''') { $fromUnitLower = 'arcmin' }
            if ($FromUnit -eq '"') { $fromUnitLower = 'arcsec' }
            if ($ToUnit -eq '°') { $toUnitLower = 'deg' }
            if ($ToUnit -eq '''') { $toUnitLower = 'arcmin' }
            if ($ToUnit -eq '"') { $toUnitLower = 'arcsec' }
            
            # Check if units are valid
            if (-not $script:AngleUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:AngleUnits.Keys -join ', ')"
            }
            if (-not $script:AngleUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:AngleUnits.Keys -join ', ')"
            }
            
            # Convert to radians first, then to target unit
            $radians = $Value * $script:AngleUnits[$fromUnitLower]
            $result = $radians / $script:AngleUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Radians       = $radians
            }
        }
        catch {
            throw "Failed to convert angle: $_"
        }
    } -Force
    
    # Radians to other units
    Set-Item -Path Function:Global:_ConvertFrom-RadiansToAngle -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Radians,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Angle -Value $Radians -FromUnit 'rad' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to radians
    Set-Item -Path Function:Global:_ConvertTo-RadiansFromAngle -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Angle -Value $Value -FromUnit $FromUnit -ToUnit 'rad'
            return $result.Radians
        }
    } -Force
    
    # Public functions and aliases
    # Convert Angle
    Set-Item -Path Function:Global:Convert-Angle -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Angle @PSBoundParameters
    } -Force
    Set-Alias -Name convert-angle -Value Convert-Angle -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name angle -Value Convert-Angle -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Radians
    Set-Item -Path Function:Global:ConvertFrom-RadiansToAngle -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Radians,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-RadiansToAngle @PSBoundParameters
    } -Force
    Set-Alias -Name radians-to-angle -Value ConvertFrom-RadiansToAngle -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Radians
    Set-Item -Path Function:Global:ConvertTo-RadiansFromAngle -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-RadiansFromAngle @PSBoundParameters
    } -Force
    Set-Alias -Name angle-to-radians -Value ConvertTo-RadiansFromAngle -Scope Global -ErrorAction SilentlyContinue
}

