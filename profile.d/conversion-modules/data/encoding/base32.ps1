# ===============================================
# Base32 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base32 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base32 encoding format.
    Base32 uses the alphabet A-Z, 2-7 (32 characters) as defined in RFC 4648.
    Supports bidirectional conversions between Base32 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base32 encoding works on 5-bit chunks, with padding using '=' character.
#>
function Initialize-FileConversion-CoreEncodingBase32 {
    # Base32 alphabet: A-Z, 2-7 (32 characters)
    $script:Base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
    $script:Base32Padding = '='

    # Helper function to encode bytes to Base32
    Set-Item -Path Function:Global:_Encode-Base32 -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return ''
        }
        $result = ''
        $buffer = 0
        $bitsInBuffer = 0
        foreach ($byte in $Bytes) {
            $buffer = ($buffer -shl 8) -bor $byte
            $bitsInBuffer += 8
            while ($bitsInBuffer -ge 5) {
                $index = ($buffer -shr ($bitsInBuffer - 5)) -band 0x1F
                $result += $script:Base32Alphabet[$index]
                $bitsInBuffer -= 5
                $buffer = $buffer -band ((1 -shl $bitsInBuffer) - 1)
            }
        }
        if ($bitsInBuffer -gt 0) {
            $index = ($buffer -shl (5 - $bitsInBuffer)) -band 0x1F
            $result += $script:Base32Alphabet[$index]
        }
        # Add padding
        $padding = (8 - ($result.Length % 8)) % 8
        if ($padding -gt 0) {
            $result += $script:Base32Padding * $padding
        }
        return $result
    } -Force

    # Helper function to decode Base32 to bytes
    Set-Item -Path Function:Global:_Decode-Base32 -Value {
        param([string]$Base32String)
        if ([string]::IsNullOrWhiteSpace($Base32String)) {
            return @()
        }
        # Remove padding and whitespace, convert to uppercase
        $base32 = ($Base32String -replace '\s+', '' -replace '=', '').ToUpper()
        if ($base32.Length -eq 0) {
            return @()
        }
        # Validate Base32 characters
        if ($base32 -notmatch '^[A-Z2-7]+$') {
            throw "Invalid Base32 character found. Only A-Z and 2-7 are allowed."
        }
        $bytes = New-Object System.Collections.ArrayList
        $buffer = 0
        $bitsInBuffer = 0
        foreach ($char in $base32.ToCharArray()) {
            $index = $script:Base32Alphabet.IndexOf($char)
            if ($index -eq -1) {
                continue
            }
            $buffer = ($buffer -shl 5) -bor $index
            $bitsInBuffer += 5
            while ($bitsInBuffer -ge 8) {
                $byte = ($buffer -shr ($bitsInBuffer - 8)) -band 0xFF
                [void]$bytes.Add($byte)
                $bitsInBuffer -= 8
                $buffer = $buffer -band ((1 -shl $bitsInBuffer) - 1)
            }
        }
        return $bytes.ToArray()
    } -Force

    # ASCII to Base32
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase32 -Value {
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
                return _Encode-Base32 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base32: $_"
            }
        }
    } -Force

    # Base32 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base32 -Base32String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base32 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base32
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert hex to ASCII, then ASCII to Base32
                $ascii = _ConvertFrom-HexToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
            catch {
                throw "Failed to convert Hex to Base32: $_"
            }
        }
    } -Force

    # Base32 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert Base32 to ASCII, then ASCII to hex
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToHex -InputObject $ascii
            }
            catch {
                throw "Failed to convert Base32 to Hex: $_"
            }
        }
    } -Force

    # Binary to Base32
    Set-Item -Path Function:Global:_ConvertFrom-BinaryToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert binary to ASCII, then ASCII to Base32
                $ascii = _ConvertFrom-BinaryToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
            catch {
                throw "Failed to convert Binary to Base32: $_"
            }
        }
    } -Force

    # Base32 to Binary
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToBinary -Value {
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
                # First convert Base32 to ASCII, then ASCII to binary
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBinary -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Base32 to Binary: $_"
            }
        }
    } -Force

    # ModHex to Base32
    Set-Item -Path Function:Global:_ConvertFrom-ModHexToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert ModHex to hex, then hex to Base32
                $hex = _ConvertFrom-ModHexToHex -InputObject $InputObject
                return _ConvertFrom-HexToBase32 -InputObject $hex
            }
            catch {
                throw "Failed to convert ModHex to Base32: $_"
            }
        }
    } -Force

    # Base32 to ModHex
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToModHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert Base32 to hex, then hex to ModHex
                $hex = _ConvertFrom-Base32ToHex -InputObject $InputObject
                return _ConvertFrom-HexToModHex -InputObject $hex
            }
            catch {
                throw "Failed to convert Base32 to ModHex: $_"
            }
        }
    } -Force

    # Octal to Base32
    Set-Item -Path Function:Global:_ConvertFrom-OctalToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert octal to ASCII, then ASCII to Base32
                $ascii = _ConvertFrom-OctalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
            catch {
                throw "Failed to convert Octal to Base32: $_"
            }
        }
    } -Force

    # Base32 to Octal
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToOctal -Value {
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
                # First convert Base32 to ASCII, then ASCII to octal
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToOctal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Base32 to Octal: $_"
            }
        }
    } -Force

    # Decimal to Base32
    Set-Item -Path Function:Global:_ConvertFrom-DecimalToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert decimal to ASCII, then ASCII to Base32
                $ascii = _ConvertFrom-DecimalToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
            catch {
                throw "Failed to convert Decimal to Base32: $_"
            }
        }
    } -Force

    # Base32 to Decimal
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToDecimal -Value {
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
                # First convert Base32 to ASCII, then ASCII to decimal
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToDecimal -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Base32 to Decimal: $_"
            }
        }
    } -Force

    # Roman to Base32
    Set-Item -Path Function:Global:_ConvertFrom-RomanToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # First convert Roman to ASCII, then ASCII to Base32
                $ascii = _ConvertFrom-RomanToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
            catch {
                throw "Failed to convert Roman to Base32: $_"
            }
        }
    } -Force

    # Base32 to Roman
    Set-Item -Path Function:Global:_ConvertFrom-Base32ToRoman -Value {
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
                # First convert Base32 to ASCII, then ASCII to Roman
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $InputObject
                return _ConvertFrom-AsciiToRoman -InputObject $ascii -Separator $Separator
            }
            catch {
                throw "Failed to convert Base32 to Roman: $_"
            }
        }
    } -Force
}

# ===============================================
# Public wrapper functions for Base32 conversions
# ===============================================

<#
.SYNOPSIS
    Converts ASCII text to Base32 representation.
.DESCRIPTION
    Converts ASCII text to Base32 string representation. Base32 uses the alphabet A-Z, 2-7 (32 characters) as defined in RFC 4648.
.PARAMETER InputObject
    The ASCII text to convert. Can be piped.
.EXAMPLE
    "Hello" | ConvertFrom-AsciiToBase32
    Converts "Hello" to Base32.
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
    Converts Base32 string to ASCII text.
.DESCRIPTION
    Converts a Base32 string back to ASCII text. Base32 uses the alphabet A-Z, 2-7 (32 characters).
.PARAMETER InputObject
    The Base32 string to convert. Can be piped. Padding characters (=) are automatically handled.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToAscii
    Converts Base32 to "Hello".
.EXAMPLE
    ConvertFrom-Base32ToAscii -InputObject "MZXW6YTBOI======"
    Converts Base32 string to ASCII.
.OUTPUTS
    System.String
    The ASCII text representation of the input Base32 string.
#>
function ConvertFrom-Base32ToAscii {
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
        _ConvertFrom-Base32ToAscii -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'base32-to-ascii' -Target 'ConvertFrom-Base32ToAscii'

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
    Converts Base32 to binary with spaces.
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
    Converts ModHex string to Base32 representation.
.DESCRIPTION
    Converts a ModHex string to Base32 string representation.
.PARAMETER InputObject
    The ModHex string to convert. Can be piped. Spaces are automatically removed.
.EXAMPLE
    "hkkllkkl" | ConvertFrom-ModHexToBase32
    Converts ModHex to Base32.
.OUTPUTS
    System.String
    The Base32 representation of the input ModHex string.
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
    Converts Base32 string to ModHex representation.
.DESCRIPTION
    Converts a Base32 string to ModHex string representation.
.PARAMETER InputObject
    The Base32 string to convert. Can be piped.
.EXAMPLE
    "JBSWY3DP" | ConvertFrom-Base32ToModHex
    Converts Base32 to ModHex.
.OUTPUTS
    System.String
    The ModHex representation of the input Base32 string.
#>
function ConvertFrom-Base32ToModHex {
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
        _ConvertFrom-Base32ToModHex -InputObject $InputObject
    }
}
Set-AgentModeAlias -Name 'base32-to-modhex' -Target 'ConvertFrom-Base32ToModHex'

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

