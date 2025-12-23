# ===============================================
# Binary encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes binary encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for binary encoding format.
    Supports bidirectional conversions between Binary and Octal, Decimal, and Roman.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreEncodingBinary {
    # Binary to Octal
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToOctal -Value {
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
                # First convert binary to ASCII, then ASCII to octal
                $ascii = _ConvertFrom-BinaryToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToOctal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Binary to Octal: $_"
            }
        }
    } -Force

    # Octal to Binary
    Set-Item -Path Function:Global:_ConvertFrom-OctalToBinary -Value {
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
                # First convert octal to ASCII, then ASCII to binary
                $ascii = _ConvertFrom-OctalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBinary -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Octal to Binary: $_"
            }
        }
    } -Force

    # Binary to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToDecimal -Value {
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
                # First convert binary to ASCII, then ASCII to decimal
                $ascii = _ConvertFrom-BinaryToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToDecimal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Binary to Decimal: $_"
            }
        }
    } -Force

    # Decimal to Binary
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToBinary -Value {
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
                # First convert decimal to ASCII, then ASCII to binary
                $ascii = _ConvertFrom-DecimalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBinary -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Decimal to Binary: $_"
            }
        }
    } -Force

    # Binary to Roman
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToRoman -Value {
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
                # First convert binary to ASCII, then ASCII to roman
                $ascii = _ConvertFrom-BinaryToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToRoman -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Binary to Roman: $_"
            }
        }
    } -Force

    # Roman to Binary
    Set-Item -Path Function:Global:_ConvertFrom-RomanToBinary -Value {
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
                # First convert roman to ASCII, then ASCII to binary
                $ascii = _ConvertFrom-RomanToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBinary -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Roman to Binary: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for Binary conversions
# ===============================================

<#
.SYNOPSIS
    Converts ASCII text to binary representation.
.DESCRIPTION
    Converts ASCII text to binary string representation. Each character is converted to its UTF-8 byte representation in binary.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "Hi" | ConvertFrom-AsciiToBinary
    Converts "Hi" to "01001000 01101001".
.EXAMPLE
    ConvertFrom-AsciiToBinary -InputObject "AB" -Separator ""
    Converts "AB" to "0100000101000010" (no separator).
.OUTPUTS
    System.String
    The binary representation of the input text.
#>
function ConvertFrom-AsciiToBinary {
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
        if ([string]::IsNullOrEmpty($InputObject)) {
            return ''
        }
        _ConvertFrom-AsciiToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'ascii-to-binary' -Target 'ConvertFrom-AsciiToBinary'

<#
.SYNOPSIS
    Converts binary string to ASCII text.
.DESCRIPTION
    Converts a binary string back to ASCII text. The binary string should contain 8-bit chunks representing UTF-8 bytes.
.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToAscii
    Converts binary to "Hi".
.EXAMPLE
    ConvertFrom-BinaryToAscii -InputObject "0100000101000010"
    Converts binary without spaces to "AB".
.OUTPUTS
    System.String
    The ASCII text representation of the input binary string.
#>
function ConvertFrom-BinaryToAscii {
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
        _ConvertFrom-BinaryToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'binary-to-ascii' -Target 'ConvertFrom-BinaryToAscii'

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
    Converts binary string to ModHex representation.
.DESCRIPTION
    Converts a binary string to ModHex (modified hexadecimal) representation. First converts binary to hex, then hex to ModHex.
.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToModHex
    Converts binary to ModHex.
.EXAMPLE
    ConvertFrom-BinaryToModHex -InputObject "11111111"
    Converts binary to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input binary string.
#>
function ConvertFrom-BinaryToModHex {
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
        _ConvertFrom-BinaryToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'binary-to-modhex' -Target 'ConvertFrom-BinaryToModHex'

<#
.SYNOPSIS
    Converts ModHex string to binary representation.
.DESCRIPTION
    Converts a ModHex (modified hexadecimal) string to binary string representation. First converts ModHex to hex, then hex to binary.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToBinary
    Converts ModHex to binary with spaces.
.EXAMPLE
    ConvertFrom-ModHexToBinary -InputObject "hkkllkkl" -Separator ""
    Converts ModHex to binary without separator.
.OUTPUTS
    System.String
    The binary representation of the input ModHex string.
#>
function ConvertFrom-ModHexToBinary {
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
        _ConvertFrom-ModHexToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'modhex-to-binary' -Target 'ConvertFrom-ModHexToBinary'

<#
.SYNOPSIS
    Converts binary string to octal representation.
.DESCRIPTION
    Converts a binary string to octal string representation.
.PARAMETER InputObject
    The binary string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToOctal
    Converts binary to octal.
.OUTPUTS
    System.String
    The octal representation of the input binary string.
#>
function ConvertFrom-BinaryToOctal {
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
        _ConvertFrom-BinaryToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'binary-to-octal' -Target 'ConvertFrom-BinaryToOctal'

<#
.SYNOPSIS
    Converts octal string to binary representation.
.DESCRIPTION
    Converts an octal string to binary string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToBinary
    Converts octal to binary.
.OUTPUTS
    System.String
    The binary representation of the input octal string.
#>
function ConvertFrom-OctalToBinary {
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
        _ConvertFrom-OctalToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'octal-to-binary' -Target 'ConvertFrom-OctalToBinary'

<#
.SYNOPSIS
    Converts binary string to decimal representation.
.DESCRIPTION
    Converts a binary string to decimal string representation.
.PARAMETER InputObject
    The binary string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToDecimal
    Converts binary to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input binary string.
#>
function ConvertFrom-BinaryToDecimal {
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
        _ConvertFrom-BinaryToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'binary-to-decimal' -Target 'ConvertFrom-BinaryToDecimal'

<#
.SYNOPSIS
    Converts decimal string to binary representation.
.DESCRIPTION
    Converts a decimal string to binary string representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToBinary
    Converts decimal to binary.
.OUTPUTS
    System.String
    The binary representation of the input decimal string.
#>
function ConvertFrom-DecimalToBinary {
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
        _ConvertFrom-DecimalToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'decimal-to-binary' -Target 'ConvertFrom-DecimalToBinary'

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
    Converts binary string to Base32 representation.
.DESCRIPTION
    Converts a binary string to Base32 string representation.
.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToBase32
    Converts binary to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input binary string.
#>
function ConvertFrom-BinaryToBase32 {
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
        _ConvertFrom-BinaryToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'binary-to-base32' -Target 'ConvertFrom-BinaryToBase32'

<#
.SYNOPSIS
    Converts Base32 string to binary representation.
.DESCRIPTION
    Converts a Base32 string to binary string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToBinary
    Converts Base32 to binary.
.OUTPUTS
    System.String
    The binary representation of the input Base32 string.
#>
function ConvertFrom-Base32ToBinary {
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
        _ConvertFrom-Base32ToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'base32-to-binary' -Target 'ConvertFrom-Base32ToBinary'

<#
.SYNOPSIS
    Converts binary string to URL/percent encoded representation.
.DESCRIPTION
    Converts a binary string to URL/percent encoded string representation.
.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToUrl
    Converts binary to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input binary string.
#>
function ConvertFrom-BinaryToUrl {
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
        _ConvertFrom-BinaryToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'binary-to-url' -Target 'ConvertFrom-BinaryToUrl'

<#
.SYNOPSIS
    Converts URL/percent encoded string to binary representation.
.DESCRIPTION
    Converts a URL/percent encoded string to binary string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToBinary
    Converts URL encoding to binary.
.OUTPUTS
    System.String
    The binary representation of the input URL encoded string.
#>
function ConvertFrom-UrlToBinary {
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
        _ConvertFrom-UrlToBinary -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'url-to-binary' -Target 'ConvertFrom-UrlToBinary'

