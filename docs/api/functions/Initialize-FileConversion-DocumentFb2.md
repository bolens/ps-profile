# Initialize-FileConversion-DocumentFb2

## Synopsis

Initializes FB2 (FictionBook) e-book format conversion utility functions.

## Description

Sets up internal conversion functions for FB2 format conversions. FB2 is an XML-based e-book format used primarily in Russia and Eastern Europe. Supports conversions between FB2 and Markdown, HTML, PDF, DOCX, LaTeX formats. This function is called automatically by Ensure-FileConversion-Documents.

## Signature

```powershell
Initialize-FileConversion-DocumentFb2
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires pandoc for conversions (pandoc supports FB2 format). FB2 files are XML-based with .fb2 or .fbz (compressed) extensions.


## Source

Defined in: ../profile.d/conversion-modules/document/document-fb2.ps1
