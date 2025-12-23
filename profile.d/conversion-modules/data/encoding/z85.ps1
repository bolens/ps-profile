# ===============================================
# Z85 encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Z85 encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Z85 encoding format.
    Z85 is ZeroMQ's variant of Base85, using a URL-safe and human-readable alphabet.
    Uses the alphabet: 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#
    The encoding works on 4-byte groups converted to 5 Z85 characters.
    Supports bidirectional conversions between Z85 and other formats.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Z85 encoding works on 4-byte groups with padding if needed.
    Unlike Base85/Ascii85, Z85 does not use 'z' compression for zero bytes.
    Reference: https://rfc.zeromq.org/spec/32/
#>
function Initialize-FileConversion-CoreEncodingZ85 {
    # Z85 alphabet: 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#
    # 85 characters total, designed to be URL-safe and human-readable
    $script:Z85Alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#'

    # Helper function to encode bytes to Z85
    Set-Item -Path Function:Global:_Encode-Z85 -Value {
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
            # Convert to 5 Z85 digits (big-endian)
            $digits = @()
            $tempValue = $value
            for ($j = 0; $j -lt 5; $j++) {
                $digits = , ($tempValue % 85) + $digits
                $tempValue = [Math]::Floor($tempValue / 85)
            }
            # Output digits based on group size
            # For 4 bytes, output all 5 digits; for fewer, output (groupSize + 1) digits
            # This matches Base85 behavior and allows proper roundtrip for variable-length data
            $outputCount = if ($groupSize -eq 4) { 5 } else { $groupSize + 1 }
            for ($j = 0; $j -lt $outputCount; $j++) {
                $result += $script:Z85Alphabet[$digits[$j]]
            }
            $i += 4
        }
        return $result
    } -Force

    # Helper function to decode Z85 to bytes
    Set-Item -Path Function:Global:_Decode-Z85 -Value {
        param([string]$Z85String)
        if ([string]::IsNullOrWhiteSpace($Z85String)) {
            return @()
        }
        # Remove whitespace
        $z85 = $Z85String -replace '\s+', ''
        if ($z85.Length -eq 0) {
            return @()
        }
        # Validate Z85 characters
        if ($z85 -notmatch '^[0-9a-zA-Z.\-:+=^!/*?&<>()\[\]{}@%$#]+$') {
            throw "Invalid Z85 character found. Only characters from the Z85 alphabet are allowed."
        }
        $bytes = New-Object System.Collections.ArrayList
        $i = 0
        while ($i -lt $z85.Length) {
            # Read Z85 digits (up to 5)
            $startIndex = $i
            $digits = @()
            $digitCount = 0
            while ($digitCount -lt 5 -and $i -lt $z85.Length) {
                $char = $z85[$i]
                $index = $script:Z85Alphabet.IndexOf($char)
                if ($index -eq -1) {
                    throw "Invalid Z85 character: $char"
                }
                $digits += $index
                $digitCount++
                $i++
            }
            # Pad with last character (84, '#') if needed (matching Base85 behavior)
            # This ensures proper roundtrip for partial groups
            while ($digitCount -lt 5) {
                $digits += 84
                $digitCount++
            }
            # Convert 5 Z85 digits to 32-bit integer
            $value = [uint32]0
            for ($j = 0; $j -lt 5; $j++) {
                $value = ($value * 85) + $digits[$j]
            }
            # Check if this was a partial group (less than 5 characters originally)
            $wasPartialGroup = (($i - $startIndex) -lt 5)
            if ($wasPartialGroup) {
                # Partial group: output (original character count - 1) bytes
                $originalCharCount = $i - $startIndex
                $bytesToOutput = $originalCharCount - 1
            }
            else {
                # Full group: output 4 bytes
                $bytesToOutput = 4
            }
            # Convert to bytes (big-endian, output only needed bytes)
            for ($j = 3; $j -ge (4 - $bytesToOutput); $j--) {
                [void]$bytes.Add([byte](($value -shr ($j * 8)) -band 0xFF))
            }
        }
        return $bytes.ToArray()
    } -Force

    # ASCII to Z85
    Set-Item -Path Function:Global:ConvertFrom-AsciiToZ85 -Value {
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
                return _Encode-Z85 -Bytes $bytes
            }
            catch {
                throw "Failed to convert ASCII to Z85: $_"
            }
        }
    } -Force

    # Z85 to ASCII
    Set-Item -Path Function:Global:ConvertFrom-Z85ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Z85 -Z85String $InputObject
                return [System.Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                throw "Failed to convert Z85 to ASCII: $_"
            }
        }
    } -Force

    # Hex to Z85
    Set-Item -Path Function:Global:ConvertFrom-HexToZ85 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $hex = $InputObject -replace '\s+', '' -replace '0x', '' -replace '0X', ''
                if ($hex.Length -eq 0) {
                    return ''
                }
                if ($hex.Length % 2 -ne 0) {
                    throw "Hex string must have an even number of characters"
                }
                $bytes = @()
                for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    $bytes += [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                return _Encode-Z85 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Hex to Z85: $_"
            }
        }
    } -Force

    # Z85 to Hex
    Set-Item -Path Function:Global:ConvertFrom-Z85ToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Z85 -Z85String $InputObject
                return ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert Z85 to Hex: $_"
            }
        }
    } -Force

    # Base64 to Z85
    Set-Item -Path Function:Global:ConvertFrom-Base64ToZ85 -Value {
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
                return _Encode-Z85 -Bytes $bytes
            }
            catch {
                throw "Failed to convert Base64 to Z85: $_"
            }
        }
    } -Force

    # Z85 to Base64
    Set-Item -Path Function:Global:ConvertFrom-Z85ToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                $bytes = _Decode-Z85 -Z85String $InputObject
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert Z85 to Base64: $_"
            }
        }
    } -Force

    # Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
    if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
        Set-AgentModeAlias -Name 'ascii-to-z85' -Target 'ConvertFrom-AsciiToZ85'
        Set-AgentModeAlias -Name 'z85-to-ascii' -Target 'ConvertFrom-Z85ToAscii'
        Set-AgentModeAlias -Name 'hex-to-z85' -Target 'ConvertFrom-HexToZ85'
        Set-AgentModeAlias -Name 'z85-to-hex' -Target 'ConvertFrom-Z85ToHex'
        Set-AgentModeAlias -Name 'base64-to-z85' -Target 'ConvertFrom-Base64ToZ85'
        Set-AgentModeAlias -Name 'z85-to-base64' -Target 'ConvertFrom-Z85ToBase64'
    }
    else {
        Set-Alias -Name 'ascii-to-z85' -Value 'ConvertFrom-AsciiToZ85' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'z85-to-ascii' -Value 'ConvertFrom-Z85ToAscii' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'hex-to-z85' -Value 'ConvertFrom-HexToZ85' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'z85-to-hex' -Value 'ConvertFrom-Z85ToHex' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'base64-to-z85' -Value 'ConvertFrom-Base64ToZ85' -Scope Global -ErrorAction SilentlyContinue
        Set-Alias -Name 'z85-to-base64' -Value 'ConvertFrom-Z85ToBase64' -Scope Global -ErrorAction SilentlyContinue
    }
}

