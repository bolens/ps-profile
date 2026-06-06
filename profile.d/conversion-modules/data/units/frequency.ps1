# ===============================================
# Frequency unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Frequency unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for frequency and rotational speed conversions.
    Supports conversions between hertz, kilohertz, megahertz, rpm, rad/s, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is hertz. All conversions go through Hz as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsFrequency {
    $script:FrequencyUnits = @{
        'hz' = 1; 'hertz' = 1
        'khz' = 1000; 'kilohertz' = 1000
        'mhz' = 1000000; 'megahertz' = 1000000
        'ghz' = 1000000000; 'gigahertz' = 1000000000
        'thz' = 1000000000000; 'terahertz' = 1000000000000
        'millihz' = 0.001
        'rpm' = 0.0166666667; 'revolutions per minute' = 0.0166666667; 'rev/min' = 0.0166666667
        'rps' = 1; 'revolutions per second' = 1; 'rev/s' = 1
        'rad/s' = 0.1591549431; 'radians per second' = 0.1591549431
        'deg/s' = 0.0027777778; 'degrees per second' = 0.0027777778
    }

    Set-Item -Path Function:Global:_Convert-Frequency -Value {
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

            if (-not $script:FrequencyUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:FrequencyUnits.Keys -join ', ')"
            }
            if (-not $script:FrequencyUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:FrequencyUnits.Keys -join ', ')"
            }

            $hertz = $Value * $script:FrequencyUnits[$fromUnitLower]
            $result = $hertz / $script:FrequencyUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Hertz         = $hertz
            }
        }
        catch {
            throw "Failed to convert frequency: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-HertzToFrequency -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Hertz,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Frequency -Value $Hertz -FromUnit 'hz' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-HertzFromFrequency -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Frequency -Value $Value -FromUnit $FromUnit -ToUnit 'hz'
            return $result.Hertz
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Frequency -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Frequency @PSBoundParameters
    } -Force
    Set-Alias -Name frequency -Value Convert-Frequency -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-HertzToFrequency -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Hertz,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-HertzToFrequency @PSBoundParameters
    } -Force
    Set-Alias -Name hz-to-frequency -Value ConvertFrom-HertzToFrequency -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-HertzFromFrequency -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-HertzFromFrequency @PSBoundParameters
    } -Force
    Set-Alias -Name frequency-to-hz -Value ConvertTo-HertzFromFrequency -Scope Global -ErrorAction SilentlyContinue
}
