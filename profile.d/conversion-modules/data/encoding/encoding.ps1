# ===============================================
# Encoding conversion utilities
# ASCII, Hexadecimal, Binary, ModHex, Octal, Decimal, Roman Numeral, Base32, and URL/Percent encoding conversions
# ========================================

<#
.SYNOPSIS
    Initializes encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ASCII, Hexadecimal, Binary, ModHex, Octal, Decimal, Roman Numeral, Base32, and URL/Percent encoding formats.
    Supports bidirectional conversions between all format combinations.
    This function is called automatically by Ensure-FileConversion-Data.
    This is a wrapper that loads and initializes all sub-modules.
.NOTES
    This is an internal initialization function and should not be called directly.
    ModHex is a modified hexadecimal encoding used by YubiKey and similar devices.
    Roman numerals are limited to byte values (1-255) for UTF-8 byte representation.
    Base32 uses the alphabet A-Z, 2-7 (32 characters) as defined in RFC 4648.
    URL encoding (percent encoding) follows RFC 3986 specification.
#>
function Initialize-FileConversion-CoreEncoding {
    # Load sub-modules in dependency order
    # $PSScriptRoot is already the encoding directory
    $encodingDir = $PSScriptRoot
    
    # Load modules (order matters due to dependencies)
    . (Join-Path $encodingDir 'roman.ps1')
    . (Join-Path $encodingDir 'modhex.ps1')
    . (Join-Path $encodingDir 'ascii.ps1')
    . (Join-Path $encodingDir 'hex.ps1')
    . (Join-Path $encodingDir 'binary.ps1')
    . (Join-Path $encodingDir 'numeric.ps1')
    . (Join-Path $encodingDir 'base32.ps1')
    . (Join-Path $encodingDir 'base36.ps1')
    . (Join-Path $encodingDir 'base58.ps1')
    . (Join-Path $encodingDir 'base62.ps1')
    . (Join-Path $encodingDir 'base85.ps1')
    . (Join-Path $encodingDir 'z85.ps1')
    . (Join-Path $encodingDir 'base91.ps1')
    . (Join-Path $encodingDir 'utf16-utf32.ps1')
    . (Join-Path $encodingDir 'rot.ps1')
    . (Join-Path $encodingDir 'morse.ps1')
    . (Join-Path $encodingDir 'url.ps1')
    . (Join-Path $encodingDir 'base122.ps1')
    . (Join-Path $encodingDir 'ebcdic.ps1')
    . (Join-Path $encodingDir 'braille.ps1')
    . (Join-Path $encodingDir 'uuid.ps1')
    . (Join-Path $encodingDir 'guid.ps1')
    
    # Initialize all sub-modules in dependency order
    Initialize-FileConversion-CoreEncodingRoman
    Initialize-FileConversion-CoreEncodingModHex
    Initialize-FileConversion-CoreEncodingAscii
    Initialize-FileConversion-CoreEncodingHex
    Initialize-FileConversion-CoreEncodingBinary
    Initialize-FileConversion-CoreEncodingNumeric
    Initialize-FileConversion-CoreEncodingBase32
    Initialize-FileConversion-CoreEncodingBase36
    Initialize-FileConversion-CoreEncodingBase58
    Initialize-FileConversion-CoreEncodingBase62
    Initialize-FileConversion-CoreEncodingBase85
    Initialize-FileConversion-CoreEncodingZ85
    Initialize-FileConversion-CoreEncodingBase91
    Initialize-FileConversion-CoreEncodingUtf16Utf32
    Initialize-FileConversion-CoreEncodingRot
    Initialize-FileConversion-CoreEncodingMorse
    Initialize-FileConversion-CoreEncodingUrl
    Initialize-FileConversion-CoreEncodingBase122
    Initialize-FileConversion-CoreEncodingEBCDIC
    Initialize-FileConversion-CoreEncodingBraille
    Initialize-FileConversion-CoreEncodingUuid
    Initialize-FileConversion-CoreEncodingGuid
}

# ===============================================
# Public wrapper functions are now in sub-modules
# ===============================================
# All public ConvertFrom-* functions have been moved to their respective sub-modules:
# - ASCII functions → ascii.ps1
# - Hex functions → hex.ps1
# - Binary functions → binary.ps1
# - ModHex functions → modhex.ps1
# - Numeric (Octal/Decimal) functions → numeric.ps1
# - Roman functions → roman.ps1
# - Base32 functions → base32.ps1
# - URL functions → url.ps1
#
# This file now serves as a thin loader that initializes all sub-modules.

