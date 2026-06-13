# Initialize-FileConversion-DocumentCommonHtml

## Synopsis

Initializes HTML document format conversion utility functions.

## Description

Sets up internal conversion functions for HTML format conversions. Supports conversions from HTML to Markdown, PDF, and LaTeX. This function is called automatically by Initialize-FileConversion-DocumentCommon.

## Signature

```powershell
Initialize-FileConversion-DocumentCommonHtml
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. All conversions use pandoc as the underlying tool.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-html.ps1
