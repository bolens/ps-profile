# ===============================================
# Flow rate unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Flow rate unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for volumetric flow rate conversions.
    Supports conversions between L/s, L/min, gpm, cfm, m³/h, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is liters per second. All conversions go through L/s as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsFlowRate {
    $script:FlowRateUnits = @{
        'l/s' = 1; 'liter per second' = 1; 'liters per second' = 1; 'litre per second' = 1; 'litres per second' = 1
        'l/min' = 0.0166666667; 'lpm' = 0.0166666667; 'liter per minute' = 0.0166666667; 'liters per minute' = 0.0166666667
        'l/h' = 0.0002777778; 'liter per hour' = 0.0002777778; 'liters per hour' = 0.0002777778
        'ml/s' = 0.001; 'milliliter per second' = 0.001; 'milliliters per second' = 0.001
        'm3/s' = 1000; 'cubic meter per second' = 1000; 'cubic meters per second' = 1000
        'm3/min' = 16.6666667; 'cubic meter per minute' = 16.6666667
        'm3/h' = 0.277777778; 'cubic meter per hour' = 0.277777778; 'cubic meters per hour' = 0.277777778
        'gpm' = 0.0630901964; 'gallon per minute' = 0.0630901964; 'gallons per minute' = 0.0630901964; 'gpm us' = 0.0630901964
        'gpm uk' = 0.0757682117; 'imperial gallon per minute' = 0.0757682117
        'cfm' = 0.471947443; 'cubic foot per minute' = 0.471947443; 'cubic feet per minute' = 0.471947443
        'ft3/s' = 28.316846592; 'cubic foot per second' = 28.316846592; 'cubic feet per second' = 28.316846592
        'gal/min' = 0.0630901964; 'gal/s' = 3.785411784
    }

    Set-Item -Path Function:Global:_Convert-FlowRate -Value {
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

            if (-not $script:FlowRateUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:FlowRateUnits.Keys -join ', ')"
            }
            if (-not $script:FlowRateUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:FlowRateUnits.Keys -join ', ')"
            }

            $litersPerSecond = $Value * $script:FlowRateUnits[$fromUnitLower]
            $result = $litersPerSecond / $script:FlowRateUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value            = $result
                Unit             = $ToUnit
                OriginalValue    = $Value
                OriginalUnit     = $FromUnit
                LitersPerSecond  = $litersPerSecond
            }
        }
        catch {
            throw "Failed to convert flow rate: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-LitersPerSecondToFlowRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$LitersPerSecond,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-FlowRate -Value $LitersPerSecond -FromUnit 'l/s' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-LitersPerSecondFromFlowRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-FlowRate -Value $Value -FromUnit $FromUnit -ToUnit 'l/s'
            return $result.LitersPerSecond
        }
    } -Force

    Set-Item -Path Function:Global:Convert-FlowRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-FlowRate @PSBoundParameters
    } -Force
    Set-Alias -Name flowrate -Value Convert-FlowRate -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-LitersPerSecondToFlowRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$LitersPerSecond,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-LitersPerSecondToFlowRate @PSBoundParameters
    } -Force
    Set-Alias -Name l-s-to-flowrate -Value ConvertFrom-LitersPerSecondToFlowRate -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-LitersPerSecondFromFlowRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-LitersPerSecondFromFlowRate @PSBoundParameters
    } -Force
    Set-Alias -Name flowrate-to-l-s -Value ConvertTo-LitersPerSecondFromFlowRate -Scope Global -ErrorAction SilentlyContinue
}
