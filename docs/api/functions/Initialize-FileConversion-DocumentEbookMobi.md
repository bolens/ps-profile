# Initialize-FileConversion-DocumentEbookMobi

## Synopsis

Initializes MOBI/AZW e-book format conversion utility functions.

## Description

Sets up internal conversion functions for MOBI/AZW format conversions. MOBI and AZW are Amazon Kindle e-book formats. This function is called automatically by Ensure-FileConversion-Documents.

## Signature

```powershell
Initialize-FileConversion-DocumentEbookMobi
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Calibre (ebook-convert) or pandoc for conversions. MOBI files use .mobi extension, AZW files use .azw or .azw3 extension.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
