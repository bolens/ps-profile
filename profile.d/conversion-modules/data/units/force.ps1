# ===============================================
# Force unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Force unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for force unit conversions.
    Supports conversions between newtons, pound-force, kilogram-force, dynes, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is newtons. All conversions go through newtons as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsForce {
    $script:ForceUnits = @{
        'n' = 1; 'newton' = 1; 'newtons' = 1
        'kn' = 1000; 'kilonewton' = 1000; 'kilonewtons' = 1000
        'mn' = 1000000; 'meganewton' = 1000000; 'meganewtons' = 1000000
        'lbf' = 4.4482216153; 'pound-force' = 4.4482216153; 'pounds-force' = 4.4482216153; 'lb f' = 4.4482216153
        'kgf' = 9.80665; 'kilogram-force' = 9.80665; 'kilograms-force' = 9.80665; 'kg force' = 9.80665
        'dyn' = 0.00001; 'dyne' = 0.00001; 'dynes' = 0.00001
        'poundal' = 0.1382549544; 'poundals' = 0.1382549544
        'ozf' = 0.278013851; 'ounce-force' = 0.278013851; 'ounces-force' = 0.278013851
    }

    Set-Item -Path Function:Global:_Convert-Force -Value {
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

            if (-not $script:ForceUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:ForceUnits.Keys -join ', ')"
            }
            if (-not $script:ForceUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:ForceUnits.Keys -join ', ')"
            }

            $newtons = $Value * $script:ForceUnits[$fromUnitLower]
            $result = $newtons / $script:ForceUnits[$toUnitLower]

            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Newtons       = $newtons
            }
        }
        catch {
            throw "Failed to convert force: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-NewtonsToForce -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Newtons,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Force -Value $Newtons -FromUnit 'n' -ToUnit $ToUnit
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-NewtonsFromForce -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Force -Value $Value -FromUnit $FromUnit -ToUnit 'n'
            return $result.Newtons
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Force -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Force @PSBoundParameters
    } -Force
    Set-Alias -Name force -Value Convert-Force -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-NewtonsToForce -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Newtons,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-NewtonsToForce @PSBoundParameters
    } -Force
    Set-Alias -Name newtons-to-force -Value ConvertFrom-NewtonsToForce -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-NewtonsFromForce -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-NewtonsFromForce @PSBoundParameters
    } -Force
    Set-Alias -Name force-to-newtons -Value ConvertTo-NewtonsFromForce -Scope Global -ErrorAction SilentlyContinue
}
