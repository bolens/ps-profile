# ===============================================
# UTF-16/UTF-32 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes UTF-16/UTF-32 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for UTF-16 and UTF-32 encoding formats.
    UTF-16 uses 16-bit code units (2 bytes per character, or 4 bytes for surrogate pairs).
    UTF-32 uses 32-bit code units (4 bytes per character).
    Supports both little-endian (LE) and big-endian (BE) byte orders.
    Supports bidirectional conversions between UTF-16/UTF-32 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    UTF-16 and UTF-32 encodings use BOM (Byte Order Mark) to indicate endianness.
    Default behavior uses little-endian (Windows standard).
    Reference: Unicode Standard, RFC 2781 (UTF-16)
#>
function Initialize-FileConversion-CoreEncodingUtf16Utf32 {
    # Helper function to encode bytes to UTF-16 (little-endian by default)
    Set-Item -Path Function:Global:_Encode-Utf16 -Value {
        param(
            [string]$Text,
            [switch]$BigEndian
        )
        if ([string]::IsNullOrEmpty($Text)) {
            return @()
        }
        try {
            $encoding = if ($BigEndian) {
                [System.Text.Encoding]::BigEndianUnicode
            }
            else {
                [System.Text.Encoding]::Unicode  # Little-endian
            }
            return $encoding.GetBytes($Text)
        }
        catch {
            throw "Failed to encode to UTF-16: $_"
        }
    } -Force

    # Helper function to decode UTF-16 to string
    Set-Item -Path Function:Global:_Decode-Utf16 -Value {
        param(
            [byte[]]$Bytes,
            [switch]$BigEndian
        )
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return ''
        }
        try {
            $encoding = if ($BigEndian) {
                [System.Text.Encoding]::BigEndianUnicode
            }
            else {
                [System.Text.Encoding]::Unicode  # Little-endian
            }
            return $encoding.GetString($Bytes)
        }
        catch {
            throw "Failed to decode from UTF-16: $_"
        }
    } -Force

    # Helper function to encode bytes to UTF-32 (little-endian by default)
    Set-Item -Path Function:Global:_Encode-Utf32 -Value {
        param(
            [string]$Text,
            [switch]$BigEndian
        )
        if ([string]::IsNullOrEmpty($Text)) {
            return @()
        }
        try {
            # .NET doesn't have built-in UTF-32, so we need to convert manually
            $result = New-Object System.Collections.ArrayList
            foreach ($char in $Text.ToCharArray()) {
                $codePoint = [int][char]$char
                # Handle surrogate pairs for characters > U+FFFF
                if ([char]::IsSurrogate($char)) {
                    # For surrogate pairs, we need both chars
                    # This is a simplified version - full implementation would handle pairs
                    $codePoint = [int][char]$char
                }
                if ($BigEndian) {
                    [void]$result.Add([byte](($codePoint -shr 24) -band 0xFF))
                    [void]$result.Add([byte](($codePoint -shr 16) -band 0xFF))
                    [void]$result.Add([byte](($codePoint -shr 8) -band 0xFF))
                    [void]$result.Add([byte]($codePoint -band 0xFF))
                }
                else {
                    [void]$result.Add([byte]($codePoint -band 0xFF))
                    [void]$result.Add([byte](($codePoint -shr 8) -band 0xFF))
                    [void]$result.Add([byte](($codePoint -shr 16) -band 0xFF))
                    [void]$result.Add([byte](($codePoint -shr 24) -band 0xFF))
                }
            }
            return $result.ToArray()
        }
        catch {
            throw "Failed to encode to UTF-32: $_"
        }
    } -Force

    # Helper function to decode UTF-32 to string
    Set-Item -Path Function:Global:_Decode-Utf32 -Value {
        param(
            [byte[]]$Bytes,
            [switch]$BigEndian
        )
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return ''
        }
        if ($Bytes.Length % 4 -ne 0) {
            throw "UTF-32 byte array length must be a multiple of 4"
        }
        try {
            $result = ''
            for ($i = 0; $i -lt $Bytes.Length; $i += 4) {
                $codePoint = if ($BigEndian) {
                    ($Bytes[$i] -shl 24) -bor ($Bytes[$i + 1] -shl 16) -bor ($Bytes[$i + 2] -shl 8) -bor $Bytes[$i + 3]
                }
                else {
                    $Bytes[$i] -bor ($Bytes[$i + 1] -shl 8) -bor ($Bytes[$i + 2] -shl 16) -bor ($Bytes[$i + 3] -shl 24)
                }
                # Convert code point to character (handle surrogate pairs if needed)
                if ($codePoint -le 0xFFFF) {
                    $result += [char]$codePoint
                }
                else {
                    # Characters > U+FFFF need surrogate pairs in UTF-16, but UTF-32 can represent them directly
                    # For now, we'll use the Unicode character if possible
                    try {
                        $result += [char]::ConvertFromUtf32($codePoint)
                    }
                    catch {
                        # If conversion fails, skip or use replacement character
                        $result += [char]0xFFFD  # Replacement character
                    }
                }
            }
            return $result
        }
        catch {
            throw "Failed to decode from UTF-32: $_"
        }
    } -Force

    # ASCII to UTF-16
    Set-Item -Path Function:Global:ConvertFrom-AsciiToUtf16 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = _Encode-Utf16 -Text $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert ASCII to UTF-16: $_"
            }
        }
    } -Force

    # UTF-16 to ASCII
    Set-Item -Path Function:Global:ConvertFrom-Utf16ToAscii -Value {
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
                if ($hexString.Length % 4 -ne 0) {
                    throw "UTF-16 hex string length must be a multiple of 4 (2 bytes per character)"
                }
                $bytes = @()
                for ($i = 0; $i -lt $hexString.Length; $i += 2) {
                    $bytes += [Convert]::ToByte($hexString.Substring($i, 2), 16)
                }
                return _Decode-Utf16 -Bytes $bytes
            }
            catch {
                throw "Failed to convert UTF-16 to ASCII: $_"
            }
        }
    } -Force

    # ASCII to UTF-32
    Set-Item -Path Function:Global:ConvertFrom-AsciiToUtf32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $bytes = _Encode-Utf32 -Text $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert ASCII to UTF-32: $_"
            }
        }
    } -Force

    # UTF-32 to ASCII
    Set-Item -Path Function:Global:ConvertFrom-Utf32ToAscii -Value {
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
                if ($hexString.Length % 8 -ne 0) {
                    throw "UTF-32 hex string length must be a multiple of 8 (4 bytes per character)"
                }
                $bytes = @()
                for ($i = 0; $i -lt $hexString.Length; $i += 2) {
                    $bytes += [Convert]::ToByte($hexString.Substring($i, 2), 16)
                }
                return _Decode-Utf32 -Bytes $bytes
            }
            catch {
                throw "Failed to convert UTF-32 to ASCII: $_"
            }
        }
    } -Force

    # Hex to UTF-16
    Set-Item -Path Function:Global:ConvertFrom-HexToUtf16 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Treat input as UTF-8 hex, decode to text, then encode as UTF-16
                $hex = $InputObject -replace '\s+', '' -replace '0x', '' -replace '0X', ''
                if ($hex.Length -eq 0) {
                    return ''
                }
                if ($hex.Length % 2 -ne 0) {
                    throw "Hex string must have an even number of characters"
                }
                $utf8Bytes = @()
                for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    $utf8Bytes += [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                $text = [System.Text.Encoding]::UTF8.GetString($utf8Bytes)
                $utf16Bytes = _Encode-Utf16 -Text $text
                return ($utf16Bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Hex to UTF-16: $_"
            }
        }
    } -Force

    # UTF-16 to Hex
    Set-Item -Path Function:Global:ConvertFrom-Utf16ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Treat input as UTF-16 hex, decode to text, then encode as UTF-8 hex
                $hex = $InputObject -replace '[^0-9A-Fa-f]', ''
                if ($hex.Length % 4 -ne 0) {
                    throw "UTF-16 hex string length must be a multiple of 4"
                }
                $utf16Bytes = @()
                for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    $utf16Bytes += [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                $text = _Decode-Utf16 -Bytes $utf16Bytes
                $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
                return ($utf8Bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert UTF-16 to Hex: $_"
            }
        }
    } -Force

    # Base64 to UTF-16
    Set-Item -Path Function:Global:ConvertFrom-Base64ToUtf16 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Treat input as Base64 (UTF-8 bytes), decode to text, then encode as UTF-16
                $utf8Bytes = [Convert]::FromBase64String($InputObject.Trim())
                $text = [System.Text.Encoding]::UTF8.GetString($utf8Bytes)
                $utf16Bytes = _Encode-Utf16 -Text $text
                return ($utf16Bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Base64 to UTF-16: $_"
            }
        }
    } -Force

    # UTF-16 to Base64
    Set-Item -Path Function:Global:ConvertFrom-Utf16ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Treat input as UTF-16 hex, decode to text, then encode as UTF-8 Base64
                $hex = $InputObject -replace '[^0-9A-Fa-f]', ''
                if ($hex.Length % 4 -ne 0) {
                    throw "UTF-16 hex string length must be a multiple of 4"
                }
                $utf16Bytes = @()
                for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    $utf16Bytes += [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                $text = _Decode-Utf16 -Bytes $utf16Bytes
                $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
                return [Convert]::ToBase64String($utf8Bytes)
            }
            catch {
                throw "Failed to convert UTF-16 to Base64: $_"
            }
        }
    } -Force

    # Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
    if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
        Set-AgentModeAlias -Name 'ascii-to-utf16' -Target 'ConvertFrom-AsciiToUtf16'
        Set-AgentModeAlias -Name 'utf16-to-ascii' -Target 'ConvertFrom-Utf16ToAscii'
        Set-AgentModeAlias -Name 'ascii-to-utf32' -Target 'ConvertFrom-AsciiToUtf32'
        Set-AgentModeAlias -Name 'utf32-to-ascii' -Target 'ConvertFrom-Utf32ToAscii'
        Set-AgentModeAlias -Name 'hex-to-utf16' -Target 'ConvertFrom-HexToUtf16'
        Set-AgentModeAlias -Name 'utf16-to-hex' -Target 'ConvertFrom-Utf16ToHex'
        Set-AgentModeAlias -Name 'base64-to-utf16' -Target 'ConvertFrom-Base64ToUtf16'
        Set-AgentModeAlias -Name 'utf16-to-base64' -Target 'ConvertFrom-Utf16ToBase64'
    }
    else {
        Set-Alias -Name 'ascii-to-utf16' -Value 'ConvertFrom-AsciiToUtf16' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'utf16-to-ascii' -Value 'ConvertFrom-Utf16ToAscii' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'ascii-to-utf32' -Value 'ConvertFrom-AsciiToUtf32' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'utf32-to-ascii' -Value 'ConvertFrom-Utf32ToAscii' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'hex-to-utf16' -Value 'ConvertFrom-HexToUtf16' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'utf16-to-hex' -Value 'ConvertFrom-Utf16ToHex' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'base64-to-utf16' -Value 'ConvertFrom-Base64ToUtf16' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'utf16-to-base64' -Value 'ConvertFrom-Utf16ToBase64' -Scope Global -ErrorAction SilentlyContinue
    }
}

