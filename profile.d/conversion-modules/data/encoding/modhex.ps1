# ===============================================
# ModHex encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes ModHex encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ModHex (modified hexadecimal) encoding format.
    ModHex is used by YubiKey and similar devices.
    Supports bidirectional conversions between ModHex and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    ModHex uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v instead of 0-9, A-F.
#>
function Initialize-FileConversion-CoreEncodingModHex {
    # ModHex character mapping (16 characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v)
    # Maps to standard hex: 0-9, A-F
    $script:ModHexToHex = @{
        'c' = '0'; 'b' = '1'; 'd' = '2'; 'e' = '3'
        'f' = '4'; 'g' = '5'; 'h' = '6'; 'i' = '7'
        'j' = '8'; 'k' = '9'; 'l' = 'A'; 'n' = 'B'
        'r' = 'C'; 't' = 'D'; 'u' = 'E'; 'v' = 'F'
    }
    $script:HexToModHex = @{
        '0' = 'c'; '1' = 'b'; '2' = 'd'; '3' = 'e'
        '4' = 'f'; '5' = 'g'; '6' = 'h'; '7' = 'i'
        '8' = 'j'; '9' = 'k'; 'A' = 'l'; 'B' = 'n'
        'C' = 'r'; 'D' = 't'; 'E' = 'u'; 'F' = 'v'
    }

    # ASCII to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToModHex -Value {
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
                $modHexString = $hexString.ToCharArray() | ForEach-Object {
                    $char = $_.ToString().ToUpper()
                    if ($script:HexToModHex.ContainsKey($char)) {
                        $script:HexToModHex[$char]
                    }
                    else {
                        throw "Invalid hex character: $char"
                    }
                }
                return ($modHexString -join '')
            }
            catch {
                throw "Failed to convert ASCII to ModHex: $_"
            }
        }
    } -Force

    # ModHex to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Remove spaces and convert to lowercase
                $modHexString = $InputObject -replace '\s+', '' -replace '[^cbdefghijklnrtuv]', ''
                if ($modHexString.Length % 2 -ne 0) {
                    throw "ModHex string length must be even (got $($modHexString.Length) characters)"
                }
                $hexString = $modHexString.ToCharArray() | ForEach-Object {
                    $char = $_.ToString().ToLower()
                    if ($script:ModHexToHex.ContainsKey($char)) {
                        $script:ModHexToHex[$char]
                    }
                    else {
                        throw "Invalid ModHex character: $char"
                    }
                }
                $hexString = $hexString -join ''
                $bytes = for ($i = 0; $i -lt $hexString.Length; $i += 2) {
                    [Convert]::ToByte($hexString.Substring($i, 2), 16)
                }
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert ModHex to ASCII: $_"
            }
        }
    } -Force

    # Hex to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-HexToModHex -Value {
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
                $hexString = $InputObject -replace '[^0-9A-Fa-f]', '' -replace '\s+', ''
                $modHexString = $hexString.ToCharArray() | ForEach-Object {
                    $char = $_.ToString().ToUpper()
                    if ($script:HexToModHex.ContainsKey($char)) {
                        $script:HexToModHex[$char]
                    }
                    else {
                        throw "Invalid hex character: $char"
                    }
                }
                return ($modHexString -join '')
            }
            catch {
                throw "Failed to convert Hex to ModHex: $_"
            }
        }
    } -Force

    # ModHex to Hex
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Remove spaces and convert to lowercase
                $modHexString = $InputObject -replace '\s+', '' -replace '[^cbdefghijklnrtuv]', ''
                $hexString = $modHexString.ToCharArray() | ForEach-Object {
                    $char = $_.ToString().ToLower()
                    if ($script:ModHexToHex.ContainsKey($char)) {
                        $script:ModHexToHex[$char]
                    }
                    else {
                        throw "Invalid ModHex character: $char"
                    }
                }
                return ($hexString -join '').ToUpper()
            }
            catch {
                throw "Failed to convert ModHex to Hex: $_"
            }
        }
    } -Force

    # Binary to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToModHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert binary to hex, then hex to modhex
                $hexString = _ConvertFrom-BinaryToHex -InputObject $InputObject
                return _ConvertFrom-HexToModHex -InputObject $hexString
            }
            catch {
                throw "Failed to convert Binary to ModHex: $_"
            }
        }
    } -Force

    # ModHex to Binary
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToBinary -Value {
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
                # First convert modhex to hex, then hex to binary
                $hexString = _ConvertFrom-ModHexToHex -InputObject $InputObject
                return _ConvertFrom-HexToBinary -InputObject $hexString -Separator $Separator
            }
            catch {
                throw "Failed to convert ModHex to Binary: $_"
            }
        }
    } -Force

    # ModHex to Octal
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToOctal -Value {
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
                # First convert modhex to hex, then hex to octal
                $hexString = _ConvertFrom-ModHexToHex -InputObject $InputObject
                return _ConvertFrom-HexToOctal -InputObject $hexString -Separator $Separator
            }
            catch {
                throw "Failed to convert ModHex to Octal: $_"
            }
        }
    } -Force

    # Octal to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-OctalToModHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert octal to hex, then hex to modhex
                $hexString = _ConvertFrom-OctalToHex -InputObject $InputObject
                return _ConvertFrom-HexToModHex -InputObject $hexString
            }
            catch {
                throw "Failed to convert Octal to ModHex: $_"
            }
        }
    } -Force

    # ModHex to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToDecimal -Value {
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
                # First convert modhex to hex, then hex to decimal
                $hexString = _ConvertFrom-ModHexToHex -InputObject $InputObject
                return _ConvertFrom-HexToDecimal -InputObject $hexString -Separator $Separator
            }
            catch {
                throw "Failed to convert ModHex to Decimal: $_"
            }
        }
    } -Force

    # Decimal to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToModHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert decimal to hex, then hex to modhex
                $hexString = _ConvertFrom-DecimalToHex -InputObject $InputObject
                return _ConvertFrom-HexToModHex -InputObject $hexString
            }
            catch {
                throw "Failed to convert Decimal to ModHex: $_"
            }
        }
    } -Force

    # ModHex to Roman
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToRoman -Value {
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
                # First convert modhex to hex, then hex to roman
                $hexString = _ConvertFrom-ModHexToHex -InputObject $InputObject
                return _ConvertFrom-HexToRoman -InputObject $hexString -Separator $Separator
            }
            catch {
                throw "Failed to convert ModHex to Roman: $_"
            }
        }
    } -Force

    # Roman to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-RomanToModHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert roman to hex, then hex to modhex
                $hexString = _ConvertFrom-RomanToHex -InputObject $InputObject
                return _ConvertFrom-HexToModHex -InputObject $hexString
            }
            catch {
                throw "Failed to convert Roman to ModHex: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for ModHex conversions
# ===============================================

<#
.SYNOPSIS
    Converts ModHex string to ASCII text.

.DESCRIPTION
    Converts a ModHex (modified hexadecimal) string back to ASCII text. ModHex uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The ASCII text representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToAscii
    Converts ModHex to ASCII text.

.EXAMPLE
    ConvertFrom-ModHexToAscii -InputObject "hkkllkkl"
    Converts ModHex string to ASCII.
#>
function ConvertFrom-ModHexToAscii {
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
        _ConvertFrom-ModHexToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'modhex-to-ascii' -Target 'ConvertFrom-ModHexToAscii'

<#
.SYNOPSIS
    Converts ModHex string to hexadecimal representation.

.DESCRIPTION
    Converts a ModHex (modified hexadecimal) string to standard hexadecimal representation.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The hexadecimal representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToHex
    Converts ModHex to hex.

.EXAMPLE
    ConvertFrom-ModHexToHex -InputObject "hkkllkkl"
    Converts ModHex string to hex.
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
    Converts ModHex string to binary representation.

.DESCRIPTION
    Converts a ModHex (modified hexadecimal) string to binary string representation. First converts ModHex to hex, then hex to binary.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.

.PARAMETER Separator
    Optional separator between binary bytes. Default is a space.

.OUTPUTS
    System.String
    The binary representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToBinary
    Converts ModHex to binary with spaces.

.EXAMPLE
    ConvertFrom-ModHexToBinary -InputObject "hkkllkkl" -Separator ""
    Converts ModHex to binary without separator.
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
    Converts ModHex string to octal representation.

.DESCRIPTION
    Converts a ModHex string to octal string representation.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between octal bytes. Default is a space.

.OUTPUTS
    System.String
    The octal representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToOctal
    Converts ModHex to octal.
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
    Converts ModHex string to decimal representation.

.DESCRIPTION
    Converts a ModHex string to decimal string representation.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between decimal values. Default is a space.

.OUTPUTS
    System.String
    The decimal representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToDecimal
    Converts ModHex to decimal.
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
    Converts ModHex string to Roman numeral representation.

.DESCRIPTION
    Converts a ModHex string to Roman numeral string representation.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped.

.PARAMETER Separator
    Optional separator between Roman numerals. Default is a space.

.OUTPUTS
    System.String
    The Roman numeral representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToRoman
    Converts ModHex to Roman numerals.
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
    Converts ModHex string to Base32 representation.

.DESCRIPTION
    Converts a ModHex string to Base32 string representation.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The Base32 representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToBase32
    Converts ModHex to Base32.
#>
function ConvertFrom-ModHexToBase32 {
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
        _ConvertFrom-ModHexToBase32 -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'modhex-to-base32' -Target 'ConvertFrom-ModHexToBase32'

<#
.SYNOPSIS
    Converts ModHex string to URL/percent encoded representation.

.DESCRIPTION
    Converts a ModHex string to URL/percent encoded string representation.

.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.

.OUTPUTS
    System.String
    The URL/percent encoded representation of the input ModHex string.

.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToUrl
    Converts ModHex to URL encoding.
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

