# _ConvertFrom-OdpToHtml

## Synopsis

Initializes ODP document format conversion utility functions.

## Description

Sets up internal conversion functions for ODP (OpenDocument Presentation) format conversions. ODP is the OpenDocument format for presentations used by LibreOffice and OpenOffice. This function is called automatically by Ensure-FileConversion-Documents.

## Signature

```powershell
_ConvertFrom-OdpToHtml [String]$InputPath, [String]$OutputPath
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires pandoc or LibreOffice for conversions. ODP files use .odp extension.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odp.ps1
