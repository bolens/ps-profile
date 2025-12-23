# ===============================================
# Weight/Mass unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Weight/Mass unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for weight/mass unit conversions.
    Supports conversions between kilograms, pounds, ounces, grams, tons, stones, and more.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is kilograms. All conversions go through kilograms as an intermediate step.
#>
function Initialize-FileConversion-CoreUnitsWeight {
    # Weight/Mass unit definitions (conversion factors to kilograms)
    $script:WeightUnits = @{
        # Metric units
        'kg' = 1; 'kilogram' = 1; 'kilograms' = 1
        'g' = 0.001; 'gram' = 0.001; 'grams' = 0.001
        'mg' = 0.000001; 'milligram' = 0.000001; 'milligrams' = 0.000001
        'ug' = 0.000000001; 'microgram' = 0.000000001; 'micrograms' = 0.000000001
        'ng' = 0.000000000001; 'nanogram' = 0.000000000001; 'nanograms' = 0.000000000001
        'cg' = 0.00001; 'centigram' = 0.00001; 'centigrams' = 0.00001
        'dg' = 0.0001; 'decigram' = 0.0001; 'decigrams' = 0.0001
        'dag' = 0.01; 'decagram' = 0.01; 'decagrams' = 0.01
        'hg' = 0.1; 'hectogram' = 0.1; 'hectograms' = 0.1
        't' = 1000; 'tonne' = 1000; 'tonnes' = 1000; 'metric ton' = 1000; 'metric tons' = 1000
        # Imperial/US units
        'lb' = 0.453592; 'pound' = 0.453592; 'pounds' = 0.453592; 'lbs' = 0.453592
        'oz' = 0.0283495; 'ounce' = 0.0283495; 'ounces' = 0.0283495
        'st' = 6.35029; 'stone' = 6.35029; 'stones' = 6.35029
        'ton' = 907.185; 'short ton' = 907.185; 'short tons' = 907.185; 'us ton' = 907.185; 'us tons' = 907.185
        'long ton' = 1016.05; 'long tons' = 1016.05; 'imperial ton' = 1016.05; 'imperial tons' = 1016.05
        'grain' = 0.0000647989; 'grains' = 0.0000647989
        'dram' = 0.00177185; 'drams' = 0.00177185
        'hundredweight' = 45.3592; 'cwt' = 45.3592; 'short hundredweight' = 45.3592; 'short cwt' = 45.3592
        'long hundredweight' = 50.8023; 'long cwt' = 50.8023
        # Troy units (for precious metals)
        'troy oz' = 0.0311035; 'troy ounce' = 0.0311035; 'troy ounces' = 0.0311035; 'ozt' = 0.0311035
        'troy lb' = 0.373242; 'troy pound' = 0.373242; 'troy pounds' = 0.373242
        'pennyweight' = 0.00155517; 'dwt' = 0.00155517
        # Other units
        'carat' = 0.0002; 'carats' = 0.0002; 'ct' = 0.0002
    }
    
    # Helper function to convert weight/mass
    Set-Item -Path Function:Global:_Convert-Weight -Value {
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
            if (-not $script:WeightUnits.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($script:WeightUnits.Keys -join ', ')"
            }
            if (-not $script:WeightUnits.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($script:WeightUnits.Keys -join ', ')"
            }
            
            # Convert to kilograms first, then to target unit
            $kilograms = $Value * $script:WeightUnits[$fromUnitLower]
            $result = $kilograms / $script:WeightUnits[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Kilograms     = $kilograms
            }
        }
        catch {
            throw "Failed to convert weight/mass: $_"
        }
    } -Force
    
    # Kilograms to other units
    Set-Item -Path Function:Global:_ConvertFrom-KilogramsToWeight -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Kilograms,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        process {
            return _Convert-Weight -Value $Kilograms -FromUnit 'kg' -ToUnit $ToUnit
        }
    } -Force
    
    # Other units to kilograms
    Set-Item -Path Function:Global:_ConvertTo-KilogramsFromWeight -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        process {
            $result = _Convert-Weight -Value $Value -FromUnit $FromUnit -ToUnit 'kg'
            return $result.Kilograms
        }
    } -Force
    
    # Public functions and aliases
    # Convert Weight
    Set-Item -Path Function:Global:Convert-Weight -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-Weight @PSBoundParameters
    } -Force
    Set-Alias -Name convert-weight -Value Convert-Weight -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name weight -Value Convert-Weight -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name mass -Value Convert-Weight -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Kilograms
    Set-Item -Path Function:Global:ConvertFrom-KilogramsToWeight -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Kilograms,
            [Parameter(Mandatory)]
            [string]$ToUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-KilogramsToWeight @PSBoundParameters
    } -Force
    Set-Alias -Name kg-to-weight -Value ConvertFrom-KilogramsToWeight -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Kilograms
    Set-Item -Path Function:Global:ConvertTo-KilogramsFromWeight -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-KilogramsFromWeight @PSBoundParameters
    } -Force
    Set-Alias -Name weight-to-kg -Value ConvertTo-KilogramsFromWeight -Scope Global -ErrorAction SilentlyContinue
}

