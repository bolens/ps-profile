# _Invoke-PandocMarkdownConversion

## Synopsis

Initializes markdown dialect conversion utility functions.

## Description

Sets up internal conversion functions for markdown dialect and wiki markup conversions via pandoc. Called automatically by Ensure-FileConversion-Documents.

## Signature

```powershell
_Invoke-PandocMarkdownConversion [String]$InputPath, [String]$OutputPath, [String]$FromFormat, [String]$ToFormat, [String]$DefaultOutputExtension, [String]$ErrorLabel
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

Internal initialization function; do not call directly.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-dialects.ps1
