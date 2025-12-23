# ===============================================
# Specialized format conversion utilities
# QR Code, JWT, Barcode
# ===============================================

<#
.SYNOPSIS
    Initializes specialized format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for specialized formats.
    Supports QR Code, JWT (JSON Web Token), and Barcode format conversions.
    This function is called automatically by Ensure-FileConversion-Specialized.
    This is a wrapper that loads and initializes all specialized sub-modules.
.NOTES
    This is an internal initialization function and should not be called directly.
    Specialized formats include:
    - QR Code generation and decoding
    - JWT encoding and decoding
    - Barcode generation and decoding
#>
function Initialize-FileConversion-Specialized {
    # Load sub-modules
    # $PSScriptRoot is already the specialized directory
    $specializedDir = $PSScriptRoot
    
    # Load modules
    . (Join-Path $specializedDir 'specialized-qrcode.ps1')
    . (Join-Path $specializedDir 'specialized-jwt.ps1')
    . (Join-Path $specializedDir 'specialized-barcode.ps1')
    
    # Initialize all sub-modules
    Initialize-FileConversion-SpecializedQrCode
    Initialize-FileConversion-SpecializedJwt
    Initialize-FileConversion-SpecializedBarcode
}

# ===============================================
# Public wrapper functions are in sub-modules
# ===============================================
# All public functions have been moved to their respective sub-modules:
# - QR Code functions → specialized-qrcode.ps1
# - JWT functions → specialized-jwt.ps1
# - Barcode functions → specialized-barcode.ps1
#
# This file now serves as a thin loader that initializes all sub-modules.

