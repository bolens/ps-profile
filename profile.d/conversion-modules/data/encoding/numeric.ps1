# ===============================================
# Numeric encoding conversion utilities (Octal and Decimal)
# ===============================================

<#
.SYNOPSIS
    Initializes numeric encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Octal and Decimal encoding formats.
    Supports bidirectional conversions between Octal/Decimal and Roman.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreEncodingNumeric {
    # Octal to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-OctalToDecimal -Value {
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
                # First convert octal to ASCII, then ASCII to decimal
                $ascii = _ConvertFrom-OctalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToDecimal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Octal to Decimal: $_"
            }
        }
    } -Force

    # Decimal to Octal
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToOctal -Value {
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
                # First convert decimal to ASCII, then ASCII to octal
                $ascii = _ConvertFrom-DecimalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToOctal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Decimal to Octal: $_"
            }
        }
    } -Force

    # Octal to Roman
    Set-Item -Path Function:Global:_ConvertFrom-OctalToRoman -Value {
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
                # First convert octal to ASCII, then ASCII to roman
                $ascii = _ConvertFrom-OctalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToRoman -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Octal to Roman: $_"
            }
        }
    } -Force

    # Roman to Octal
    Set-Item -Path Function:Global:_ConvertFrom-RomanToOctal -Value {
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
                # First convert roman to ASCII, then ASCII to octal
                $ascii = _ConvertFrom-RomanToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToOctal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Roman to Octal: $_"
            }
        }
    } -Force

    # Decimal to Roman
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToRoman -Value {
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
                # First convert decimal to ASCII, then ASCII to roman
                $ascii = _ConvertFrom-DecimalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToRoman -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Decimal to Roman: $_"
            }
        }
    } -Force

    # Roman to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-RomanToDecimal -Value {
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
                # First convert roman to ASCII, then ASCII to decimal
                $ascii = _ConvertFrom-RomanToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToDecimal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Roman to Decimal: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for Numeric (Octal/Decimal) conversions
# ===============================================

<#
.SYNOPSIS
    Converts ASCII text to octal representation.
.DESCRIPTION
    Converts ASCII text to octal string representation. Each character is converted to its UTF-8 byte representation in octal (base 8).
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "Hi" | ConvertFrom-AsciiToOctal
    Converts "Hi" to "110 151" (octal representation).
.EXAMPLE
    ConvertFrom-AsciiToOctal -InputObject "AB" -Separator ""
    Converts "AB" to "101102" (no separator).
.OUTPUTS
    System.String
    The octal representation of the input text.
#>
function ConvertFrom-AsciiToOctal {
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
        _ConvertFrom-AsciiToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'ascii-to-octal' -Target 'ConvertFrom-AsciiToOctal'

<#
.SYNOPSIS
    Converts octal string to ASCII text.
.DESCRIPTION
    Converts an octal string back to ASCII text. The octal string should contain 3-digit octal values representing UTF-8 bytes.
.PARAMETER InputObject
    The octal string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToAscii
    Converts octal to "Hi".
.EXAMPLE
    ConvertFrom-OctalToAscii -InputObject "101102"
    Converts octal without spaces to "AB".
.OUTPUTS
    System.String
    The ASCII text representation of the input octal string.
#>
function ConvertFrom-OctalToAscii {
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
        _ConvertFrom-OctalToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'octal-to-ascii' -Target 'ConvertFrom-OctalToAscii'

<#
.SYNOPSIS
    Converts ASCII text to decimal representation.
.DESCRIPTION
    Converts ASCII text to decimal string representation. Each character is converted to its UTF-8 byte value in decimal.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "Hi" | ConvertFrom-AsciiToDecimal
    Converts "Hi" to "72 105" (decimal representation).
.EXAMPLE
    ConvertFrom-AsciiToDecimal -InputObject "AB" -Separator ","
    Converts "AB" to "65,66" (comma separator).
.OUTPUTS
    System.String
    The decimal representation of the input text.
#>
function ConvertFrom-AsciiToDecimal {
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
        _ConvertFrom-AsciiToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'ascii-to-decimal' -Target 'ConvertFrom-AsciiToDecimal'

<#
.SYNOPSIS
    Converts decimal string to ASCII text.
.DESCRIPTION
    Converts a decimal string back to ASCII text. The decimal string should contain decimal values (0-255) representing UTF-8 bytes.
.PARAMETER InputObject
    The decimal string to convert. Can be piped. Values can be separated by spaces or commas.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToAscii
    Converts decimal to "Hi".
.EXAMPLE
    ConvertFrom-DecimalToAscii -InputObject "65,66"
    Converts decimal with commas to "AB".
.OUTPUTS
    System.String
    The ASCII text representation of the input decimal string.
#>
function ConvertFrom-DecimalToAscii {
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
        _ConvertFrom-DecimalToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'decimal-to-ascii' -Target 'ConvertFrom-DecimalToAscii'

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
    Converts ModHex string to octal representation.
.DESCRIPTION
    Converts a ModHex string to octal string representation.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToOctal
    Converts ModHex to octal.
.OUTPUTS
    System.String
    The octal representation of the input ModHex string.
#>
function ConvertFrom-ModHexToOctal {
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
        _ConvertFrom-ModHexToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'modhex-to-octal' -Target 'ConvertFrom-ModHexToOctal'

<#
.SYNOPSIS
    Converts octal string to ModHex representation.
.DESCRIPTION
    Converts an octal string to ModHex string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToModHex
    Converts octal to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input octal string.
#>
function ConvertFrom-OctalToModHex {
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
        _ConvertFrom-OctalToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'octal-to-modhex' -Target 'ConvertFrom-OctalToModHex'

<#
.SYNOPSIS
    Converts ModHex string to decimal representation.
.DESCRIPTION
    Converts a ModHex string to decimal string representation.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToDecimal
    Converts ModHex to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input ModHex string.
#>
function ConvertFrom-ModHexToDecimal {
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
        _ConvertFrom-ModHexToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'modhex-to-decimal' -Target 'ConvertFrom-ModHexToDecimal'

<#
.SYNOPSIS
    Converts decimal string to ModHex representation.
.DESCRIPTION
    Converts a decimal string to ModHex string representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToModHex
    Converts decimal to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input decimal string.
#>
function ConvertFrom-DecimalToModHex {
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
        _ConvertFrom-DecimalToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'decimal-to-modhex' -Target 'ConvertFrom-DecimalToModHex'

<#
.SYNOPSIS
    Converts octal string to decimal representation.
.DESCRIPTION
    Converts an octal string to decimal string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToDecimal
    Converts octal to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input octal string.
#>
function ConvertFrom-OctalToDecimal {
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
        _ConvertFrom-OctalToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'octal-to-decimal' -Target 'ConvertFrom-OctalToDecimal'

<#
.SYNOPSIS
    Converts decimal string to octal representation.
.DESCRIPTION
    Converts a decimal string to octal string representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToOctal
    Converts decimal to octal.
.OUTPUTS
    System.String
    The octal representation of the input decimal string.
#>
function ConvertFrom-DecimalToOctal {
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
        _ConvertFrom-DecimalToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'decimal-to-octal' -Target 'ConvertFrom-DecimalToOctal'

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
    Converts octal string to Base32 representation.
.DESCRIPTION
    Converts an octal string to Base32 string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToBase32
    Converts octal to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input octal string.
#>
function ConvertFrom-OctalToBase32 {
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
        _ConvertFrom-OctalToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'octal-to-base32' -Target 'ConvertFrom-OctalToBase32'

<#
.SYNOPSIS
    Converts Base32 string to octal representation.
.DESCRIPTION
    Converts a Base32 string to octal string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToOctal
    Converts Base32 to octal.
.OUTPUTS
    System.String
    The octal representation of the input Base32 string.
#>
function ConvertFrom-Base32ToOctal {
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
        _ConvertFrom-Base32ToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'base32-to-octal' -Target 'ConvertFrom-Base32ToOctal'

<#
.SYNOPSIS
    Converts decimal string to Base32 representation.
.DESCRIPTION
    Converts a decimal string to Base32 string representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToBase32
    Converts decimal to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input decimal string.
#>
function ConvertFrom-DecimalToBase32 {
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
        _ConvertFrom-DecimalToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'decimal-to-base32' -Target 'ConvertFrom-DecimalToBase32'

<#
.SYNOPSIS
    Converts Base32 string to decimal representation.
.DESCRIPTION
    Converts a Base32 string to decimal string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToDecimal
    Converts Base32 to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input Base32 string.
#>
function ConvertFrom-Base32ToDecimal {
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
        _ConvertFrom-Base32ToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'base32-to-decimal' -Target 'ConvertFrom-Base32ToDecimal'

<#
.SYNOPSIS
    Converts octal string to URL/percent encoded representation.
.DESCRIPTION
    Converts an octal string to URL/percent encoded string representation.
.PARAMETER InputObject
    The octal string to convert. Can be piped.
.EXAMPLE
    "110 151" | ConvertFrom-OctalToUrl
    Converts octal to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input octal string.
#>
function ConvertFrom-OctalToUrl {
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
        _ConvertFrom-OctalToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'octal-to-url' -Target 'ConvertFrom-OctalToUrl'

<#
.SYNOPSIS
    Converts URL/percent encoded string to octal representation.
.DESCRIPTION
    Converts a URL/percent encoded string to octal string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToOctal
    Converts URL encoding to octal.
.OUTPUTS
    System.String
    The octal representation of the input URL encoded string.
#>
function ConvertFrom-UrlToOctal {
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
        _ConvertFrom-UrlToOctal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'url-to-octal' -Target 'ConvertFrom-UrlToOctal'

<#
.SYNOPSIS
    Converts decimal string to URL/percent encoding representation.
.DESCRIPTION
    Converts a decimal string to URL/percent encoding representation.
.PARAMETER InputObject
    The decimal string to convert. Can be piped.
.EXAMPLE
    "72 105" | ConvertFrom-DecimalToUrl
    Converts decimal to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input decimal string.
#>
function ConvertFrom-DecimalToUrl {
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
        _ConvertFrom-DecimalToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'decimal-to-url' -Target 'ConvertFrom-DecimalToUrl'

<#
.SYNOPSIS
    Converts URL/percent encoded string to decimal representation.
.DESCRIPTION
    Converts a URL/percent encoded string to decimal string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.PARAMETER Separator
    Optional separator between decimal values. Default is a space.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToDecimal
    Converts URL encoding to decimal.
.OUTPUTS
    System.String
    The decimal representation of the input URL encoded string.
#>
function ConvertFrom-UrlToDecimal {
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
        _ConvertFrom-UrlToDecimal -InputObject $InputObject -Separator $Separator
    }
}
Set-AgentModeAlias -Name 'url-to-decimal' -Target 'ConvertFrom-UrlToDecimal'

