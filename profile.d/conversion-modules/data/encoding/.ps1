# ===============================================
# Encoding conversion utilities
# ASCII, Hexadecimal, Binary, ModHex, Octal, Decimal, Roman Numeral, Base32, and URL/Percent encoding conversions
# ===============================================

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
    # $PSScriptRoot is already the core directory
    $coreDir = $PSScriptRoot
    
    # Load modules (order matters due to dependencies)
    . (Join-Path $coreDir 'core-encoding-roman.ps1')
    . (Join-Path $coreDir 'core-encoding-modhex.ps1')
    . (Join-Path $coreDir 'core-encoding-ascii.ps1')
    . (Join-Path $coreDir 'core-encoding-hex.ps1')
    . (Join-Path $coreDir 'core-encoding-binary.ps1')
    . (Join-Path $coreDir 'core-encoding-numeric.ps1')
    . (Join-Path $coreDir 'core-encoding-base32.ps1')
    . (Join-Path $coreDir 'core-encoding-base36.ps1')
    . (Join-Path $coreDir 'core-encoding-base58.ps1')
    . (Join-Path $coreDir 'core-encoding-base62.ps1')
    . (Join-Path $coreDir 'core-encoding-base85.ps1')
    . (Join-Path $coreDir 'core-encoding-z85.ps1')
    . (Join-Path $coreDir 'core-encoding-base91.ps1')
    . (Join-Path $coreDir 'core-encoding-utf16-utf32.ps1')
    . (Join-Path $coreDir 'core-encoding-rot.ps1')
    . (Join-Path $coreDir 'core-encoding-morse.ps1')
    . (Join-Path $coreDir 'core-encoding-url.ps1')
    . (Join-Path $coreDir 'core-encoding-base122.ps1')
    . (Join-Path $coreDir 'core-encoding-ebcdic.ps1')
    . (Join-Path $coreDir 'core-encoding-braille.ps1')
    
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
}

# ===============================================
# Public wrapper functions are now in sub-modules
# ===============================================
# All public ConvertFrom-* functions have been moved to their respective sub-modules:
# - ASCII functions → core-encoding-ascii.ps1
# - Hex functions → core-encoding-hex.ps1
# - Binary functions → core-encoding-binary.ps1
# - ModHex functions → core-encoding-modhex.ps1
# - Numeric (Octal/Decimal) functions → core-encoding-numeric.ps1
# - Roman functions → core-encoding-roman.ps1
# - Base32 functions → core-encoding-base32.ps1
# - URL functions → core-encoding-url.ps1
#
# This file now serves as a thin loader that initializes all sub-modules.
