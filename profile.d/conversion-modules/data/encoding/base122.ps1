# ===============================================
# Base122 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base122 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base122 encoding format.
    Base122 uses 122 printable ASCII characters for URL-safe binary encoding.
    More efficient than Base64 while remaining URL-safe.
    Supports bidirectional conversions between Base122 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base122 encoding works on variable-length encoding without padding.
    Uses 122 characters: all printable ASCII except some problematic URL characters.
#>
function Initialize-FileConversion-CoreEncodingBase122 {
    # Base122 alphabet: 122 characters (URL-safe)
    # Base122 uses 122 characters from ASCII range for efficient binary encoding
    # Standard approach: all ASCII 32-126 (95 chars) except " (34) and \ (92) = 93 chars
    # To reach 122, we add safe extended ASCII characters
    # Build alphabet: space + all printable ASCII except " and \ = 93 chars, then add 29 safe extended
    $baseChars = ' !#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~'
    $baseChars = $baseChars -replace '"', '' -replace '\\', ''  # Remove " and \
    # Add safe extended ASCII characters (non-breaking space and other safe chars)
    # Total: 93 base + 29 extended = 122 characters
    $extendedChars = -join ([char]0xA0, [char]0xA1, [char]0xA2, [char]0xA3, [char]0xA5, [char]0xA7, [char]0xA9, [char]0xAA, [char]0xAB, [char]0xAC, [char]0xAE, [char]0xAF, [char]0xB0, [char]0xB1, [char]0xB2, [char]0xB3, [char]0xB5, [char]0xB6, [char]0xB7, [char]0xB9, [char]0xBA, [char]0xBB, [char]0xBC, [char]0xBD, [char]0xBE, [char]0xBF, [char]0xD7, [char]0xF7, [char]0x2022)
    $script:Base122Alphabet = $baseChars + $extendedChars

    # Helper function to encode bytes to Base122
    Set-Item -Path Function:Global:_Encode-Base122 -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return ''
        }
        # Convert bytes to big integer
        $bigInt = [System.Numerics.BigInteger]::Zero
        foreach ($byte in $Bytes) {
            $bigInt = ($bigInt -shl 8) -bor $byte
        }
        # Handle zero case
        if ($bigInt -eq 0) {
            return $script:Base122Alphabet[0].ToString()
        }
        # Convert to Base122
        $result = ''
        $base = [System.Numerics.BigInteger]::new(122)
        while ($bigInt -gt 0) {
            $remainder = [int]($bigInt % $base)
            $result = $script:Base122Alphabet[$remainder] + $result
            $bigInt = [System.Numerics.BigInteger]::Divide($bigInt, $base)
        }
        # Add leading zeros (represented by first character of alphabet)
        foreach ($byte in $Bytes) {
            if ($byte -eq 0) {
                $result = $script:Base122Alphabet[0] + $result
            }
            else {
                break
            }
        }
        return $result
    } -Force

    # Helper function to decode Base122 to bytes
    Set-Item -Path Function:Global:_Decode-Base122 -Value {
        param([string]$Base122String)
        if ([string]::IsNullOrWhiteSpace($Base122String)) {
            return @()
        }
        # Remove whitespace
        $base122 = $Base122String -replace '\s+', ''
        if ($base122.Length -eq 0) {
            return @()
        }
        # Convert to big integer
        $bigInt = [System.Numerics.BigInteger]::Zero
        foreach ($char in $base122.ToCharArray()) {
            $index = $script:Base122Alphabet.IndexOf($char)
            if ($index -eq -1) {
                throw "Invalid Base122 character: $char"
            }
            $bigInt = ($bigInt * 122) + $index
        }
        # Convert big integer to bytes
        $bytes = New-Object System.Collections.ArrayList
        $byteBase = [System.Numerics.BigInteger]::new(256)
        if ($bigInt -eq 0) {
            [void]$bytes.Add(0)
        }
        else {
            while ($bigInt -gt 0) {
                [void]$bytes.Insert(0, [byte]($bigInt % $byteBase))
                $bigInt = [System.Numerics.BigInteger]::Divide($bigInt, $byteBase)
            }
        }
        # Handle leading zeros (represented by first character of alphabet)
        $leadingZeros = 0
        foreach ($char in $base122.ToCharArray()) {
            if ($char -eq $script:Base122Alphabet[0]) {
                $leadingZeros++
            }
            else {
                break
            }
        }
        for ($i = 0; $i -lt $leadingZeros; $i++) {
            [void]$bytes.Insert(0, 0)
        }
        return $bytes.ToArray()
    } -Force

    # ASCII to Base122
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase122 -Value {
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
                return _Encode-Base122 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base122: $_"
            }
        }
    } -Force

    # Base122 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base122ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base122 -Base122String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base122 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base122
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase122 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Remove spaces and dashes
                $hex = $InputObject -replace '\s+', '' -replace '-', ''
                if ($hex.Length % 2 -ne 0) {
                    throw "Invalid hex string: length must be even"
                }
                $bytes = for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                return _Encode-Base122 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Base122: $_"
            }
        }
    } -Force

    # Base122 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base122ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base122 -Base122String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base122 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Base122
    Set-Item -Path Function:Global:_ConvertFrom-Base64ToBase122 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = [Convert]::FromBase64String($InputObject.Trim())
                return _Encode-Base122 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Base122: $_"
            }
        }
    } -Force

    # Base122 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-Base122ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base122 -Base122String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Base122 to Base64: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Base122
<#
.SYNOPSIS
    Converts ASCII text to Base122 encoding.
.DESCRIPTION
    Encodes ASCII/UTF-8 text to Base122 format.
    Base122 is a URL-safe binary encoding using 122 printable ASCII characters.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase122
    
    Converts text to Base122 format.
.OUTPUTS
    System.String
    Returns the Base122 encoded string.
#>
function ConvertFrom-AsciiToBase122 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBase122 @PSBoundParameters
}
Set-Alias -Name ascii-to-base122 -Value ConvertFrom-AsciiToBase122 -Scope Global -ErrorAction SilentlyContinue

# Convert Base122 to ASCII
<#
.SYNOPSIS
    Converts Base122 encoding to ASCII text.
.DESCRIPTION
    Decodes Base122 encoded string back to ASCII/UTF-8 text.
.PARAMETER InputObject
    The Base122 encoded string to decode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase122 | ConvertFrom-Base122ToAscii
    
    Converts Base122 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Base122ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base122ToAscii @PSBoundParameters
}
Set-Alias -Name base122-to-ascii -Value ConvertFrom-Base122ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to Base122
<#
.SYNOPSIS
    Converts hexadecimal string to Base122 encoding.
.DESCRIPTION
    Encodes a hexadecimal string to Base122 format.
.PARAMETER InputObject
    The hexadecimal string to encode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase122
    
    Converts hex to Base122 format.
.OUTPUTS
    System.String
    Returns the Base122 encoded string.
#>
function ConvertFrom-HexToBase122 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HexToBase122 @PSBoundParameters
}
Set-Alias -Name hex-to-base122 -Value ConvertFrom-HexToBase122 -Scope Global -ErrorAction SilentlyContinue

# Convert Base122 to Hex
<#
.SYNOPSIS
    Converts Base122 encoding to hexadecimal string.
.DESCRIPTION
    Decodes Base122 encoded string to hexadecimal format.
.PARAMETER InputObject
    The Base122 encoded string to decode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase122 | ConvertFrom-Base122ToHex
    
    Converts Base122 to hex format.
.OUTPUTS
    System.String
    Returns the hexadecimal string.
#>
function ConvertFrom-Base122ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base122ToHex @PSBoundParameters
}
Set-Alias -Name base122-to-hex -Value ConvertFrom-Base122ToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to Base122
<#
.SYNOPSIS
    Converts Base64 encoding to Base122 encoding.
.DESCRIPTION
    Converts a Base64 encoded string to Base122 format.
.PARAMETER InputObject
    The Base64 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase122
    
    Converts Base64 to Base122 format.
.OUTPUTS
    System.String
    Returns the Base122 encoded string.
#>
function ConvertFrom-Base64ToBase122 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base64ToBase122 @PSBoundParameters
}
Set-Alias -Name base64-to-base122 -Value ConvertFrom-Base64ToBase122 -Scope Global -ErrorAction SilentlyContinue

# Convert Base122 to Base64
<#
.SYNOPSIS
    Converts Base122 encoding to Base64 encoding.
.DESCRIPTION
    Converts a Base122 encoded string to Base64 format.
.PARAMETER InputObject
    The Base122 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase122 | ConvertFrom-Base122ToBase64
    
    Converts Base122 to Base64 format.
.OUTPUTS
    System.String
    Returns the Base64 encoded string.
#>
function ConvertFrom-Base122ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base122ToBase64 @PSBoundParameters
}
Set-Alias -Name base122-to-base64 -Value ConvertFrom-Base122ToBase64 -Scope Global -ErrorAction SilentlyContinue

