# ===============================================
# URL/Percent encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes URL/Percent encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for URL/Percent encoding format.
    URL encoding (percent encoding) converts special characters to %XX format where XX is hexadecimal.
    Supports bidirectional conversions between URL encoding and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    URL encoding follows RFC 3986 specification. Reserved characters are encoded as %XX.
#>
function Initialize-FileConversion-CoreEncodingUrl {
    # ASCII to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToUrl -Value {
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
                $result = ''
                foreach ($byte in $bytes) {
                    $char = [char]$byte
                    # Unreserved characters (RFC 3986): A-Z, a-z, 0-9, -, _, ., ~
                    if (($char -match '^[A-Za-z0-9\-_.~]$')) {
                        $result += $char
                    }
                    else {
                        # Percent encode: %XX
                        $result += '%' + $byte.ToString('X2')
                    }
                }
                return $result
            }
            catch {
                throw "Failed to convert ASCII to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-UrlToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = New-Object System.Collections.ArrayList
                $i = 0
                while ($i -lt $InputObject.Length) {
                    if ($InputObject[$i] -eq '%' -and $i + 2 -lt $InputObject.Length) {
                        # Try to decode %XX
                        $hex = $InputObject.Substring($i + 1, 2)
                        if ($hex -match '^[0-9A-Fa-f]{2}$') {
                            $byte = [Convert]::ToByte($hex, 16)
                            [void]$bytes.Add($byte)
                            $i += 3
                        }
                        else {
                            # Invalid % encoding, treat as literal %
                            [void]$bytes.Add([byte][char]'%')
                            $i++
                        }
                    }
                    else {
                        # Regular character
                        $charBytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject[$i])
                        foreach ($b in $charBytes) {
                            [void]$bytes.Add($b)
                        }
                        $i++
                    }
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes.ToArray())
            }
            catch {
                throw "Failed to convert URL encoding to ASCII: $_"
            }
        }
    } -Force

    # Hex to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-HexToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert hex to ASCII, then ASCII to URL encoding
                $ascii = _ConvertFrom-HexToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToUrl -InputObject $ascii
            }
            catch {
                throw "Failed to convert Hex to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to Hex
    Set-Item -Path Function:Global:_ConvertFrom-UrlToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert URL encoding to ASCII, then ASCII to hex
                $ascii = _ConvertFrom-UrlToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToHex -InputObject $ascii
            }
            catch {
                throw "Failed to convert URL encoding to Hex: $_"
            }
        }
    } -Force

    # Binary to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert binary to ASCII, then ASCII to URL encoding
                $ascii = _ConvertFrom-BinaryToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToUrl -InputObject $ascii
            }
            catch {
                throw "Failed to convert Binary to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to Binary
    Set-Item -Path Function:Global:_ConvertFrom-UrlToBinary -Value {
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
                # First convert URL encoding to ASCII, then ASCII to binary
                $ascii = _ConvertFrom-UrlToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBinary -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert URL encoding to Binary: $_"
            }
        }
    } -Force

    # ModHex to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert ModHex to hex, then hex to URL encoding
                $hex = _ConvertFrom-ModHexToHex -InputObject $InputObject
                return _ConvertFrom-HexToUrl -InputObject $hex
            }
            catch {
                throw "Failed to convert ModHex to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-UrlToModHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert URL encoding to hex, then hex to ModHex
                $hex = _ConvertFrom-UrlToHex -InputObject $InputObject
                return _ConvertFrom-HexToModHex -InputObject $hex
            }
            catch {
                throw "Failed to convert URL encoding to ModHex: $_"
            }
        }
    } -Force

    # Base32 to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert Base32 to ASCII, then ASCII to URL encoding
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToUrl -InputObject $ascii
            }
            catch {
                throw "Failed to convert Base32 to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to Base32
    Set-Item -Path Function:Global:_ConvertFrom-UrlToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert URL encoding to ASCII, then ASCII to Base32
                $ascii = _ConvertFrom-UrlToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
            catch {
                throw "Failed to convert URL encoding to Base32: $_"
            }
        }
    } -Force

    # Octal to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-OctalToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert octal to ASCII, then ASCII to URL encoding
                $ascii = _ConvertFrom-OctalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToUrl -InputObject $ascii
            }
            catch {
                throw "Failed to convert Octal to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to Octal
    Set-Item -Path Function:Global:_ConvertFrom-UrlToOctal -Value {
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
                # First convert URL encoding to ASCII, then ASCII to octal
                $ascii = _ConvertFrom-UrlToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToOctal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert URL encoding to Octal: $_"
            }
        }
    } -Force

    # Decimal to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert decimal to ASCII, then ASCII to URL encoding
                $ascii = _ConvertFrom-DecimalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToUrl -InputObject $ascii
            }
            catch {
                throw "Failed to convert Decimal to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-UrlToDecimal -Value {
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
                # First convert URL encoding to ASCII, then ASCII to decimal
                $ascii = _ConvertFrom-UrlToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToDecimal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert URL encoding to Decimal: $_"
            }
        }
    } -Force

    # Roman to URL encoding
    Set-Item -Path Function:Global:_ConvertFrom-RomanToUrl -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert Roman to ASCII, then ASCII to URL encoding
                $ascii = _ConvertFrom-RomanToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToUrl -InputObject $ascii
            }
            catch {
                throw "Failed to convert Roman to URL encoding: $_"
            }
        }
    } -Force

    # URL encoding to Roman
    Set-Item -Path Function:Global:_ConvertFrom-UrlToRoman -Value {
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
                # First convert URL encoding to ASCII, then ASCII to Roman
                $ascii = _ConvertFrom-UrlToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToRoman -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert URL encoding to Roman: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for URL conversions
# ===============================================

<#
.SYNOPSIS
    Converts ASCII text to URL/percent encoding representation.
.DESCRIPTION
    Converts ASCII text to URL/percent encoding. Special characters are encoded as %XX where XX is hexadecimal.
    Unreserved characters (A-Z, a-z, 0-9, -, _, ., ~) are left unchanged per RFC 3986.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToUrl
    Converts "Hello World" to "Hello%20World" (space is encoded as %20).
.EXAMPLE
    ConvertFrom-AsciiToUrl -InputObject "test@example.com"
    Converts to URL encoding with @ encoded as %40.
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

<#
.SYNOPSIS
    Converts URL/percent encoded string to ASCII text.
.DESCRIPTION
    Converts a URL/percent encoded string back to ASCII text. %XX sequences are decoded to their character equivalents.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToAscii
    Converts "Hello%20World" to "Hello World".
.EXAMPLE
    ConvertFrom-UrlToAscii -InputObject "test%40example.com"
    Converts URL encoding to "test@example.com".
.OUTPUTS
    System.String
    The ASCII text representation of the input URL encoded string.
#>
function ConvertFrom-UrlToAscii {
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
        _ConvertFrom-UrlToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'url-to-ascii' -Target 'ConvertFrom-UrlToAscii'
Set-AgentModeAlias -Name 'url-decode' -Target 'ConvertFrom-UrlToAscii'

<#
.SYNOPSIS
    Converts hexadecimal string to URL/percent encoding representation.
.DESCRIPTION
    Converts a hexadecimal string to URL/percent encoding representation.
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

<#
.SYNOPSIS
    Converts binary string to URL/percent encoding representation.
.DESCRIPTION
    Converts a binary string to URL/percent encoding representation.
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
    Converts URL encoding to binary with spaces.
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

<#
.SYNOPSIS
    Converts ModHex string to URL/percent encoding representation.
.DESCRIPTION
    Converts a ModHex string to URL/percent encoding representation.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToUrl
    Converts ModHex to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input ModHex string.
#>
function ConvertFrom-ModHexToUrl {
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
        _ConvertFrom-ModHexToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'modhex-to-url' -Target 'ConvertFrom-ModHexToUrl'

<#
.SYNOPSIS
    Converts URL/percent encoded string to ModHex representation.
.DESCRIPTION
    Converts a URL/percent encoded string to ModHex string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToModHex
    Converts URL encoding to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input URL encoded string.
#>
function ConvertFrom-UrlToModHex {
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
        _ConvertFrom-UrlToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'url-to-modhex' -Target 'ConvertFrom-UrlToModHex'

<#
.SYNOPSIS
    Converts Base32 string to URL/percent encoded representation.
.DESCRIPTION
    Converts a Base32 string to URL/percent encoded string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToUrl
    Converts Base32 to URL encoding.
.OUTPUTS
    System.String
    The URL/percent encoded representation of the input Base32 string.
#>
function ConvertFrom-Base32ToUrl {
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
        _ConvertFrom-Base32ToUrl -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'base32-to-url' -Target 'ConvertFrom-Base32ToUrl'

<#
.SYNOPSIS
    Converts URL/percent encoded string to Base32 representation.
.DESCRIPTION
    Converts a URL/percent encoded string to Base32 string representation.
.PARAMETER InputObject
    The URL/percent encoded string to convert. Can be piped.
.EXAMPLE
    "Hello%20World" | ConvertFrom-UrlToBase32
    Converts URL encoding to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input URL encoded string.
#>
function ConvertFrom-UrlToBase32 {
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
        _ConvertFrom-UrlToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'url-to-base32' -Target 'ConvertFrom-UrlToBase32'

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

