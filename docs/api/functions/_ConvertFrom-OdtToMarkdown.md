# _ConvertFrom-OdtToMarkdown

## Synopsis

Initializes ODT document format conversion utility functions.

## Description

Sets up internal conversion functions for ODT (OpenDocument Text) format conversions. ODT is the OpenDocument format for text documents used by LibreOffice and OpenOffice. This function is called automatically by Ensure-FileConversion-Documents.

## Signature

```powershell
_ConvertFrom-OdtToMarkdown [String]$InputPath, [String]$OutputPath
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires pandoc for conversions. ODT files use .odt extension.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
