# ===============================================
# Data Size unit conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Data Size unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for data size unit conversions.
    Supports conversions between bytes, kilobytes, megabytes, gigabytes, terabytes, petabytes, and exabytes.
    Supports both binary (1024-based) and decimal (1000-based) units.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Binary units (KiB, MiB, GiB, etc.) use 1024 as the base multiplier.
    Decimal units (KB, MB, GB, etc.) use 1000 as the base multiplier.
    Default behavior uses binary units (1024-based) for consistency with most systems.
#>
function Initialize-FileConversion-CoreUnitsDataSize {
    # Data size unit definitions (binary - 1024-based)
    # Using explicit values for clarity (PowerShell's 1MB, 1GB, etc. are 1024-based)
    $script:DataSizeUnitsBinary = @{
        'B' = 1; 'bytes' = 1; 'byte' = 1
        'KB' = 1024; 'kilobytes' = 1024; 'kilobyte' = 1024
        'MB' = 1048576; 'megabytes' = 1048576; 'megabyte' = 1048576
        'GB' = 1073741824; 'gigabytes' = 1073741824; 'gigabyte' = 1073741824
        'TB' = 1099511627776; 'terabytes' = 1099511627776; 'terabyte' = 1099511627776
        'PB' = 1125899906842624; 'petabytes' = 1125899906842624; 'petabyte' = 1125899906842624
        'EB' = 1152921504606846976; 'exabytes' = 1152921504606846976; 'exabyte' = 1152921504606846976
        # Binary units (IEC standard - same values as above)
        'KiB' = 1024; 'kibibytes' = 1024; 'kibibyte' = 1024
        'MiB' = 1048576; 'mebibytes' = 1048576; 'mebibyte' = 1048576
        'GiB' = 1073741824; 'gibibytes' = 1073741824; 'gibibyte' = 1073741824
        'TiB' = 1099511627776; 'tebibytes' = 1099511627776; 'tebibyte' = 1099511627776
        'PiB' = 1125899906842624; 'pebibytes' = 1125899906842624; 'pebibyte' = 1125899906842624
        'EiB' = 1152921504606846976; 'exbibytes' = 1152921504606846976; 'exbibyte' = 1152921504606846976
    }
    
    # Data size unit definitions (decimal - 1000-based)
    $script:DataSizeUnitsDecimal = @{
        'B' = 1; 'bytes' = 1; 'byte' = 1
        'KB' = 1000; 'kilobytes' = 1000; 'kilobyte' = 1000
        'MB' = 1000000; 'megabytes' = 1000000; 'megabyte' = 1000000
        'GB' = 1000000000; 'gigabytes' = 1000000000; 'gigabyte' = 1000000000
        'TB' = 1000000000000; 'terabytes' = 1000000000000; 'terabyte' = 1000000000000
        'PB' = 1000000000000000; 'petabytes' = 1000000000000000; 'petabyte' = 1000000000000000
        'EB' = 1000000000000000000; 'exabytes' = 1000000000000000000; 'exabyte' = 1000000000000000000
    }
    
    # Helper function to convert data size
    Set-Item -Path Function:Global:_Convert-DataSize -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseDecimal
        )
        
        try {
            $fromUnitLower = $FromUnit.ToLower()
            $toUnitLower = $ToUnit.ToLower()
            
            # Determine which unit set to use
            $units = if ($UseDecimal) { $script:DataSizeUnitsDecimal } else { $script:DataSizeUnitsBinary }
            
            # Check if units are valid
            if (-not $units.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($units.Keys -join ', ')"
            }
            if (-not $units.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($units.Keys -join ', ')"
            }
            
            # Convert to bytes first, then to target unit
            $bytes = $Value * $units[$fromUnitLower]
            $result = $bytes / $units[$toUnitLower]
            
            return [PSCustomObject]@{
                Value         = $result
                Unit          = $ToUnit
                OriginalValue = $Value
                OriginalUnit  = $FromUnit
                Bytes         = $bytes
                IsDecimal     = $UseDecimal
            }
        }
        catch {
            throw "Failed to convert data size: $_"
        }
    } -Force
    
    # Bytes to other units
    Set-Item -Path Function:Global:_ConvertFrom-BytesToDataSize -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Bytes,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseDecimal
        )
        process {
            return _Convert-DataSize -Value $Bytes -FromUnit 'B' -ToUnit $ToUnit -UseDecimal:$UseDecimal
        }
    } -Force
    
    # Other units to bytes
    Set-Item -Path Function:Global:_ConvertTo-BytesFromDataSize -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [switch]$UseDecimal
        )
        process {
            $result = _Convert-DataSize -Value $Value -FromUnit $FromUnit -ToUnit 'B' -UseDecimal:$UseDecimal
            return $result.Bytes
        }
    } -Force
    
    # Public functions and aliases
    # Convert Data Size
    Set-Item -Path Function:Global:Convert-DataSize -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseDecimal
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-DataSize @PSBoundParameters
    } -Force
    Set-Alias -Name convert-datasize -Value Convert-DataSize -Scope Global -ErrorAction SilentlyContinue
    Set-Alias -Name datasize -Value Convert-DataSize -Scope Global -ErrorAction SilentlyContinue
    
    # Convert from Bytes
    Set-Item -Path Function:Global:ConvertFrom-BytesToDataSize -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Bytes,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseDecimal
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-BytesToDataSize @PSBoundParameters
    } -Force
    Set-Alias -Name bytes-to-datasize -Value ConvertFrom-BytesToDataSize -Scope Global -ErrorAction SilentlyContinue
    
    # Convert to Bytes
    Set-Item -Path Function:Global:ConvertTo-BytesFromDataSize -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [switch]$UseDecimal
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-BytesFromDataSize @PSBoundParameters
    } -Force
    Set-Alias -Name datasize-to-bytes -Value ConvertTo-BytesFromDataSize -Scope Global -ErrorAction SilentlyContinue
}

