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

