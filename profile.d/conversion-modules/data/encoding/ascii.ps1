# ===============================================
# ASCII encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes ASCII encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ASCII encoding format.
    Supports bidirectional conversions between ASCII and Hex, Binary, Octal, Decimal, and Roman.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreEncodingAscii {
    # ASCII to Hex
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
                $hexString = ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
                return $hexString
            }
            catch {
                throw "Failed to convert ASCII to Hex: $_"
            }
        }
    } -Force

    # Hex to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-HexToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
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
                $bytes = for ($i = 0; $i -lt $hexString.Length; $i += 2) {
                    [Convert]::ToByte($hexString.Substring($i, 2), 16)
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Hex to ASCII: $_"
            }
        }
    } -Force

    # ASCII to Binary
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBinary -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
                $binaryStrings = $bytes | ForEach-Object {
                    [Convert]::ToString($_, 2).PadLeft(8, '0')
                }
                return $binaryStrings -join $Separator
            }
            catch {
                throw "Failed to convert ASCII to Binary: $_"
            }
        }
    } -Force

    # Binary to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToAscii -Value {
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
                # Validate binary string contains only 0s and 1s
                if ($binaryString -notmatch '^[01]+$') {
                    throw "Binary string contains invalid characters (only 0 and 1 allowed)"
                }
                $bytes = for ($i = 0; $i -lt $binaryString.Length; $i += 8) {
                    [Convert]::ToByte($binaryString.Substring($i, 8), 2)
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Binary to ASCII: $_"
            }
        }
    } -Force

    # ASCII to Octal
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToOctal -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
                $octalStrings = $bytes | ForEach-Object {
                    [Convert]::ToString($_, 8).PadLeft(3, '0')
                }
                return $octalStrings -join $Separator
            }
            catch {
                throw "Failed to convert ASCII to Octal: $_"
            }
        }
    } -Force

    # Octal to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-OctalToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Remove spaces and split into 3-digit chunks
                $octalString = $InputObject -replace '\s+', ''
                if ($octalString.Length % 3 -ne 0) {
                    throw "Octal string length must be a multiple of 3 (got $($octalString.Length) characters)"
                }
                # Validate octal string contains only 0-7
                if ($octalString -notmatch '^[0-7]+$') {
                    throw "Octal string contains invalid characters (only 0-7 allowed)"
                }
                $bytes = for ($i = 0; $i -lt $octalString.Length; $i += 3) {
                    [Convert]::ToByte($octalString.Substring($i, 3), 8)
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Octal to ASCII: $_"
            }
        }
    } -Force

    # ASCII to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToDecimal -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
                $decimalStrings = $bytes | ForEach-Object { $_.ToString() }
                return $decimalStrings -join $Separator
            }
            catch {
                throw "Failed to convert ASCII to Decimal: $_"
            }
        }
    } -Force

    # Decimal to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Split by spaces or commas, or assume single numbers
                $decimalStrings = $InputObject -split '[,\s]+' | Where-Object { $_ -match '^\d+$' }
                if ($decimalStrings.Count -eq 0) {
                    throw "No valid decimal numbers found in input"
                }
                $bytes = $decimalStrings | ForEach-Object {
                    $value = [int]$_
                    if ($value -lt 0 -or $value -gt 255) {
                        throw "Decimal value $value is out of byte range (0-255)"
                    }
                    [byte]$value
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Decimal to ASCII: $_"
            }
        }
    } -Force

    # ASCII to Roman
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToRoman -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject,
            [string]$Separator = ' '
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject)
                $romanStrings = $bytes | ForEach-Object {
                    _ConvertTo-RomanNumeral -Number $_
                }
                return $romanStrings -join $Separator
            }
            catch {
                throw "Failed to convert ASCII to Roman: $_"
            }
        }
    } -Force

    # Roman to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-RomanToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Split by spaces or assume single Roman numerals
                $romanStrings = $InputObject -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                if ($romanStrings.Count -eq 0) {
                    throw "No valid Roman numerals found in input"
                }
                $bytes = $romanStrings | ForEach-Object {
                    $value = _ConvertFrom-RomanNumeral -Roman $_
                    [byte]$value
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Roman to ASCII: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for ASCII conversions
# ===============================================

<#
.SYNOPSIS
    Converts ASCII text to hexadecimal representation.
.DESCRIPTION
    Converts ASCII text to hexadecimal string representation. Each character is converted to its UTF-8 byte representation in hex.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.EXAMPLE
    "Hello" | ConvertFrom-AsciiToHex
    Converts "Hello" to "48656C6C6F".
.EXAMPLE
    ConvertFrom-AsciiToHex -InputObject "World"
    Converts "World" to "576F726C64".
.OUTPUTS
    System.String
    The hexadecimal representation of the input text.
#>
function ConvertFrom-AsciiToHex {
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
        _ConvertFrom-AsciiToHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'ascii-to-hex' -Target 'ConvertFrom-AsciiToHex'

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
    Converts ASCII text to ModHex representation.
.DESCRIPTION
    Converts ASCII text to ModHex (modified hexadecimal) string representation. ModHex is used by YubiKey and similar devices.
    Uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v instead of 0-9, A-F.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.EXAMPLE
    "Hello" | ConvertFrom-AsciiToModHex
    Converts "Hello" to ModHex representation.
.EXAMPLE
    ConvertFrom-AsciiToModHex -InputObject "Test"
    Converts "Test" to ModHex representation.
.OUTPUTS
    System.String
    The ModHex representation of the input text.
#>
function ConvertFrom-AsciiToModHex {
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
        _ConvertFrom-AsciiToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'ascii-to-modhex' -Target 'ConvertFrom-AsciiToModHex'

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
    Converts ASCII text to Base32 representation.
.DESCRIPTION
    Converts ASCII text to Base32 string representation. Base32 uses the alphabet A-Z, 2-7 (32 characters) as defined in RFC 4648.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.EXAMPLE
    "Hello" | ConvertFrom-AsciiToBase32
    Converts "Hello" to Base32 representation.
.EXAMPLE
    ConvertFrom-AsciiToBase32 -InputObject "World"
    Converts "World" to Base32 representation.
.OUTPUTS
    System.String
    The Base32 representation of the input text.
#>
function ConvertFrom-AsciiToBase32 {
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
        _ConvertFrom-AsciiToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'ascii-to-base32' -Target 'ConvertFrom-AsciiToBase32'

<#
.SYNOPSIS
    Converts ASCII text to URL/percent encoded representation.
.DESCRIPTION
    Converts ASCII text to URL/percent encoded string representation following RFC 3986 specification.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToUrl
    Converts "Hello World" to "Hello%20World".
.EXAMPLE
    ConvertFrom-AsciiToUrl -InputObject "test@example.com"
    Converts to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input text.
#>
function ConvertFrom-AsciiToUrl {
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
        _ConvertFrom-AsciiToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'ascii-to-url' -Target 'ConvertFrom-AsciiToUrl'
Set-AgentModeAlias -Name 'url-encode' -Target 'ConvertFrom-AsciiToUrl'

