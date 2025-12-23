# ===============================================
# Hash format conversion utilities
# Hash ↔ Hex, Base64, Base32 representations
# ===============================================

<#
.SYNOPSIS
    Initializes hash format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for converting hash values between different representations.
    Supports conversions between Hex, Base64, and Base32 formats for hash/digest values.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Hash format conversions are useful for converting between different hash representations
    (e.g., converting a hex hash to Base64 or Base32 format).
#>
function Initialize-FileConversion-DigestHashFormat {
    # Hash Hex to Base64
    Set-Item -Path Function:Global:_ConvertFrom-HashHexToBase64 -Value {
        param([string]$HashHex)
        if ([string]::IsNullOrWhiteSpace($HashHex)) {
            return ''
        }
        
        try {
            # Remove any spaces or dashes from hex string
            $hex = $HashHex -replace '[\s\-]', ''
            
            # Validate hex string
            if ($hex.Length % 2 -ne 0) {
                throw "Hex string must have even number of characters"
            }
            if ($hex -notmatch '^[0-9A-Fa-f]+$') {
                throw "Invalid hex string format"
            }
            
            # Convert hex to bytes
            $bytes = @()
            for ($i = 0; $i -lt $hex.Length; $i += 2) {
                $byte = [Convert]::ToByte($hex.Substring($i, 2), 16)
                $bytes += $byte
            }
            
            # Convert bytes to Base64
            return [Convert]::ToBase64String($bytes)
        }
        catch {
            throw "Failed to convert hash hex to Base64: $_"
        }
    } -Force

    # Hash Base64 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-HashBase64ToHex -Value {
        param([string]$HashBase64)
        if ([string]::IsNullOrWhiteSpace($HashBase64)) {
            return ''
        }
        
        try {
            # Remove any whitespace
            $base64 = $HashBase64 -replace '\s', ''
            
            # Convert Base64 to bytes
            $bytes = [Convert]::FromBase64String($base64)
            
            # Convert bytes to hex
            $hex = ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            return $hex.ToLower()
        }
        catch {
            throw "Failed to convert hash Base64 to hex: $_"
        }
    } -Force

    # Hash Hex to Base32
    Set-Item -Path Function:Global:_ConvertFrom-HashHexToBase32 -Value {
        param([string]$HashHex)
        if ([string]::IsNullOrWhiteSpace($HashHex)) {
            return ''
        }
        
        try {
            # First convert hex to Base64, then use Base32 conversion
            # Remove any spaces or dashes from hex string
            $hex = $HashHex -replace '[\s\-]', ''
            
            # Validate hex string
            if ($hex.Length % 2 -ne 0) {
                throw "Hex string must have even number of characters"
            }
            if ($hex -notmatch '^[0-9A-Fa-f]+$') {
                throw "Invalid hex string format"
            }
            
            # Convert hex to bytes
            $bytes = @()
            for ($i = 0; $i -lt $hex.Length; $i += 2) {
                $byte = [Convert]::ToByte($hex.Substring($i, 2), 16)
                $bytes += $byte
            }
            
            # Convert bytes to Base32 (RFC 4648) - use direct Base32 encoding
            if (Get-Command _Encode-Base32 -ErrorAction SilentlyContinue) {
                return _Encode-Base32 -Bytes $bytes
            }
            else {
                # Fallback: convert to ASCII first, then Base32
                $ascii = [System.Text.Encoding]::UTF8.GetString($bytes)
                return _ConvertFrom-AsciiToBase32 -InputObject $ascii
            }
        }
        catch {
            throw "Failed to convert hash hex to Base32: $_"
        }
    } -Force

    # Hash Base32 to Hex
    Set-Item -Path Function:Global:_ConvertFrom-HashBase32ToHex -Value {
        param([string]$HashBase32)
        if ([string]::IsNullOrWhiteSpace($HashBase32)) {
            return ''
        }
        
        try {
            # Remove any whitespace and padding
            $base32 = $HashBase32 -replace '\s', '' -replace '=', ''
            
            # Convert Base32 to bytes (using direct Base32 decoding)
            if (Get-Command _Decode-Base32 -ErrorAction SilentlyContinue) {
                $bytes = _Decode-Base32 -Base32String $base32
            }
            else {
                # Fallback: convert Base32 to ASCII first, then to bytes
                $ascii = _ConvertFrom-Base32ToAscii -InputObject $base32
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($ascii)
            }
            
            # Convert bytes to hex
            $hex = ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
            return $hex.ToLower()
        }
        catch {
            throw "Failed to convert hash Base32 to hex: $_"
        }
    } -Force

    # Hash Base64 to Base32
    Set-Item -Path Function:Global:_ConvertFrom-HashBase64ToBase32 -Value {
        param([string]$HashBase64)
        if ([string]::IsNullOrWhiteSpace($HashBase64)) {
            return ''
        }
        
        try {
            # First convert Base64 to hex, then hex to Base32
            $hex = _ConvertFrom-HashBase64ToHex -HashBase64 $HashBase64
            return _ConvertFrom-HashHexToBase32 -HashHex $hex
        }
        catch {
            throw "Failed to convert hash Base64 to Base32: $_"
        }
    } -Force

    # Hash Base32 to Base64
    Set-Item -Path Function:Global:_ConvertFrom-HashBase32ToBase64 -Value {
        param([string]$HashBase32)
        if ([string]::IsNullOrWhiteSpace($HashBase32)) {
            return ''
        }
        
        try {
            # First convert Base32 to hex, then hex to Base64
            $hex = _ConvertFrom-HashBase32ToHex -HashBase32 $HashBase32
            return _ConvertFrom-HashHexToBase64 -HashHex $hex
        }
        catch {
            throw "Failed to convert hash Base32 to Base64: $_"
        }
    } -Force
}

# Convert hash from Hex to Base64
<#
.SYNOPSIS
    Converts a hash value from hexadecimal to Base64 format.
.DESCRIPTION
    Converts a hash/digest value from hexadecimal representation to Base64 representation.
    Useful for converting between different hash format representations.
.PARAMETER HashHex
    The hash value in hexadecimal format (e.g., "a1b2c3d4").
.EXAMPLE
    ConvertFrom-HashHexToBase64 -HashHex "a1b2c3d4e5f6"
    
    Converts hex hash to Base64 format.
.EXAMPLE
    "a1b2c3d4" | ConvertFrom-HashHexToBase64
    
    Converts hex hash from pipeline.
.OUTPUTS
    System.String
    Returns the hash value in Base64 format.
#>
function ConvertFrom-HashHexToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$HashHex
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($HashHex)) {
            return ''
        }
        try {
            if (Get-Command _ConvertFrom-HashHexToBase64 -ErrorAction SilentlyContinue) {
                return _ConvertFrom-HashHexToBase64 -HashHex $HashHex
            }
            else {
                Write-Error "Internal conversion function _ConvertFrom-HashHexToBase64 not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert hash hex to Base64: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name hash-hex-to-base64 -Value ConvertFrom-HashHexToBase64 -ErrorAction SilentlyContinue

# Convert hash from Base64 to Hex
<#
.SYNOPSIS
    Converts a hash value from Base64 to hexadecimal format.
.DESCRIPTION
    Converts a hash/digest value from Base64 representation to hexadecimal representation.
.PARAMETER HashBase64
    The hash value in Base64 format.
.EXAMPLE
    ConvertFrom-HashBase64ToHex -HashBase64 "obLDxMPh+g=="
    
    Converts Base64 hash to hex format.
.EXAMPLE
    "obLDxMPh+g==" | ConvertFrom-HashBase64ToHex
    
    Converts Base64 hash from pipeline.
.OUTPUTS
    System.String
    Returns the hash value in hexadecimal format (lowercase).
#>
function ConvertFrom-HashBase64ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$HashBase64
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($HashBase64)) {
            return ''
        }
        try {
            if (Get-Command _ConvertFrom-HashBase64ToHex -ErrorAction SilentlyContinue) {
                return _ConvertFrom-HashBase64ToHex -HashBase64 $HashBase64
            }
            else {
                Write-Error "Internal conversion function _ConvertFrom-HashBase64ToHex not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert hash Base64 to hex: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name hash-base64-to-hex -Value ConvertFrom-HashBase64ToHex -ErrorAction SilentlyContinue

# Convert hash from Hex to Base32
<#
.SYNOPSIS
    Converts a hash value from hexadecimal to Base32 format.
.DESCRIPTION
    Converts a hash/digest value from hexadecimal representation to Base32 representation (RFC 4648).
.PARAMETER HashHex
    The hash value in hexadecimal format.
.EXAMPLE
    ConvertFrom-HashHexToBase32 -HashHex "a1b2c3d4e5f6"
    
    Converts hex hash to Base32 format.
.OUTPUTS
    System.String
    Returns the hash value in Base32 format.
#>
function ConvertFrom-HashHexToBase32 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$HashHex
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($HashHex)) {
            return ''
        }
        try {
            if (Get-Command _ConvertFrom-HashHexToBase32 -ErrorAction SilentlyContinue) {
                return _ConvertFrom-HashHexToBase32 -HashHex $HashHex
            }
            else {
                Write-Error "Internal conversion function _ConvertFrom-HashHexToBase32 not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert hash hex to Base32: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name hash-hex-to-base32 -Value ConvertFrom-HashHexToBase32 -ErrorAction SilentlyContinue

# Convert hash from Base32 to Hex
<#
.SYNOPSIS
    Converts a hash value from Base32 to hexadecimal format.
.DESCRIPTION
    Converts a hash/digest value from Base32 representation to hexadecimal representation.
.PARAMETER HashBase32
    The hash value in Base32 format.
.EXAMPLE
    ConvertFrom-HashBase32ToHex -HashBase32 "JBSWY3DP"
    
    Converts Base32 hash to hex format.
.OUTPUTS
    System.String
    Returns the hash value in hexadecimal format (lowercase).
#>
function ConvertFrom-HashBase32ToHex {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$HashBase32
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($HashBase32)) {
            return ''
        }
        try {
            if (Get-Command _ConvertFrom-HashBase32ToHex -ErrorAction SilentlyContinue) {
                return _ConvertFrom-HashBase32ToHex -HashBase32 $HashBase32
            }
            else {
                Write-Error "Internal conversion function _ConvertFrom-HashBase32ToHex not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert hash Base32 to hex: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name hash-base32-to-hex -Value ConvertFrom-HashBase32ToHex -ErrorAction SilentlyContinue

# Convert hash from Base64 to Base32
<#
.SYNOPSIS
    Converts a hash value from Base64 to Base32 format.
.DESCRIPTION
    Converts a hash/digest value from Base64 representation to Base32 representation.
.PARAMETER HashBase64
    The hash value in Base64 format.
.EXAMPLE
    ConvertFrom-HashBase64ToBase32 -HashBase64 "obLDxMPh+g=="
    
    Converts Base64 hash to Base32 format.
.OUTPUTS
    System.String
    Returns the hash value in Base32 format.
#>
function ConvertFrom-HashBase64ToBase32 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$HashBase64
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($HashBase64)) {
            return ''
        }
        try {
            if (Get-Command _ConvertFrom-HashBase64ToBase32 -ErrorAction SilentlyContinue) {
                return _ConvertFrom-HashBase64ToBase32 -HashBase64 $HashBase64
            }
            else {
                Write-Error "Internal conversion function _ConvertFrom-HashBase64ToBase32 not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert hash Base64 to Base32: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name hash-base64-to-base32 -Value ConvertFrom-HashBase64ToBase32 -ErrorAction SilentlyContinue

# Convert hash from Base32 to Base64
<#
.SYNOPSIS
    Converts a hash value from Base32 to Base64 format.
.DESCRIPTION
    Converts a hash/digest value from Base32 representation to Base64 representation.
.PARAMETER HashBase32
    The hash value in Base32 format.
.EXAMPLE
    ConvertFrom-HashBase32ToBase64 -HashBase32 "JBSWY3DP"
    
    Converts Base32 hash to Base64 format.
.OUTPUTS
    System.String
    Returns the hash value in Base64 format.
#>
function ConvertFrom-HashBase32ToBase64 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$HashBase32
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($HashBase32)) {
            return ''
        }
        try {
            if (Get-Command _ConvertFrom-HashBase32ToBase64 -ErrorAction SilentlyContinue) {
                return _ConvertFrom-HashBase32ToBase64 -HashBase32 $HashBase32
            }
            else {
                Write-Error "Internal conversion function _ConvertFrom-HashBase32ToBase64 not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert hash Base32 to Base64: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name hash-base32-to-base64 -Value ConvertFrom-HashBase32ToBase64 -ErrorAction SilentlyContinue

