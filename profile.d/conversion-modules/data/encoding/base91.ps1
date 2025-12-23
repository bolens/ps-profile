# ===============================================
# Base91 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base91 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base91 encoding format.
    Base91 uses 91 printable ASCII characters (33-126, excluding some characters).
    More efficient than Base64, providing better compression ratio.
    Supports bidirectional conversions between Base91 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base91 encoding works on variable-length encoding without padding.
    Uses the standard Base91 alphabet: A-Z, a-z, 0-9, and special characters.
#>
function Initialize-FileConversion-CoreEncodingBase91 {
    # Base91 alphabet: 91 printable ASCII characters
    # Reference: https://github.com/aberaud/base91-python
    # Alphabet order: A-Z, a-z, 0-9, then special characters
    $script:Base91Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~"'

    # Helper function to encode bytes to Base91
    # Reference: https://github.com/aberaud/base91-python
    Set-Item -Path Function:Global:_Encode-Base91 -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return ''
        }
        $result = ''
        $b = [uint64]0  # Use unsigned to avoid sign extension issues
        $n = 0
        for ($i = 0; $i -lt $Bytes.Length; $i++) {
            # Match Python: b |= byte << n
            $b = $b -bor ($Bytes[$i] -shl $n)
            $n += 8
            # Match Python: if n>13: (process when we have more than 13 bits)
            # Note: Python uses 'if' not 'while', but we need to process all available bits
            # So we use 'while' to continue processing until n <= 13
            while ($n -gt 13) {
                # Match Python: v = b & 8191 (0x1FFF) - get lower 13 bits
                $v = $b -band 0x1FFF
                if ($v -gt 88) {
                    # Match Python: b >>= 13, n -= 13
                    $b = $b -shr 13
                    $n -= 13
                }
                else {
                    # Match Python: v = b & 16383 (0x3FFF) - get lower 14 bits, b >>= 14, n -= 14
                    $v = $b -band 0x3FFF
                    $b = $b -shr 14
                    $n -= 14
                }
                # Match Python: out += alphabet[v % 91] + alphabet[v // 91]
                $result += $script:Base91Alphabet[$v % 91]
                $result += $script:Base91Alphabet[([Math]::Floor($v / 91)) % 91]
            }
        }
        # Match Python: if n: out += alphabet[b % 91]; if n>7 or b>90: out += alphabet[b // 91]
        if ($n -gt 0) {
            $result += $script:Base91Alphabet[$b % 91]
            if ($n -gt 7 -or $b -gt 90) {
                $result += $script:Base91Alphabet[([Math]::Floor($b / 91)) % 91]
            }
        }
        return $result
    } -Force

    # Helper function to decode Base91 to bytes
    # Reference: https://github.com/aberaud/base91-python
    Set-Item -Path Function:Global:_Decode-Base91 -Value {
        param([string]$Base91String)
        
        # Input validation
        if ([string]::IsNullOrWhiteSpace($Base91String)) {
            return @()
        }
        
        # Remove whitespace
        $base91 = $Base91String -replace '\s+', ''
        if ($base91.Length -eq 0) {
            return @()
        }
        
        $bytes = New-Object System.Collections.ArrayList
        $b = [uint64]0  # Use unsigned to avoid sign extension issues
        $n = 0
        $v = -1
        
        for ($i = 0; $i -lt $base91.Length; $i++) {
            $char = $base91[$i]
            $c = $script:Base91Alphabet.IndexOf($char)
            
            # Skip invalid characters (matching Python reference behavior)
            if ($c -eq -1) {
                continue
            }
            
            if ($v -lt 0) {
                # First character of pair
                $v = $c
            }
            else {
                # Second character of pair - reconstruct value
                # Match Python: v += c*91
                $v = $v + ($c * 91)
                
                # Match Python: b |= v << n
                $b = $b -bor ($v -shl $n)
                
                # Match Python: n += 13 if (v & 8191)>88 else 14
                if (($v -band 0x1FFF) -gt 88) {
                    $n += 13
                }
                else {
                    $n += 14
                }
                
                # Match Python: while True: out += struct.pack('B', b&255); b >>= 8; n -= 8; if not n>7: break
                while ($n -gt 7) {
                    [void]$bytes.Add([byte]($b -band 0xFF))
                    $b = $b -shr 8
                    $n -= 8
                }
                
                # Reset for next pair
                $v = -1
            }
        }
        
        # Handle trailing single character (matching Python reference: if v+1)
        if ($v -ge 0) {
            [void]$bytes.Add([byte](($b -bor ($v -shl $n)) -band 0xFF))
        }
        
        return $bytes.ToArray()
    } -Force

    # ASCII to Base91
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase91 -Value {
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
                return _Encode-Base91 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base91: $_"
            }
        }
    } -Force

    # Base91 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base91ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base91 -Base91String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base91 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base91
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase91 -Value {
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
                return _Encode-Base91 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Base91: $_"
            }
        }
    } -Force

    # Base91 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base91ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base91 -Base91String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base91 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Base91
    Set-Item -Path Function:Global:_ConvertFrom-Base64ToBase91 -Value {
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
                return _Encode-Base91 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Base91: $_"
            }
        }
    } -Force

    # Base91 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-Base91ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base91 -Base91String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Base91 to Base64: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Base91
<#
.SYNOPSIS
    Converts ASCII text to Base91 encoding.
.DESCRIPTION
    Encodes ASCII/UTF-8 text to Base91 format.
    Base91 is more efficient than Base64, providing better compression ratio.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase91
    
    Converts text to Base91 format.
.OUTPUTS
    System.String
    Returns the Base91 encoded string.
#>
function ConvertFrom-AsciiToBase91 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBase91 @PSBoundParameters
}
Set-Alias -Name ascii-to-base91 -Value ConvertFrom-AsciiToBase91 -Scope Global -ErrorAction SilentlyContinue

# Convert Base91 to ASCII
<#
.SYNOPSIS
    Converts Base91 encoding to ASCII text.
.DESCRIPTION
    Decodes Base91 encoded string back to ASCII/UTF-8 text.
.PARAMETER InputObject
    The Base91 encoded string to decode.
.EXAMPLE
    ">OwJh>Io0Tv!8PE" | ConvertFrom-Base91ToAscii
    
    Converts Base91 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Base91ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base91ToAscii @PSBoundParameters
}
Set-Alias -Name base91-to-ascii -Value ConvertFrom-Base91ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to Base91
<#
.SYNOPSIS
    Converts hexadecimal string to Base91 encoding.
.DESCRIPTION
    Encodes a hexadecimal string to Base91 format.
.PARAMETER InputObject
    The hexadecimal string to encode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase91
    
    Converts hex to Base91 format.
.OUTPUTS
    System.String
    Returns the Base91 encoded string.
#>
function ConvertFrom-HexToBase91 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HexToBase91 @PSBoundParameters
}
Set-Alias -Name hex-to-base91 -Value ConvertFrom-HexToBase91 -Scope Global -ErrorAction SilentlyContinue

# Convert Base91 to Hex
<#
.SYNOPSIS
    Converts Base91 encoding to hexadecimal string.
.DESCRIPTION
    Decodes Base91 encoded string to hexadecimal format.
.PARAMETER InputObject
    The Base91 encoded string to decode.
.EXAMPLE
    ">OwJh>Io0Tv!8PE" | ConvertFrom-Base91ToHex
    
    Converts Base91 to hex format.
.OUTPUTS
    System.String
    Returns the hexadecimal string.
#>
function ConvertFrom-Base91ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base91ToHex @PSBoundParameters
}
Set-Alias -Name base91-to-hex -Value ConvertFrom-Base91ToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to Base91
<#
.SYNOPSIS
    Converts Base64 encoding to Base91 encoding.
.DESCRIPTION
    Converts a Base64 encoded string to Base91 format.
.PARAMETER InputObject
    The Base64 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase91
    
    Converts Base64 to Base91 format.
.OUTPUTS
    System.String
    Returns the Base91 encoded string.
#>
function ConvertFrom-Base64ToBase91 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base64ToBase91 @PSBoundParameters
}
Set-Alias -Name base64-to-base91 -Value ConvertFrom-Base64ToBase91 -Scope Global -ErrorAction SilentlyContinue

# Convert Base91 to Base64
<#
.SYNOPSIS
    Converts Base91 encoding to Base64 encoding.
.DESCRIPTION
    Converts a Base91 encoded string to Base64 format.
.PARAMETER InputObject
    The Base91 encoded string to convert.
.EXAMPLE
    ">OwJh>Io0Tv!8PE" | ConvertFrom-Base91ToBase64
    
    Converts Base91 to Base64 format.
.OUTPUTS
    System.String
    Returns the Base64 encoded string.
#>
function ConvertFrom-Base91ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base91ToBase64 @PSBoundParameters
}
Set-Alias -Name base91-to-base64 -Value ConvertFrom-Base91ToBase64 -Scope Global -ErrorAction SilentlyContinue

