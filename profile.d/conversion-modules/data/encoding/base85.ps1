# ===============================================
# Base85/Ascii85 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base85/Ascii85 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base85/Ascii85 encoding format.
    Base85 (also known as Ascii85) uses 85 printable ASCII characters (33-117).
    Commonly used in PDF and PostScript files.
    The encoding works on 4-byte groups converted to 5 base85 digits.
    Supports bidirectional conversions between Base85 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Base85 encoding works on 4-byte groups with padding if needed.
    The standard alphabet uses characters from ! (33) to u (117).
#>
function Initialize-FileConversion-CoreEncodingBase85 {
    # Base85 alphabet: !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstu
    # Characters 33-117 (85 characters total)
    $script:Base85Alphabet = '!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstu'
    $script:Base85Padding = '~>'

    # Helper function to encode bytes to Base85
    Set-Item -Path Function:Global:_Encode-Base85 -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return ''
        }
        $result = ''
        $i = 0
        while ($i -lt $Bytes.Length) {
            # Process 4-byte groups
            $group = @(0, 0, 0, 0)
            $groupSize = 0
            for ($j = 0; $j -lt 4 -and ($i + $j) -lt $Bytes.Length; $j++) {
                $group[$j] = $Bytes[$i + $j]
                $groupSize++
            }
            # Convert 4 bytes to 32-bit integer
            $value = [uint32]0
            for ($j = 0; $j -lt 4; $j++) {
                $value = ($value -shl 8) -bor $group[$j]
            }
            # Special case: all zeros become 'z' (compression)
            if ($value -eq 0 -and $groupSize -eq 4) {
                $result += 'z'
                $i += 4
                continue
            }
            # Convert to 5 base85 digits (big-endian)
            $digits = @()
            $tempValue = $value
            for ($j = 0; $j -lt 5; $j++) {
                $digits = , ($tempValue % 85) + $digits
                $tempValue = [Math]::Floor($tempValue / 85)
            }
            # Output digits based on group size
            # For 4 bytes, output all 5 digits; for fewer, output (groupSize + 1) digits
            $outputCount = if ($groupSize -eq 4) { 5 } else { $groupSize + 1 }
            for ($j = 0; $j -lt $outputCount; $j++) {
                $result += $script:Base85Alphabet[$digits[$j]]
            }
            $i += 4
        }
        return $result
    } -Force

    # Helper function to decode Base85 to bytes
    Set-Item -Path Function:Global:_Decode-Base85 -Value {
        param([string]$Base85String)
        if ([string]::IsNullOrWhiteSpace($Base85String)) {
            return @()
        }
        # Remove whitespace and padding markers
        $base85 = $Base85String -replace '\s+', '' -replace '~>', ''
        if ($base85.Length -eq 0) {
            return @()
        }
        # Validate Base85 characters
        if ($base85 -notmatch '^[!"#$%&''()*+,\-./0-9:;<=>?@A-Z\[\\\]^_`a-u]+$') {
            throw "Invalid Base85 character found. Only characters from the Base85 alphabet are allowed."
        }
        $bytes = New-Object System.Collections.ArrayList
        $i = 0
        while ($i -lt $base85.Length) {
            # Handle 'z' compression (represents 4 zero bytes)
            # 'z' only represents compression when it's a standalone character
            # Check if next 4 characters would form a valid group, if not, treat 'z' as compression
            if ($base85[$i] -eq 'z' -and ($i + 1 -ge $base85.Length -or ($base85.Length - $i - 1) % 5 -ne 0)) {
                for ($j = 0; $j -lt 4; $j++) {
                    [void]$bytes.Add(0)
                }
                $i++
                continue
            }
            # Read 5 base85 digits
            $digits = @()
            $digitCount = 0
            while ($digitCount -lt 5 -and $i -lt $base85.Length) {
                $char = $base85[$i]
                $index = $script:Base85Alphabet.IndexOf($char)
                if ($index -eq -1) {
                    throw "Invalid Base85 character: $char"
                }
                $digits += $index
                $digitCount++
                $i++
            }
            # Pad with 'u' (84) if needed
            while ($digitCount -lt 5) {
                $digits += 84
                $digitCount++
            }
            # Convert 5 base85 digits to 32-bit integer
            $value = [uint32]0
            for ($j = 0; $j -lt 5; $j++) {
                $value = ($value * 85) + $digits[$j]
            }
            # Convert to 4 bytes (always output 4 bytes, caller will trim if needed)
            for ($j = 3; $j -ge 0; $j--) {
                [void]$bytes.Add([byte](($value -shr ($j * 8)) -band 0xFF))
            }
        }
        return $bytes.ToArray()
    } -Force

    # ASCII to Base85
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBase85 -Value {
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
                return _Encode-Base85 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Base85: $_"
            }
        }
    } -Force

    # Base85 to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-Base85ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base85 -Base85String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Base85 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Base85
    Set-Item -Path Function:Global:_ConvertFrom-HexToBase85 -Value {
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
                return _Encode-Base85 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Base85: $_"
            }
        }
    } -Force

    # Base85 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-Base85ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base85 -Base85String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base85 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Base85
    Set-Item -Path Function:Global:_ConvertFrom-Base64ToBase85 -Value {
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
                return _Encode-Base85 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Base85: $_"
            }
        }
    } -Force

    # Base85 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-Base85ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Base85 -Base85String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Base85 to Base64: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Base85
<#
.SYNOPSIS
    Converts ASCII text to Base85/Ascii85 encoding.
.DESCRIPTION
    Encodes ASCII/UTF-8 text to Base85 format.
    Base85 is commonly used in PDF and PostScript files.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToBase85
    
    Converts text to Base85 format.
.OUTPUTS
    System.String
    Returns the Base85 encoded string.
#>
function ConvertFrom-AsciiToBase85 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBase85 @PSBoundParameters
}
Set-Alias -Name ascii-to-base85 -Value ConvertFrom-AsciiToBase85 -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name ascii-to-ascii85 -Value ConvertFrom-AsciiToBase85 -Scope Global -ErrorAction SilentlyContinue

# Convert Base85 to ASCII
<#
.SYNOPSIS
    Converts Base85/Ascii85 encoding to ASCII text.
.DESCRIPTION
    Decodes Base85 encoded string back to ASCII/UTF-8 text.
.PARAMETER InputObject
    The Base85 encoded string to decode.
.EXAMPLE
    "87cURD]j7BEbo7" | ConvertFrom-Base85ToAscii
    
    Converts Base85 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Base85ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base85ToAscii @PSBoundParameters
}
Set-Alias -Name base85-to-ascii -Value ConvertFrom-Base85ToAscii -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name ascii85-to-ascii -Value ConvertFrom-Base85ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to Base85
<#
.SYNOPSIS
    Converts hexadecimal string to Base85 encoding.
.DESCRIPTION
    Encodes a hexadecimal string to Base85 format.
.PARAMETER InputObject
    The hexadecimal string to encode.
.EXAMPLE
    "48656C6C6F" | ConvertFrom-HexToBase85
    
    Converts hex to Base85 format.
.OUTPUTS
    System.String
    Returns the Base85 encoded string.
#>
function ConvertFrom-HexToBase85 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HexToBase85 @PSBoundParameters
}
Set-Alias -Name hex-to-base85 -Value ConvertFrom-HexToBase85 -Scope Global -ErrorAction SilentlyContinue

# Convert Base85 to Hex
<#
.SYNOPSIS
    Converts Base85 encoding to hexadecimal string.
.DESCRIPTION
    Decodes Base85 encoded string to hexadecimal format.
.PARAMETER InputObject
    The Base85 encoded string to decode.
.EXAMPLE
    "87cURD]j7BEbo7" | ConvertFrom-Base85ToHex
    
    Converts Base85 to hex format.
.OUTPUTS
    System.String
    Returns the hexadecimal string.
#>
function ConvertFrom-Base85ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base85ToHex @PSBoundParameters
}
Set-Alias -Name base85-to-hex -Value ConvertFrom-Base85ToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to Base85
<#
.SYNOPSIS
    Converts Base64 encoding to Base85 encoding.
.DESCRIPTION
    Converts a Base64 encoded string to Base85 format.
.PARAMETER InputObject
    The Base64 encoded string to convert.
.EXAMPLE
    "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase85
    
    Converts Base64 to Base85 format.
.OUTPUTS
    System.String
    Returns the Base85 encoded string.
#>
function ConvertFrom-Base64ToBase85 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base64ToBase85 @PSBoundParameters
}
Set-Alias -Name base64-to-base85 -Value ConvertFrom-Base64ToBase85 -Scope Global -ErrorAction SilentlyContinue

# Convert Base85 to Base64
<#
.SYNOPSIS
    Converts Base85 encoding to Base64 encoding.
.DESCRIPTION
    Converts a Base85 encoded string to Base64 format.
.PARAMETER InputObject
    The Base85 encoded string to convert.
.EXAMPLE
    "87cURD]j7BEbo7" | ConvertFrom-Base85ToBase64
    
    Converts Base85 to Base64 format.
.OUTPUTS
    System.String
    Returns the Base64 encoded string.
#>
function ConvertFrom-Base85ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Base85ToBase64 @PSBoundParameters
}
Set-Alias -Name base85-to-base64 -Value ConvertFrom-Base85ToBase64 -Scope Global -ErrorAction SilentlyContinue

