# ===============================================
# Base62 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base62 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base62 encoding format.
    Base62 uses the alphabet: 0-9, A-Z, a-z (62 characters).
    URL-safe alphanumeric encoding commonly used for compact representation.
    Supports bidirectional conversions between Base62 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base62 encoding works on variable-length encoding without padding.
#>
function Initialize-FileConversion-CoreEncodingBase62 {
    # Base62 alphabet: 0-9, A-Z, a-z (62 characters)
    $script:Base62Alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

    # Helper function to encode bytes to Base62
    Set-Item -Path Function:Global:_Encode-Base62 -Value {
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
            return $script:Base62Alphabet[0].ToString()
        }
        # Convert to Base62
        $result = ''
        $base = [System.Numerics.BigInteger]::new(62)
        while ($bigInt -gt 0) {
            $remainder = [int]($bigInt % $base)
            $result = $script:Base62Alphabet[$remainder] + $result
            $bigInt = [System.Numerics.BigInteger]::Divide($bigInt, $base)
        }
        # Add leading zeros (represented by first character of alphabet)
        foreach ($byte in $Bytes) {
            if ($byte -eq 0) {
                $result = $script:Base62Alphabet[0] + $result
            }
            else {
                break
            }
        }
        return $result
    } -Force

    # Helper function to decode Base62 to bytes
    Set-Item -Path Function:Global:_Decode-Base62 -Value {
        param([string]$Base62String)
        if ([string]::IsNullOrWhiteSpace($Base62String)) {
            return @()
        }
        # Remove whitespace
        $base62 = $Base62String -replace '\s+', ''
        if ($base62.Length -eq 0) {
            return @()
        }
        # Validate Base62 characters
        if ($base62 -notmatch '^[0-9A-Za-z]+$') {
            throw "Invalid Base62 character found. Only 0-9, A-Z, and a-z are allowed."
        }
        # Convert to big integer
        $bigInt = [System.Numerics.BigInteger]::Zero
        foreach ($char in $base62.ToCharArray()) {
            $index = $script:Base62Alphabet.IndexOf($char)
            if ($index -eq -1) {
                throw "Invalid Base62 character: $char"
            }
            $bigInt = ($bigInt * 62) + $index
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
        foreach ($char in $base62.ToCharArray()) {
            if ($char -eq $script:Base62Alphabet[0]) {
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

    # ASCII to Base62
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase62 -Value {
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
                return _Encode-Base62 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base62: $_"
            }
        }
    } -Force

    # Base62 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base62ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base62 -Base62String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base62 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base62
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase62 -Value {
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
                return _Encode-Base62 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Base62: $_"
            }
        }
    } -Force

    # Base62 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base62ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base62 -Base62String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base62 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Base62
    Set-Item -Path Function:Global:_ConvertFrom-Base64ToBase62 -Value {
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
                return _Encode-Base62 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Base62: $_"
            }
        }
    } -Force

    # Base62 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-Base62ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base62 -Base62String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Base62 to Base64: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Base62
<#
.SYNOPSIS
    Converts ASCII text to Base62 encoding.
.DESCRIPTION
    Encodes ASCII/UTF-8 text to Base62 format.
    Base62 is a URL-safe alphanumeric encoding using 0-9, A-Z, and a-z.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase62
    
    Converts text to Base62 format.
.OUTPUTS
    System.String
    Returns the Base62 encoded string.
#>
function ConvertFrom-AsciiToBase62 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBase62 @PSBoundParameters
}
Set-Alias -Name ascii-to-base62 -Value ConvertFrom-AsciiToBase62 -Scope Global -ErrorAction SilentlyContinue

# Convert Base62 to ASCII
<#
.SYNOPSIS
    Converts Base62 encoding to ASCII text.
.DESCRIPTION
    Decodes Base62 encoded string back to ASCII/UTF-8 text.
.PARAMETER InputObject
    The Base62 encoded string to decode.
.EXAMPLE
    "73W9kKxE" | ConvertFrom-Base62ToAscii
    
    Converts Base62 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Base62ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base62ToAscii @PSBoundParameters
}
Set-Alias -Name base62-to-ascii -Value ConvertFrom-Base62ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to Base62
<#
.SYNOPSIS
    Converts hexadecimal string to Base62 encoding.
.DESCRIPTION
    Encodes a hexadecimal string to Base62 format.
.PARAMETER InputObject
    The hexadecimal string to encode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase62
    
    Converts hex to Base62 format.
.OUTPUTS
    System.String
    Returns the Base62 encoded string.
#>
function ConvertFrom-HexToBase62 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HexToBase62 @PSBoundParameters
}
Set-Alias -Name hex-to-base62 -Value ConvertFrom-HexToBase62 -Scope Global -ErrorAction SilentlyContinue

# Convert Base62 to Hex
<#
.SYNOPSIS
    Converts Base62 encoding to hexadecimal string.
.DESCRIPTION
    Decodes Base62 encoded string to hexadecimal format.
.PARAMETER InputObject
    The Base62 encoded string to decode.
.EXAMPLE
    "73W9kKxE" | ConvertFrom-Base62ToHex
    
    Converts Base62 to hex format.
.OUTPUTS
    System.String
    Returns the hexadecimal string.
#>
function ConvertFrom-Base62ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base62ToHex @PSBoundParameters
}
Set-Alias -Name base62-to-hex -Value ConvertFrom-Base62ToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to Base62
<#
.SYNOPSIS
    Converts Base64 encoding to Base62 encoding.
.DESCRIPTION
    Converts a Base64 encoded string to Base62 format.
.PARAMETER InputObject
    The Base64 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase62
    
    Converts Base64 to Base62 format.
.OUTPUTS
    System.String
    Returns the Base62 encoded string.
#>
function ConvertFrom-Base64ToBase62 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base64ToBase62 @PSBoundParameters
}
Set-Alias -Name base64-to-base62 -Value ConvertFrom-Base64ToBase62 -Scope Global -ErrorAction SilentlyContinue

# Convert Base62 to Base64
<#
.SYNOPSIS
    Converts Base62 encoding to Base64 encoding.
.DESCRIPTION
    Converts a Base62 encoded string to Base64 format.
.PARAMETER InputObject
    The Base62 encoded string to convert.
.EXAMPLE
    "73W9kKxE" | ConvertFrom-Base62ToBase64
    
    Converts Base62 to Base64 format.
.OUTPUTS
    System.String
    Returns the Base64 encoded string.
#>
function ConvertFrom-Base62ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base62ToBase64 @PSBoundParameters
}
Set-Alias -Name base62-to-base64 -Value ConvertFrom-Base62ToBase64 -Scope Global -ErrorAction SilentlyContinue

