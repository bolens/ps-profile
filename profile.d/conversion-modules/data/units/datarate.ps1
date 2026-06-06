# ===============================================
# Data rate unit conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Data rate unit conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for data rate / bandwidth conversions.
    Supports conversions between bps, Kbps, Mbps, Gbps, B/s, and related units.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base unit is bits per second. Network rates use decimal (1000-based) multipliers by default.
#>
function Initialize-FileConversion-CoreUnitsDataRate {
    $script:DataRateUnitsDecimal = @{
        'bps' = 1; 'bit/s' = 1; 'bits/s' = 1; 'bits per second' = 1
        'kbps' = 1000; 'kbit/s' = 1000; 'kbits/s' = 1000; 'kilobits per second' = 1000
        'mbps' = 1000000; 'mbit/s' = 1000000; 'mbits/s' = 1000000; 'megabits per second' = 1000000
        'gbps' = 1000000000; 'gbit/s' = 1000000000; 'gbits/s' = 1000000000; 'gigabits per second' = 1000000000
        'tbps' = 1000000000000; 'tbit/s' = 1000000000000; 'terabits per second' = 1000000000000
        'b/s' = 8; 'byte/s' = 8; 'bytes/s' = 8; 'bytes per second' = 8
        'kb/s' = 8000; 'kbyte/s' = 8000; 'kbytes/s' = 8000; 'kilobytes per second' = 8000
        'mb/s' = 8000000; 'mbyte/s' = 8000000; 'mbytes/s' = 8000000; 'megabytes per second' = 8000000
        'gb/s' = 8000000000; 'gbyte/s' = 8000000000; 'gbytes/s' = 8000000000; 'gigabytes per second' = 8000000000
    }

    $script:DataRateUnitsBinary = @{
        'bps' = 1; 'bit/s' = 1; 'bits/s' = 1; 'bits per second' = 1
        'kbps' = 1024; 'kbit/s' = 1024; 'kbits/s' = 1024
        'mbps' = 1048576; 'mbit/s' = 1048576; 'mbits/s' = 1048576
        'gbps' = 1073741824; 'gbit/s' = 1073741824; 'gbits/s' = 1073741824
        'b/s' = 8; 'byte/s' = 8; 'bytes/s' = 8; 'bytes per second' = 8
        'kb/s' = 8192; 'kbyte/s' = 8192; 'kbytes/s' = 8192
        'mb/s' = 8388608; 'mbyte/s' = 8388608; 'mbytes/s' = 8388608
        'gb/s' = 8589934592; 'gbyte/s' = 8589934592; 'gbytes/s' = 8589934592
    }

    Set-Item -Path Function:Global:_Convert-DataRate -Value {
        param(
            [Parameter(Mandatory)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseBinary
        )

        try {
            $fromUnitLower = $FromUnit.ToLower()
            $toUnitLower = $ToUnit.ToLower()
            $units = if ($UseBinary) { $script:DataRateUnitsBinary } else { $script:DataRateUnitsDecimal }

            if (-not $units.ContainsKey($fromUnitLower)) {
                throw "Invalid source unit: '$FromUnit'. Supported units: $($units.Keys -join ', ')"
            }
            if (-not $units.ContainsKey($toUnitLower)) {
                throw "Invalid target unit: '$ToUnit'. Supported units: $($units.Keys -join ', ')"
            }

            $bitsPerSecond = $Value * $units[$fromUnitLower]
            $result = $bitsPerSecond / $units[$toUnitLower]

            return [PSCustomObject]@{
                Value          = $result
                Unit           = $ToUnit
                OriginalValue  = $Value
                OriginalUnit   = $FromUnit
                BitsPerSecond  = $bitsPerSecond
                IsBinary       = [bool]$UseBinary
            }
        }
        catch {
            throw "Failed to convert data rate: $_"
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-BitsPerSecondToDataRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$BitsPerSecond,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseBinary
        )
        process {
            return _Convert-DataRate -Value $BitsPerSecond -FromUnit 'bps' -ToUnit $ToUnit -UseBinary:$UseBinary
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-BitsPerSecondFromDataRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [switch]$UseBinary
        )
        process {
            $result = _Convert-DataRate -Value $Value -FromUnit $FromUnit -ToUnit 'bps' -UseBinary:$UseBinary
            return $result.BitsPerSecond
        }
    } -Force

    Set-Item -Path Function:Global:Convert-DataRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseBinary
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _Convert-DataRate @PSBoundParameters
    } -Force
    Set-Alias -Name datarate -Value Convert-DataRate -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertFrom-BitsPerSecondToDataRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$BitsPerSecond,
            [Parameter(Mandatory)]
            [string]$ToUnit,
            [switch]$UseBinary
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertFrom-BitsPerSecondToDataRate @PSBoundParameters
    } -Force
    Set-Alias -Name bps-to-datarate -Value ConvertFrom-BitsPerSecondToDataRate -Scope Global -ErrorAction SilentlyContinue

    Set-Item -Path Function:Global:ConvertTo-BitsPerSecondFromDataRate -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Value,
            [Parameter(Mandatory)]
            [string]$FromUnit,
            [switch]$UseBinary
        )
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
        _ConvertTo-BitsPerSecondFromDataRate @PSBoundParameters
    } -Force
    Set-Alias -Name datarate-to-bps -Value ConvertTo-BitsPerSecondFromDataRate -Scope Global -ErrorAction SilentlyContinue
}
