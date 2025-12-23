# ===============================================
# Hexadecimal encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes hexadecimal encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for hexadecimal encoding format.
    Supports bidirectional conversions between Hex and Binary, Octal, Decimal, and Roman.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreEncodingHex {
    # Hex to Binary
    Set-Item -Path Function:Global:_ConvertFrom-HexToBinary -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Remove spaces and common separators
                $hexString = $InputObject -replace '[^0-9A-Fa-f]', ''
                if ($hexString.Length % 2 -ne 0) {
                    throw "Hex string length must be even (got $($hexString.Length) characters)"
                }
                $binaryStrings = for ($i = 0; $i -lt $hexString.Length; $i += 2) {
                    $byteValue = [Convert]::ToByte($hexString.Substring($i, 2), 16)
                    [Convert]::ToString($byteValue, 2).PadLeft(8, '0')
                }
                return $binaryStrings -join $Separator
            }
            catch {
                throw "Failed to convert Hex to Binary: $_"
            }
        }
    } -Force

    # Binary to Hex
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Remove spaces and split into 8-bit chunks
                $binaryString = $InputObject -replace '\s+', ''
                if ($binaryString.Length % 8 -ne 0) {
                    throw "Binary string length must be a multiple of 8 (got $($binaryString.Length) bits)"
                }
                if ($binaryString -notmatch '^[01]+$') {
                    throw "Binary string contains invalid characters (only 0 and 1 allowed)"
                }
                $hexStrings = for ($i = 0; $i -lt $binaryString.Length; $i += 8) {
                    $byteValue = [Convert]::ToByte($binaryString.Substring($i, 8), 2)
                    $byteValue.ToString('X2')
                }
                return ($hexStrings -join '').ToUpper()
            }
            catch {
                throw "Failed to convert Binary to Hex: $_"
            }
        }
    } -Force

    # Hex to Octal
    Set-Item -Path Function:Global:_ConvertFrom-HexToOctal -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert hex to ASCII, then ASCII to octal
                $ascii = _ConvertFrom-HexToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToOctal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Hex to Octal: $_"
            }
        }
    } -Force

    # Octal to Hex
    Set-Item -Path Function:Global:_ConvertFrom-OctalToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert octal to ASCII, then ASCII to hex
                $ascii = _ConvertFrom-OctalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToHex -InputObject $ascii
            }
            catch {
                throw "Failed to convert Octal to Hex: $_"
            }
        }
    } -Force

    # Hex to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-HexToDecimal -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert hex to ASCII, then ASCII to decimal
                $ascii = _ConvertFrom-HexToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToDecimal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Hex to Decimal: $_"
            }
        }
    } -Force

    # Decimal to Hex
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert decimal to ASCII, then ASCII to hex
                $ascii = _ConvertFrom-DecimalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToHex -InputObject $ascii
            }
            catch {
                throw "Failed to convert Decimal to Hex: $_"
            }
        }
    } -Force

    # Hex to Roman
    Set-Item -Path Function:Global:_ConvertFrom-HexToRoman -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert hex to ASCII, then ASCII to roman
                $ascii = _ConvertFrom-HexToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToRoman -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Hex to Roman: $_"
            }
        }
    } -Force

    # Roman to Hex
    Set-Item -Path Function:Global:_ConvertFrom-RomanToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert roman to ASCII, then ASCII to hex
                $ascii = _ConvertFrom-RomanToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToHex -InputObject $ascii
            }
            catch {
                throw "Failed to convert Roman to Hex: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for Hex conversions
# ===============================================

<#
.SYNOPSIS
    Converts hexadecimal string to ASCII text.
.DESCRIPTION
    Converts a hexadecimal string back to ASCII text. The hex string should contain pairs of hex digits representing UTF-8 bytes.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToAscii
    Converts "48656C6C6F" to "Hello".
.EXAMPLE
    ConvertFrom-HexToAscii -InputObject "48 65 6C 6C 6F"
    Converts hex with spaces to "Hello".
.OUTPUTS
    System.String
    The ASCII text representation of the input hex string.
#>
function ConvertFrom-HexToAscii {
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
        if ([string]::IsNullOrEmpty($InputObject)) {
            return ''
        }
        _ConvertFrom-HexToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'hex-to-ascii' -Target 'ConvertFrom-HexToAscii'

<#
.SYNOPSIS
    Converts hexadecimal string to binary representation.
.DESCRIPTION
    Converts a hexadecimal string to binary string representation. Each hex byte is converted to an 8-bit binary value.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "4865" | ConvertFrom-HexToBinary
    Converts hex to binary with spaces.
.EXAMPLE
    ConvertFrom-HexToBinary -InputObject "FF" -Separator ""
    Converts hex to binary without separator.
.OUTPUTS
    System.String
    The binary representation of the input hex string.
#>
function ConvertFrom-HexToBinary {
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
        _ConvertFrom-HexToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'hex-to-binary' -Target 'ConvertFrom-HexToBinary'

<#
.SYNOPSIS
    Converts binary string to hexadecimal representation.
.DESCRIPTION
    Converts a binary string to hexadecimal string representation. Each 8-bit binary chunk is converted to a hex byte.
.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToHex
    Converts binary to hex.
.EXAMPLE
    ConvertFrom-BinaryToHex -InputObject "11111111"
    Converts binary to "FF".
.OUTPUTS
    System.String
    The hexadecimal representation of the input binary string.
#>
function ConvertFrom-BinaryToHex {
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
        _ConvertFrom-BinaryToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'binary-to-hex' -Target 'ConvertFrom-BinaryToHex'

<#
.SYNOPSIS
    Converts hexadecimal string to ModHex representation.
.DESCRIPTION
    Converts a hexadecimal string to ModHex (modified hexadecimal) representation. ModHex uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.
.EXAMPLE
    "4865" | ConvertFrom-HexToModHex
    Converts hex to ModHex.
.EXAMPLE
    ConvertFrom-HexToModHex -InputObject "FF"
    Converts hex to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input hex string.
#>
function ConvertFrom-HexToModHex {
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
        _ConvertFrom-HexToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'hex-to-modhex' -Target 'ConvertFrom-HexToModHex'

<#
.SYNOPSIS
    Converts ModHex string to hexadecimal representation.
.DESCRIPTION
    Converts a ModHex (modified hexadecimal) string to standard hexadecimal representation.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToHex
    Converts ModHex to hex.
.EXAMPLE
    ConvertFrom-ModHexToHex -InputObject "hkkllkkl"
    Converts ModHex string to hex.
.OUTPUTS
    System.String
    The hexadecimal representation of the input ModHex string.
#>
function ConvertFrom-ModHexToHex {
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
        _ConvertFrom-ModHexToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'modhex-to-hex' -Target 'ConvertFrom-ModHexToHex'

<#
.SYNOPSIS
    Converts hexadecimal string to octal representation.
.DESCRIPTION
    Converts a hexadecimal string to octal string representation.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "4865" | ConvertFrom-HexToOctal
    Converts hex to octal.
.OUTPUTS
    System.String
    The octal representation of the input hex string.
#>
function ConvertFrom-HexToOctal {
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
        _ConvertFrom-HexToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'hex-to-octal' -Target 'ConvertFrom-HexToOctal'

<#
.SYNOPSIS
    Converts octal string to hexadecimal representation.
.DESCRIPTION
    Converts an octal string to hexadecimal string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToHex
    Converts octal to hex.
.OUTPUTS
    System.String
    The hexadecimal representation of the input octal string.
#>
function ConvertFrom-OctalToHex {
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
        _ConvertFrom-OctalToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'octal-to-hex' -Target 'ConvertFrom-OctalToHex'

<#
.SYNOPSIS
    Converts hexadecimal string to decimal representation.
.DESCRIPTION
    Converts a hexadecimal string to decimal string representation.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "4865" | ConvertFrom-HexToDecimal
    Converts hex to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input hex string.
#>
function ConvertFrom-HexToDecimal {
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
        _ConvertFrom-HexToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'hex-to-decimal' -Target 'ConvertFrom-HexToDecimal'

<#
.SYNOPSIS
    Converts decimal string to hexadecimal representation.
.DESCRIPTION
    Converts a decimal string to hexadecimal string representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToHex
    Converts decimal to hex.
.OUTPUTS
    System.String
    The hexadecimal representation of the input decimal string.
#>
function ConvertFrom-DecimalToHex {
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
        _ConvertFrom-DecimalToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'decimal-to-hex' -Target 'ConvertFrom-DecimalToHex'

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
    Converts hexadecimal string to Base32 representation.
.DESCRIPTION
    Converts a hexadecimal string to Base32 string representation.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase32
    Converts hex to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input hex string.
#>
function ConvertFrom-HexToBase32 {
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
        _ConvertFrom-HexToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'hex-to-base32' -Target 'ConvertFrom-HexToBase32'

<#
.SYNOPSIS
    Converts Base32 string to hexadecimal representation.
.DESCRIPTION
    Converts a Base32 string to hexadecimal string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToHex
    Converts Base32 to hex.
.OUTPUTS
    System.String
    The hexadecimal representation of the input Base32 string.
#>
function ConvertFrom-Base32ToHex {
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
        _ConvertFrom-Base32ToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'base32-to-hex' -Target 'ConvertFrom-Base32ToHex'

<#
.SYNOPSIS
    Converts hexadecimal string to URL/percent encoded representation.
.DESCRIPTION
    Converts a hexadecimal string to URL/percent encoded string representation.
.PARAMETER InputObject
    The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToUrl
    Converts hex to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input hex string.
#>
function ConvertFrom-HexToUrl {
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
        _ConvertFrom-HexToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'hex-to-url' -Target 'ConvertFrom-HexToUrl'

<#
.SYNOPSIS
    Converts URL/percent encoded string to hexadecimal representation.
.DESCRIPTION
    Converts a URL/percent encoded string to hexadecimal string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToHex
    Converts URL encoding to hex.
.OUTPUTS
    System.String
    The hexadecimal representation of the input URL encoded string.
#>
function ConvertFrom-UrlToHex {
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
        _ConvertFrom-UrlToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'url-to-hex' -Target 'ConvertFrom-UrlToHex'

