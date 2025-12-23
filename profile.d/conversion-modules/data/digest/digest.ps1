# ===============================================
# Hash & Digest format conversion utilities
# Hash Format Conversions, Checksum Calculations
# ===============================================

<#
.SYNOPSIS
    Initializes hash and digest format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for hash and digest formats.
    Supports hash format conversions (Hex ↔ Base64 ↔ Base32) and checksum calculations (CRC32, Adler32).
    This function is called automatically by Ensure-FileConversion-Data.
    This is a wrapper that loads and initializes all digest sub-modules.
.NOTES
    This is an internal initialization function and should not be called directly.
    Digest formats include:
    - Hash format conversions (Hex, Base64, Base32)
    - Checksum calculations (CRC32, Adler32)
#>
function Initialize-FileConversion-Digest {
    # Load sub-modules
    # $PSScriptRoot is already the digest directory
    $digestDir = $PSScriptRoot
    
    # Load modules
    . (Join-Path $digestDir 'digest-hash-format.ps1')
    . (Join-Path $digestDir 'digest-checksum.ps1')
    
    # Initialize all sub-modules
    Initialize-FileConversion-DigestHashFormat
    Initialize-FileConversion-DigestChecksum
}

# ===============================================
# Public wrapper functions are in sub-modules
# ===============================================
# All public functions have been moved to their respective sub-modules:
# - Hash format conversion functions → digest-hash-format.ps1
# - Checksum calculation functions → digest-checksum.ps1
#
# This file now serves as a thin loader that initializes all sub-modules.

