# ===============================================
# Number base conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes number base conversion utility functions.
.DESCRIPTION
    Sets up internal functions for converting numbers between different bases.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-NumberBase {
    # Number Base Converter
    Set-Item -Path Function:Global:_Convert-NumberBase -Value {
        param(
            [string]$Number,
            [ValidateSet('Binary', 'Octal', 'Decimal', 'Hexadecimal')]
            [string]$FromBase = 'Decimal',
            [ValidateSet('Binary', 'Octal', 'Decimal', 'Hexadecimal')]
            [string]$ToBase = 'Hexadecimal'
        )
        try {
            $decimal = switch ($FromBase) {
                'Binary' { [Convert]::ToInt32($Number, 2) }
                'Octal' { [Convert]::ToInt32($Number, 8) }
                'Decimal' { [int]$Number }
                'Hexadecimal' { [Convert]::ToInt32($Number, 16) }
            }
            $result = switch ($ToBase) {
                'Binary' { [Convert]::ToString($decimal, 2) }
                'Octal' { [Convert]::ToString($decimal, 8) }
                'Decimal' { $decimal.ToString() }
                'Hexadecimal' { [Convert]::ToString($decimal, 16).ToUpper() }
            }
            [PSCustomObject]@{
                Original = $Number
                FromBase = $FromBase
                ToBase   = $ToBase
                Result   = $result
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.data.number-base.convert' -Context @{
                    from_base = $FromBase
                    to_base   = $ToBase
                    number    = $Number
                }
            }
            else {
                Write-Error "Failed to convert number base: $_"
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts numbers between different bases.
.DESCRIPTION
    Converts numbers between Binary, Octal, Decimal, and Hexadecimal bases.
.PARAMETER Number
    The number to convert (as a string).
.PARAMETER FromBase
    The base of the input number. Default is Decimal.
.PARAMETER ToBase
    The base to convert to. Default is Hexadecimal.
.EXAMPLE
    Convert-NumberBase -Number "255" -FromBase Decimal -ToBase Hexadecimal
    Converts 255 from decimal to hexadecimal (FF).
.EXAMPLE
    Convert-NumberBase -Number "1010" -FromBase Binary -ToBase Decimal
    Converts binary 1010 to decimal (10).
.OUTPUTS
    PSCustomObject
    Object containing Original, FromBase, ToBase, and Result properties.
#>
function Convert-NumberBase {
    param(
        [string]$Number,
        [ValidateSet('Binary', 'Octal', 'Decimal', 'Hexadecimal')]
        [string]$FromBase = 'Decimal',
        [ValidateSet('Binary', 'Octal', 'Decimal', 'Hexadecimal')]
        [string]$ToBase = 'Hexadecimal'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Convert-NumberBase @PSBoundParameters
}
Set-Alias -Name base-convert -Value Convert-NumberBase -ErrorAction SilentlyContinue

