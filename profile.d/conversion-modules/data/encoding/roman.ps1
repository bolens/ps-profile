# ===============================================
# Roman numeral encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Roman numeral encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Roman numeral encoding format.
    Supports bidirectional conversions between Roman numerals and byte values (1-255).
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Roman numerals are limited to byte values (1-255) for UTF-8 byte representation.
#>
function Initialize-FileConversion-CoreEncodingRoman {
    # Roman numeral helper functions
    Set-Item -Path Function:Global:_ConvertTo-RomanNumeral -Value {
        param([int]$Number)
        if ($Number -le 0 -or $Number -gt 255) {
            throw "Number must be between 1 and 255 for byte conversion"
        }
        $romanValues = @(
            @{ Value = 100; Numeral = 'C' },
            @{ Value = 90; Numeral = 'XC' },
            @{ Value = 50; Numeral = 'L' },
            @{ Value = 40; Numeral = 'XL' },
            @{ Value = 10; Numeral = 'X' },
            @{ Value = 9; Numeral = 'IX' },
            @{ Value = 5; Numeral = 'V' },
            @{ Value = 4; Numeral = 'IV' },
            @{ Value = 1; Numeral = 'I' }
        )
        $result = ''
        foreach ($pair in $romanValues) {
            while ($Number -ge $pair.Value) {
                $result += $pair.Numeral
                $Number -= $pair.Value
            }
        }
        return $result
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-RomanNumeral -Value {
        param([string]$Roman)
        $roman = $Roman.ToUpper().Trim()
        if ([string]::IsNullOrEmpty($roman)) {
            return 0
        }
        $romanMap = @{
            'I' = 1; 'V' = 5; 'X' = 10; 'L' = 50; 'C' = 100; 'D' = 500; 'M' = 1000
        }
        $result = 0
        $prevValue = 0
        for ($i = $roman.Length - 1; $i -ge 0; $i--) {
            $char = $roman[$i].ToString()
            if (-not $romanMap.ContainsKey($char)) {
                throw "Invalid Roman numeral character: $char"
            }
            $value = $romanMap[$char]
            if ($value -lt $prevValue) {
                $result -= $value
            }
            else {
                $result += $value
            }
            $prevValue = $value
        }
        if ($result -gt 255) {
            throw "Roman numeral value $result exceeds byte maximum (255)"
        }
        return $result
    } -Force
}

# ===============================================
# Public wrapper functions for Roman conversions
# ===============================================

<#
.SYNOPSIS
    Converts Roman numeral string to ASCII text.

.DESCRIPTION
    Converts a Roman numeral string back to ASCII text. The Roman numerals should represent UTF-8 byte values (1-255).

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped. Roman numerals should be separated by spaces.

.OUTPUTS
    System.String
    The ASCII text representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToAscii
    Converts Roman numerals to "Hi".

.EXAMPLE
    ConvertFrom-RomanToAscii -InputObject "LXV LXVII"
    Converts Roman numerals to "AB".
#>
function ConvertFrom-RomanToAscii {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'roman-to-ascii' -Target 'ConvertFrom-RomanToAscii'

<#
.SYNOPSIS
    Converts Roman numeral string to hexadecimal representation.

.DESCRIPTION
    Converts a Roman numeral string to hexadecimal string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.OUTPUTS
    System.String
    The hexadecimal representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToHex
    Converts Roman numerals to hex.
#>
function ConvertFrom-RomanToHex {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'roman-to-hex' -Target 'ConvertFrom-RomanToHex'

<#
.SYNOPSIS
    Converts Roman numeral string to binary representation.

.DESCRIPTION
    Converts a Roman numeral string to binary string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.

.OUTPUTS
    System.String
    The binary representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToBinary
    Converts Roman numerals to binary.
#>
function ConvertFrom-RomanToBinary {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject,
        [string]$Separator = ' '
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'roman-to-binary' -Target 'ConvertFrom-RomanToBinary'

<#
.SYNOPSIS
    Converts Roman numeral string to ModHex representation.

.DESCRIPTION
    Converts a Roman numeral string to ModHex string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.OUTPUTS
    System.String
    The ModHex representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToModHex
    Converts Roman numerals to ModHex.
#>
function ConvertFrom-RomanToModHex {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'roman-to-modhex' -Target 'ConvertFrom-RomanToModHex'

<#
.SYNOPSIS
    Converts Roman numeral string to octal representation.

.DESCRIPTION
    Converts a Roman numeral string to octal string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.

.OUTPUTS
    System.String
    The octal representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToOctal
    Converts Roman numerals to octal.
#>
function ConvertFrom-RomanToOctal {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject,
        [string]$Separator = ' '
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'roman-to-octal' -Target 'ConvertFrom-RomanToOctal'

<#
.SYNOPSIS
    Converts Roman numeral string to decimal representation.

.DESCRIPTION
    Converts a Roman numeral string to decimal string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between decimal values. Default is a space.

.OUTPUTS
    System.String
    The decimal representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToDecimal
    Converts Roman numerals to decimal.
#>
function ConvertFrom-RomanToDecimal {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject,
        [string]$Separator = ' '
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'roman-to-decimal' -Target 'ConvertFrom-RomanToDecimal'

<#
.SYNOPSIS
    Converts Roman numeral string to Base32 representation.

.DESCRIPTION
    Converts a Roman numeral string to Base32 string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.OUTPUTS
    System.String
    The Base32 representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToBase32
    Converts Roman numerals to Base32.
#>
function ConvertFrom-RomanToBase32 {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'roman-to-base32' -Target 'ConvertFrom-RomanToBase32'

<#
.SYNOPSIS
    Converts Roman numeral string to URL/percent encoded representation.

.DESCRIPTION
    Converts a Roman numeral string to URL/percent encoded string representation.

.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.

.OUTPUTS
    System.String
    The URL/percent encoded representation of the input Roman numeral string.

.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToUrl
    Converts Roman numerals to URL encoding.
#>
function ConvertFrom-RomanToUrl {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    begin {
        if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    }
    process {
        if ([string]::IsNullOrEmpty($InputObject)) { return '' }
        _ConvertFrom-RomanToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'roman-to-url' -Target 'ConvertFrom-RomanToUrl'

