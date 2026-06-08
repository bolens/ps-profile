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
    Converts binary string to ASCII text.

.DESCRIPTION
    Converts a binary string back to ASCII text. The binary string should contain 8-bit chunks representing UTF-8 bytes.

.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The ASCII text representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToAscii
    Converts binary to "Hi".

.EXAMPLE
    ConvertFrom-BinaryToAscii -InputObject "0100000101000010"
    Converts binary without spaces to "AB".
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
    Converts binary string to hexadecimal representation.

.DESCRIPTION
    Converts a binary string to hexadecimal string representation. Each 8-bit binary chunk is converted to a hex byte.

.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The hexadecimal representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToHex
    Converts binary to hex.

.EXAMPLE
    ConvertFrom-BinaryToHex -InputObject "11111111"
    Converts binary to "FF".
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

.OUTPUTS
    System.String
    The ModHex representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToModHex
    Converts binary to ModHex.

.EXAMPLE
    ConvertFrom-BinaryToModHex -InputObject "11111111"
    Converts binary to ModHex.
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
    Converts binary string to octal representation.

.DESCRIPTION
    Converts a binary string to octal string representation.

.PARAMETER InputObject
    The binary string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.

.OUTPUTS
    System.String
    The octal representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToOctal
    Converts binary to octal.
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
    Converts binary string to decimal representation.

.DESCRIPTION
    Converts a binary string to decimal string representation.

.PARAMETER InputObject
    The binary string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between decimal values. Default is a space.

.OUTPUTS
    System.String
    The decimal representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToDecimal
    Converts binary to decimal.
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
    Converts binary string to Roman numeral representation.

.DESCRIPTION
    Converts a binary string to Roman numeral string representation.

.PARAMETER InputObject
    The binary string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.

.OUTPUTS
    System.String
    The Roman numeral representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToRoman
    Converts binary to Roman numerals.
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
    Converts binary string to Base32 representation.

.DESCRIPTION
    Converts a binary string to Base32 string representation.

.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The Base32 representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToBase32
    Converts binary to Base32.
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
    Converts binary string to URL/percent encoded representation.

.DESCRIPTION
    Converts a binary string to URL/percent encoded string representation.

.PARAMETER InputObject
    The binary string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The URL/percent encoded representation of the input binary string.

.EXAMPLE
    "01001000 01101001" | ConvertFrom-BinaryToUrl
    Converts binary to URL encoding.
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

