# ===============================================
# EBCDIC encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes EBCDIC encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for EBCDIC (Extended Binary Coded Decimal Interchange Code) encoding format.
    EBCDIC is a legacy mainframe character encoding used primarily on IBM mainframe systems.
    Supports bidirectional conversions between EBCDIC and ASCII text.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Uses EBCDIC Code Page 037 (US English) as the standard mapping.
    EBCDIC is an 8-bit encoding with 256 possible values.
#>
function Initialize-FileConversion-CoreEncodingEBCDIC {
    # EBCDIC Code Page 037 to ASCII mapping
    # Maps EBCDIC byte values (0-255) to ASCII characters
    $script:EbcdicToAscii = @(
        # 0x00-0x0F: Control characters
        [char]0x00, [char]0x01, [char]0x02, [char]0x03, [char]0x9C, [char]0x09, [char]0x86, [char]0x7F,
        [char]0x97, [char]0x8D, [char]0x8E, [char]0x0B, [char]0x0C, [char]0x0D, [char]0x0E, [char]0x0F,
        # 0x10-0x1F: Control characters
        [char]0x10, [char]0x11, [char]0x12, [char]0x13, [char]0x9D, [char]0x85, [char]0x08, [char]0x87,
        [char]0x18, [char]0x19, [char]0x92, [char]0x8F, [char]0x1C, [char]0x1D, [char]0x1E, [char]0x1F,
        # 0x20-0x2F: Space and punctuation
        [char]0x80, [char]0x81, [char]0x82, [char]0x83, [char]0x84, [char]0x0A, [char]0x17, [char]0x1B,
        [char]0x88, [char]0x89, [char]0x8A, [char]0x8B, [char]0x8C, [char]0x05, [char]0x06, [char]0x07,
        # 0x30-0x3F: Numbers and punctuation
        [char]0x90, [char]0x91, [char]0x16, [char]0x93, [char]0x94, [char]0x95, [char]0x96, [char]0x04,
        [char]0x98, [char]0x99, [char]0x9A, [char]0x9B, [char]0x14, [char]0x15, [char]0x9E, [char]0x1A,
        # 0x40-0x4F: Special characters and uppercase letters
        [char]0x20, [char]0xA0, [char]0xE2, [char]0xE4, [char]0xE0, [char]0xE1, [char]0xE3, [char]0xE5,
        [char]0xE7, [char]0xF1, [char]0xA2, [char]0x2E, [char]0x3C, [char]0x28, [char]0x2B, [char]0x7C,
        # 0x50-0x5F: Special characters and uppercase letters
        [char]0x26, [char]0xE9, [char]0xEA, [char]0xEB, [char]0xE8, [char]0xED, [char]0xEE, [char]0xEF,
        [char]0xEC, [char]0xDF, [char]0x21, [char]0x24, [char]0x2A, [char]0x29, [char]0x3B, [char]0x5E,
        # 0x60-0x6F: Special characters and uppercase letters
        [char]0x2D, [char]0x2F, [char]0xC2, [char]0xC4, [char]0xC0, [char]0xC1, [char]0xC3, [char]0xC5,
        [char]0xC7, [char]0xD1, [char]0xA6, [char]0x2C, [char]0x25, [char]0x5F, [char]0x3E, [char]0x3F,
        # 0x70-0x7F: Special characters and lowercase letters
        [char]0xF8, [char]0xC9, [char]0xCA, [char]0xCB, [char]0xC8, [char]0xCD, [char]0xCE, [char]0xCF,
        [char]0xCC, [char]0x60, [char]0x3A, [char]0x23, [char]0x40, [char]0x27, [char]0x3D, [char]0x22,
        # 0x80-0x8F: Uppercase letters
        [char]0xD8, [char]0x61, [char]0x62, [char]0x63, [char]0x64, [char]0x65, [char]0x66, [char]0x67,
        [char]0x68, [char]0x69, [char]0xAB, [char]0xBB, [char]0xF0, [char]0xFD, [char]0xFE, [char]0xB1,
        # 0x90-0x9F: Uppercase letters
        [char]0xB0, [char]0x6A, [char]0x6B, [char]0x6C, [char]0x6D, [char]0x6E, [char]0x6F, [char]0x70,
        [char]0x71, [char]0x72, [char]0xAA, [char]0xBA, [char]0xE6, [char]0xB8, [char]0xC6, [char]0xA4,
        # 0xA0-0xAF: Uppercase letters
        [char]0xB5, [char]0x7E, [char]0x73, [char]0x74, [char]0x75, [char]0x76, [char]0x77, [char]0x78,
        [char]0x79, [char]0x7A, [char]0xA1, [char]0xBF, [char]0xD0, [char]0x5B, [char]0xDE, [char]0xAE,
        # 0xB0-0xBF: Uppercase letters and special
        [char]0xAC, [char]0xA3, [char]0xA5, [char]0xB7, [char]0xA9, [char]0xA7, [char]0xB6, [char]0xBC,
        [char]0xBD, [char]0xBE, [char]0xDD, [char]0xA8, [char]0xAF, [char]0x5D, [char]0xB4, [char]0xD7,
        # 0xC0-0xCF: Uppercase letters
        [char]0x7B, [char]0x41, [char]0x42, [char]0x43, [char]0x44, [char]0x45, [char]0x46, [char]0x47,
        [char]0x48, [char]0x49, [char]0xAD, [char]0xF4, [char]0xF6, [char]0xF2, [char]0xF3, [char]0xF5,
        # 0xD0-0xDF: Uppercase letters
        [char]0x7D, [char]0x4A, [char]0x4B, [char]0x4C, [char]0x4D, [char]0x4E, [char]0x4F, [char]0x50,
        [char]0x51, [char]0x52, [char]0xB9, [char]0xFB, [char]0xFC, [char]0xF9, [char]0xFA, [char]0xFF,
        # 0xE0-0xEF: Uppercase letters
        [char]0x5C, [char]0xF7, [char]0x53, [char]0x54, [char]0x55, [char]0x56, [char]0x57, [char]0x58,
        [char]0x59, [char]0x5A, [char]0xB2, [char]0xD4, [char]0xD6, [char]0xD2, [char]0xD3, [char]0xD5,
        # 0xF0-0xFF: Numbers and special
        [char]0x30, [char]0x31, [char]0x32, [char]0x33, [char]0x34, [char]0x35, [char]0x36, [char]0x37,
        [char]0x38, [char]0x39, [char]0xB3, [char]0xDB, [char]0xDC, [char]0xD9, [char]0xDA, [char]0x9F
    )

    # ASCII to EBCDIC mapping (reverse lookup)
    $script:AsciiToEbcdic = New-Object byte[] 256
    for ($i = 0; $i -lt 256; $i++) {
        $script:AsciiToEbcdic[$i] = 0x40  # Default to space if not found
    }
    # Build reverse mapping
    for ($ebcdic = 0; $ebcdic -lt 256; $ebcdic++) {
        $ascii = [int][char]$script:EbcdicToAscii[$ebcdic]
        if ($ascii -lt 256) {
            $script:AsciiToEbcdic[$ascii] = [byte]$ebcdic
        }
    }

    # Helper function to encode bytes (ASCII) to EBCDIC
    Set-Item -Path Function:Global:_Encode-EBCDIC -Value {
        param([byte[]]$Bytes)
        if ($null -eq $Bytes -or $Bytes.Length -eq 0) {
            return @()
        }
        $result = New-Object byte[] $Bytes.Length
        for ($i = 0; $i -lt $Bytes.Length; $i++) {
            $result[$i] = $script:AsciiToEbcdic[$Bytes[$i]]
        }
        return $result
    } -Force

    # Helper function to decode EBCDIC to bytes (ASCII)
    Set-Item -Path Function:Global:_Decode-EBCDIC -Value {
        param([byte[]]$EbcdicBytes)
        if ($null -eq $EbcdicBytes -or $EbcdicBytes.Length -eq 0) {
            return @()
        }
        $result = New-Object byte[] $EbcdicBytes.Length
        for ($i = 0; $i -lt $EbcdicBytes.Length; $i++) {
            $ebcdicByte = $EbcdicBytes[$i]
            $asciiChar = $script:EbcdicToAscii[$ebcdicByte]
            $result[$i] = [byte][char]$asciiChar
        }
        return $result
    } -Force

    # ASCII to EBCDIC (as hex string)
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToEBCDIC -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                $asciiBytes = [System.Text.Encoding]::ASCII.GetBytes($InputObject)
                $ebcdicBytes = _Encode-EBCDIC -Bytes $asciiBytes
                # Return as hex string for display
                return ($ebcdicBytes | ForEach-Object { $_.ToString('X2') }) -join ''
            }
            catch {
                throw "Failed to convert ASCII to EBCDIC: $_"
            }
        }
    } -Force

    # EBCDIC (as hex string) to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-EBCDICToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                # Parse hex string to bytes
                $hex = $InputObject -replace '\s+', '' -replace '-', ''
                if ($hex.Length % 2 -ne 0) {
                    throw "Invalid EBCDIC hex string: length must be even"
                }
                $ebcdicBytes = for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                $asciiBytes = _Decode-EBCDIC -EbcdicBytes $ebcdicBytes
                return [System.Text.Encoding]::ASCII.GetString($asciiBytes)
            }
            catch {
                throw "Failed to convert EBCDIC to ASCII: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to EBCDIC
<#
.SYNOPSIS
    Converts ASCII text to EBCDIC encoding.
.DESCRIPTION
    Encodes ASCII text to EBCDIC format (Code Page 037).
    Returns the EBCDIC encoding as a hexadecimal string.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello" | ConvertFrom-AsciiToEBCDIC
    
    Converts text to EBCDIC format (returns hex string).
.OUTPUTS
    System.String
    Returns the EBCDIC encoded string as hexadecimal.
#>
function ConvertFrom-AsciiToEBCDIC {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToEBCDIC @PSBoundParameters
}
Set-Alias -Name ascii-to-ebcdic -Value ConvertFrom-AsciiToEBCDIC -Scope Global -ErrorAction SilentlyContinue

# Convert EBCDIC to ASCII
<#
.SYNOPSIS
    Converts EBCDIC encoding to ASCII text.
.DESCRIPTION
    Decodes EBCDIC encoded string (as hexadecimal) back to ASCII text.
.PARAMETER InputObject
    The EBCDIC encoded string as hexadecimal.
.EXAMPLE
    "C885939396" | ConvertFrom-EBCDICToAscii
    
    Converts EBCDIC hex to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-EBCDICToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-EBCDICToAscii @PSBoundParameters
}
Set-Alias -Name ebcdic-to-ascii -Value ConvertFrom-EBCDICToAscii -Scope Global -ErrorAction SilentlyContinue

