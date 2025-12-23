# ===============================================
# Base36 encoding conversion utilities
# ========================================

<#
.SYNOPSIS
    Initializes Base36 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base36 encoding format.
    Base36 uses the alphabet: 0-9, A-Z (36 characters).
    Alphanumeric encoding commonly used for compact numeric representation.
    Supports bidirectional conversions between Base36 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base36 encoding works on variable-length encoding without padding.
#>
function Initialize-FileConversion-CoreEncodingBase36 {
    # Base36 alphabet: 0-9, A-Z (36 characters)
    $script:Base36Alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'

    # Helper function to encode bytes to Base36
    Set-Item -Path Function:Global:_Encode-Base36 -Value {
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
            return $script:Base36Alphabet[0].ToString()
        }
        # Convert to Base36
        $result = ''
        $base = [System.Numerics.BigInteger]::new(36)
        while ($bigInt -gt 0) {
            $remainder = [int]($bigInt % $base)
            $result = $script:Base36Alphabet[$remainder] + $result
            $bigInt = [System.Numerics.BigInteger]::Divide($bigInt, $base)
        }
        # Add leading zeros (represented by first character of alphabet)
        foreach ($byte in $Bytes) {
            if ($byte -eq 0) {
                $result = $script:Base36Alphabet[0] + $result
            }
            else {
                break
            }
        }
        return $result
    } -Force

    # Helper function to decode Base36 to bytes
    Set-Item -Path Function:Global:_Decode-Base36 -Value {
        param([string]$Base36String)
        if ([string]::IsNullOrWhiteSpace($Base36String)) {
            return @()
        }
        # Remove whitespace and convert to uppercase
        $base36 = ($Base36String -replace '\s+', '').ToUpper()
        if ($base36.Length -eq 0) {
            return @()
        }
        # Validate Base36 characters
        if ($base36 -notmatch '^[0-9A-Z]+$') {
            throw "Invalid Base36 character found. Only 0-9 and A-Z are allowed."
        }
        # Convert to big integer
        $bigInt = [System.Numerics.BigInteger]::Zero
        foreach ($char in $base36.ToCharArray()) {
            $index = $script:Base36Alphabet.IndexOf($char)
            if ($index -eq -1) {
                throw "Invalid Base36 character: $char"
            }
            $bigInt = ($bigInt * 36) + $index
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
        foreach ($char in $base36.ToCharArray()) {
            if ($char -eq $script:Base36Alphabet[0]) {
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

    # ASCII to Base36
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase36 -Value {
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
                return _Encode-Base36 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base36: $_"
            }
        }
    } -Force

    # Base36 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base36ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base36 -Base36String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base36 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base36
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase36 -Value {
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
                return _Encode-Base36 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Base36: $_"
            }
        }
    } -Force

    # Base36 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base36ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base36 -Base36String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base36 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Base36
    Set-Item -Path Function:Global:_ConvertFrom-Base64ToBase36 -Value {
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
                return _Encode-Base36 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Base36: $_"
            }
        }
    } -Force

    # Base36 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-Base36ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base36 -Base36String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Base36 to Base64: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Base36
<#
.SYNOPSIS
    Converts ASCII text to Base36 encoding.
.DESCRIPTION
    Encodes ASCII/UTF-8 text to Base36 format.
    Base36 is an alphanumeric encoding using 0-9 and A-Z.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase36
    
    Converts text to Base36 format.
.OUTPUTS
    System.String
    Returns the Base36 encoded string.
#>
function ConvertFrom-AsciiToBase36 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBase36 @PSBoundParameters
}
Set-Alias -Name ascii-to-base36 -Value ConvertFrom-AsciiToBase36 -Scope Global -ErrorAction SilentlyContinue

# Convert Base36 to ASCII
<#
.SYNOPSIS
    Converts Base36 encoding to ASCII text.
.DESCRIPTION
    Decodes Base36 encoded string back to ASCII/UTF-8 text.
.PARAMETER InputObject
    The Base36 encoded string to decode.
.EXAMPLE
    "91IXPRL3" | ConvertFrom-Base36ToAscii
    
    Converts Base36 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Base36ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base36ToAscii @PSBoundParameters
}
Set-Alias -Name base36-to-ascii -Value ConvertFrom-Base36ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to Base36
<#
.SYNOPSIS
    Converts hexadecimal string to Base36 encoding.
.DESCRIPTION
    Encodes a hexadecimal string to Base36 format.
.PARAMETER InputObject
    The hexadecimal string to encode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase36
    
    Converts hex to Base36 format.
.OUTPUTS
    System.String
    Returns the Base36 encoded string.
#>
function ConvertFrom-HexToBase36 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HexToBase36 @PSBoundParameters
}
Set-Alias -Name hex-to-base36 -Value ConvertFrom-HexToBase36 -Scope Global -ErrorAction SilentlyContinue

# Convert Base36 to Hex
<#
.SYNOPSIS
    Converts Base36 encoding to hexadecimal string.
.DESCRIPTION
    Decodes Base36 encoded string to hexadecimal format.
.PARAMETER InputObject
    The Base36 encoded string to decode.
.EXAMPLE
    "91IXPRL3" | ConvertFrom-Base36ToHex
    
    Converts Base36 to hex format.
.OUTPUTS
    System.String
    Returns the hexadecimal string.
#>
function ConvertFrom-Base36ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base36ToHex @PSBoundParameters
}
Set-Alias -Name base36-to-hex -Value ConvertFrom-Base36ToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to Base36
<#
.SYNOPSIS
    Converts Base64 encoding to Base36 encoding.
.DESCRIPTION
    Converts a Base64 encoded string to Base36 format.
.PARAMETER InputObject
    The Base64 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase36
    
    Converts Base64 to Base36 format.
.OUTPUTS
    System.String
    Returns the Base36 encoded string.
#>
function ConvertFrom-Base64ToBase36 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base64ToBase36 @PSBoundParameters
}
Set-Alias -Name base64-to-base36 -Value ConvertFrom-Base64ToBase36 -Scope Global -ErrorAction SilentlyContinue

# Convert Base36 to Base64
<#
.SYNOPSIS
    Converts Base36 encoding to Base64 encoding.
.DESCRIPTION
    Converts a Base36 encoded string to Base64 format.
.PARAMETER InputObject
    The Base36 encoded string to convert.
.EXAMPLE
    "91IXPRL3" | ConvertFrom-Base36ToBase64
    
    Converts Base36 to Base64 format.
.OUTPUTS
    System.String
    Returns the Base64 encoded string.
#>
function ConvertFrom-Base36ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base36ToBase64 @PSBoundParameters
}
Set-Alias -Name base36-to-base64 -Value ConvertFrom-Base36ToBase64 -Scope Global -ErrorAction SilentlyContinue

