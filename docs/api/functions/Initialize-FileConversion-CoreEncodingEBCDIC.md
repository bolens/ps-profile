# Initialize-FileConversion-CoreEncodingEBCDIC

## Synopsis

Initializes EBCDIC encoding conversion utility functions.

## Description

Sets up internal conversion functions for EBCDIC (Extended Binary Coded Decimal Interchange Code) encoding format. EBCDIC is a legacy mainframe character encoding used primarily on IBM mainframe systems. Supports bidirectional conversions between EBCDIC and ASCII text. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingEBCDIC
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Uses EBCDIC Code Page 037 (US English) as the standard mapping. EBCDIC is an 8-bit encoding with 256 possible values.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ebcdic.ps1
