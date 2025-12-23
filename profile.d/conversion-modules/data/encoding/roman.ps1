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
    Converts ASCII text to Roman numeral representation.
.DESCRIPTION
    Converts ASCII text to Roman numeral string representation. Each character is converted to its UTF-8 byte value as a Roman numeral.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "A" | ConvertFrom-AsciiToRoman
    Converts "A" to "LXXII" (65 in Roman).
.EXAMPLE
    ConvertFrom-AsciiToRoman -InputObject "Hi" -Separator ","
    Converts "Hi" to "LXXII,CV" (comma separator).
.OUTPUTS
    System.String
    The Roman numeral representation of the input text.
#>
function ConvertFrom-AsciiToRoman {
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
        _ConvertFrom-AsciiToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'ascii-to-roman' -Target 'ConvertFrom-AsciiToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to ASCII text.
.DESCRIPTION
    Converts a Roman numeral string back to ASCII text. The Roman numerals should represent UTF-8 byte values (1-255).
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped. Roman numerals should be separated by spaces.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToAscii
    Converts Roman numerals to "Hi".
.EXAMPLE
    ConvertFrom-RomanToAscii -InputObject "LXV LXVII"
    Converts Roman numerals to "AB".
.OUTPUTS
    System.String
    The ASCII text representation of the input Roman numeral string.
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
    Converts hexadecimal string to Roman numeral representation.
.DESCRIPTION
    Converts a hexadecimal string to Roman numeral string representation.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "4865" | ConvertFrom-HexToRoman
    Converts hex to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input hex string.
#>
function ConvertFrom-HexToRoman {
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
        _ConvertFrom-HexToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'hex-to-roman' -Target 'ConvertFrom-HexToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to hexadecimal representation.
.DESCRIPTION
    Converts a Roman numeral string to hexadecimal string representation.
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToHex
    Converts Roman numerals to hex.
.OUTPUTS
    System.String
    The hexadecimal representation of the input Roman numeral string.
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
    Converts binary string to Roman numeral representation.
.DESCRIPTION
    Converts a binary string to Roman numeral string representation.
.PARAMETER InputObject
    The binary string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToRoman
    Converts binary to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input binary string.
#>
function ConvertFrom-BinaryToRoman {
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
        _ConvertFrom-BinaryToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'binary-to-roman' -Target 'ConvertFrom-BinaryToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to binary representation.
.DESCRIPTION
    Converts a Roman numeral string to binary string representation.
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToBinary
    Converts Roman numerals to binary.
.OUTPUTS
    System.String
    The binary representation of the input Roman numeral string.
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
    Converts ModHex string to Roman numeral representation.
.DESCRIPTION
    Converts a ModHex string to Roman numeral string representation.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToRoman
    Converts ModHex to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input ModHex string.
#>
function ConvertFrom-ModHexToRoman {
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
        _ConvertFrom-ModHexToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'modhex-to-roman' -Target 'ConvertFrom-ModHexToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to ModHex representation.
.DESCRIPTION
    Converts a Roman numeral string to ModHex string representation.
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToModHex
    Converts Roman numerals to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input Roman numeral string.
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
    Converts octal string to Roman numeral representation.
.DESCRIPTION
    Converts an octal string to Roman numeral string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToRoman
    Converts octal to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input octal string.
#>
function ConvertFrom-OctalToRoman {
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
        _ConvertFrom-OctalToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'octal-to-roman' -Target 'ConvertFrom-OctalToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to octal representation.
.DESCRIPTION
    Converts a Roman numeral string to octal string representation.
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToOctal
    Converts Roman numerals to octal.
.OUTPUTS
    System.String
    The octal representation of the input Roman numeral string.
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
    Converts decimal string to Roman numeral representation.
.DESCRIPTION
    Converts a decimal string to Roman numeral string representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToRoman
    Converts decimal to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input decimal string.
#>
function ConvertFrom-DecimalToRoman {
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
        _ConvertFrom-DecimalToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'decimal-to-roman' -Target 'ConvertFrom-DecimalToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to decimal representation.
.DESCRIPTION
    Converts a Roman numeral string to decimal string representation.
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToDecimal
    Converts Roman numerals to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input Roman numeral string.
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
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToBase32
    Converts Roman numerals to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input Roman numeral string.
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
    Converts Base32 string to Roman numeral representation.
.DESCRIPTION
    Converts a Base32 string to Roman numeral string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToRoman
    Converts Base32 to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input Base32 string.
#>
function ConvertFrom-Base32ToRoman {
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
        _ConvertFrom-Base32ToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'base32-to-roman' -Target 'ConvertFrom-Base32ToRoman'

<#
.SYNOPSIS
    Converts Roman numeral string to URL/percent encoded representation.
.DESCRIPTION
    Converts a Roman numeral string to URL/percent encoded string representation.
.PARAMETER InputObject
    The Roman numeral string to convert. Can be piped.
.EXAMPLE
    "LXXII CV" | ConvertFrom-RomanToUrl
    Converts Roman numerals to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input Roman numeral string.
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

<#
.SYNOPSIS
    Converts URL/percent encoded string to Roman numeral representation.
.DESCRIPTION
    Converts a URL/percent encoded string to Roman numeral string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToRoman
    Converts URL encoding to Roman numerals.
.OUTPUTS
    System.String
    The Roman numeral representation of the input URL encoded string.
#>
function ConvertFrom-UrlToRoman {
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
        _ConvertFrom-UrlToRoman -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'url-to-roman' -Target 'ConvertFrom-UrlToRoman'

