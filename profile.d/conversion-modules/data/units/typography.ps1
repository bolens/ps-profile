# ===============================================
# Typography unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Typography unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for typography and print unit conversions.
    Supports conversions between points, picas, pixels (at a given DPI), inches, millimeters, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is meters. Pixel conversions require a -Dpi parameter (default 96).
#>
function Initialize-FileConversion-CoreUnitsTypography {
    $script:TypographyUnits = @{
        'pt' = 0.0254 / 72; 'point' = 0.0254 / 72; 'points' = 0.0254 / 72
        'pc' = 0.0254 / 6; 'pica' = 0.0254 / 6; 'picas' = 0.0254 / 6
        'm' = 1; 'meter' = 1; 'meters' = 1
        'in' = 0.0254; 'inch' = 0.0254; 'inches' = 0.0254
        'mm' = 0.001; 'millimeter' = 0.001; 'millimeters' = 0.001
        'cm' = 0.01; 'centimeter' = 0.01; 'centimeters' = 0.01
        'q' = 0.00025; 'quarter millimeter' = 0.00025
        'em' = 0.0254 / 72; 'rem' = 0.0254 / 72
    }

    Set-Item -Path Function:Global:_Get-TypographyUnitFactorToMeters -Value {
        param(
            [Parameter(Mandatory)]
            [string]$Unit,
            [int]$Dpi = 96
        )

        $unitLower = $Unit.ToLower()
        if ($unitLower -in @('px', 'pixel', 'pixels')) {
            if ($Dpi -le 0) {
                throw 'Dpi must be greater than zero for pixel conversions.'
            }
            return 0.0254 / $Dpi
        }
        if (-not $script:TypographyUnits.ContainsKey($unitLower)) {
            throw "Invalid typography unit: '$Unit'."
        }
        return $script:TypographyUnits[$unitLower]
    } -Force

    Set-Item -Path Function:Global:_Convert-Typography -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [int]$Dpi = 96
        )

        try {
            $fromFactor = _Get-TypographyUnitFactorToMeters -Unit $FromUnit -Dpi $Dpi
            $toFactor = _Get-TypographyUnitFactorToMeters -Unit $ToUnit -Dpi $Dpi

            $meters = $Value * $fromFactor
            $result = $meters / $toFactor

            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Meters        = $meters
                Dpi           = $Dpi
            }
        }
        catch {
            throw "Failed to convert typography units: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-MetersToTypography -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Meters,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [int]$Dpi = 96
        )
        process {
            return _Convert-Typography -Value $Meters -FromUnit 'm' -ToUnit $ToUnit -Dpi $Dpi
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-MetersFromTypography -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [int]$Dpi = 96
        )
        process {
            $fromFactor = _Get-TypographyUnitFactorToMeters -Unit $FromUnit -Dpi $Dpi
            return $Value * $fromFactor
        }
    } -Force

    Set-Item -Path Function:Global:Convert-Typography -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [int]$Dpi = 96
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Typography @PSBoundParameters
    } -Force
    Set-Alias -Name typography -Value Convert-Typography -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-MetersToTypography -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Meters,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [int]$Dpi = 96
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-MetersToTypography @PSBoundParameters
    } -Force
    Set-Alias -Name meters-to-typography -Value ConvertFrom-MetersToTypography -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-MetersFromTypography -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [int]$Dpi = 96
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-MetersFromTypography @PSBoundParameters
    } -Force
    Set-Alias -Name typography-to-meters -Value ConvertTo-MetersFromTypography -Scope Global -ErrorAction SilentlyContinue
}
