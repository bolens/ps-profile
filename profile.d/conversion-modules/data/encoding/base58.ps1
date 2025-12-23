# ===============================================
# Base58 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base58 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base58 encoding format.
    Base58 uses the alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
    (58 characters, excluding 0, O, I, l to avoid confusion).
    Commonly used by Bitcoin addresses and other cryptocurrency applications.
    Supports bidirectional conversions between Base58 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base58 encoding works on variable-length encoding without padding.
#>
function Initialize-FileConversion-CoreEncodingBase58 {
    # Base58 alphabet: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
    # Excludes: 0, O, I, l to avoid visual confusion
    $script:Base58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

    # Helper function to encode bytes to Base58
    Set-Item -Path Function:Global:_Encode-Base58 -Value {
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
            return $script:Base58Alphabet[0].ToString()
        }
        # Convert to Base58
        $result = ''
        $base = [System.Numerics.BigInteger]::new(58)
        while ($bigInt -gt 0) {
            $remainder = [int]($bigInt % $base)
            $result = $script:Base58Alphabet[$remainder] + $result
            $bigInt = [System.Numerics.BigInteger]::Divide($bigInt, $base)
        }
        # Add leading zeros (represented by first character of alphabet)
        foreach ($byte in $Bytes) {
            if ($byte -eq 0) {
                $result = $script:Base58Alphabet[0] + $result
            }
            else {
                break
            }
        }
        return $result
    } -Force

    # Helper function to decode Base58 to bytes
    Set-Item -Path Function:Global:_Decode-Base58 -Value {
        param([string]$Base58String)
        if ([string]::IsNullOrWhiteSpace($Base58String)) {
            return @()
        }
        # Remove whitespace
        $base58 = $Base58String -replace '\s+', ''
        if ($base58.Length -eq 0) {
            return @()
        }
        # Validate Base58 characters
        if ($base58 -notmatch '^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$') {
            throw "Invalid Base58 character found. Only characters from the Base58 alphabet are allowed."
        }
        # Convert to big integer
        $bigInt = [System.Numerics.BigInteger]::Zero
        foreach ($char in $base58.ToCharArray()) {
            $index = $script:Base58Alphabet.IndexOf($char)
            if ($index -eq -1) {
                throw "Invalid Base58 character: $char"
            }
            $bigInt = ($bigInt * 58) + $index
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
        foreach ($char in $base58.ToCharArray()) {
            if ($char -eq $script:Base58Alphabet[0]) {
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

    # ASCII to Base58
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase58 -Value {
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
                return _Encode-Base58 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base58: $_"
            }
        }
    } -Force

    # Base58 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base58ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base58 -Base58String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base58 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base58
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase58 -Value {
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
                return _Encode-Base58 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Base58: $_"
            }
        }
    } -Force

    # Base58 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base58ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base58 -Base58String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base58 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Base58
    Set-Item -Path Function:Global:_ConvertFrom-Base64ToBase58 -Value {
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
                return _Encode-Base58 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Base58: $_"
            }
        }
    } -Force

    # Base58 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-Base58ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base58 -Base58String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Base58 to Base64: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Base58
<#
.SYNOPSIS
    Converts ASCII text to Base58 encoding.
.DESCRIPTION
    Encodes ASCII/UTF-8 text to Base58 format.
    Base58 is commonly used by Bitcoin addresses and other cryptocurrency applications.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase58
    
    Converts text to Base58 format.
.OUTPUTS
    System.String
    Returns the Base58 encoded string.
#>
function ConvertFrom-AsciiToBase58 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBase58 @PSBoundParameters
}
Set-Alias -Name ascii-to-base58 -Value ConvertFrom-AsciiToBase58 -Scope Global -ErrorAction SilentlyContinue

# Convert Base58 to ASCII
<#
.SYNOPSIS
    Converts Base58 encoding to ASCII text.
.DESCRIPTION
    Decodes Base58 encoded string back to ASCII/UTF-8 text.
.PARAMETER InputObject
    The Base58 encoded string to decode.
.EXAMPLE
    "JxF12TrwUP45BMd" | ConvertFrom-Base58ToAscii
    
    Converts Base58 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Base58ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base58ToAscii @PSBoundParameters
}
Set-Alias -Name base58-to-ascii -Value ConvertFrom-Base58ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to Base58
<#
.SYNOPSIS
    Converts hexadecimal string to Base58 encoding.
.DESCRIPTION
    Encodes a hexadecimal string to Base58 format.
.PARAMETER InputObject
    The hexadecimal string to encode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase58
    
    Converts hex to Base58 format.
.OUTPUTS
    System.String
    Returns the Base58 encoded string.
#>
function ConvertFrom-HexToBase58 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HexToBase58 @PSBoundParameters
}
Set-Alias -Name hex-to-base58 -Value ConvertFrom-HexToBase58 -Scope Global -ErrorAction SilentlyContinue

# Convert Base58 to Hex
<#
.SYNOPSIS
    Converts Base58 encoding to hexadecimal string.
.DESCRIPTION
    Decodes Base58 encoded string to hexadecimal format.
.PARAMETER InputObject
    The Base58 encoded string to decode.
.EXAMPLE
    "JxF12TrwUP45BMd" | ConvertFrom-Base58ToHex
    
    Converts Base58 to hex format.
.OUTPUTS
    System.String
    Returns the hexadecimal string.
#>
function ConvertFrom-Base58ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base58ToHex @PSBoundParameters
}
Set-Alias -Name base58-to-hex -Value ConvertFrom-Base58ToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to Base58
<#
.SYNOPSIS
    Converts Base64 encoding to Base58 encoding.
.DESCRIPTION
    Converts a Base64 encoded string to Base58 format.
.PARAMETER InputObject
    The Base64 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase58
    
    Converts Base64 to Base58 format.
.OUTPUTS
    System.String
    Returns the Base58 encoded string.
#>
function ConvertFrom-Base64ToBase58 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base64ToBase58 @PSBoundParameters
}
Set-Alias -Name base64-to-base58 -Value ConvertFrom-Base64ToBase58 -Scope Global -ErrorAction SilentlyContinue

# Convert Base58 to Base64
<#
.SYNOPSIS
    Converts Base58 encoding to Base64 encoding.
.DESCRIPTION
    Converts a Base58 encoded string to Base64 format.
.PARAMETER InputObject
    The Base58 encoded string to convert.
.EXAMPLE
    "JxF12TrwUP45BMd" | ConvertFrom-Base58ToBase64
    
    Converts Base58 to Base64 format.
.OUTPUTS
    System.String
    Returns the Base64 encoded string.
#>
function ConvertFrom-Base58ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base58ToBase64 @PSBoundParameters
}
Set-Alias -Name base58-to-base64 -Value ConvertFrom-Base58ToBase64 -Scope Global -ErrorAction SilentlyContinue

