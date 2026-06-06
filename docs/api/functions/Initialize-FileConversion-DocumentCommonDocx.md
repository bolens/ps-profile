# Initialize-FileConversion-DocumentCommonDocx

## Synopsis

Initializes DOCX document format conversion utility functions.

## Description

Sets up internal conversion functions for DOCX (Microsoft Word) format conversions. Supports conversions from DOCX to Markdown, HTML, PDF, and LaTeX. This function is called automatically by Initialize-FileConversion-DocumentCommon.

## Signature

```powershell
Initialize-FileConversion-DocumentCommonDocx
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. All conversions use pandoc as the underlying tool.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-docx.ps1
