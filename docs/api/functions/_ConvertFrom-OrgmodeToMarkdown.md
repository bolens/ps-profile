# _ConvertFrom-OrgmodeToMarkdown

## Synopsis

Initializes Org-mode document format conversion utility functions.

## Description

Sets up internal conversion functions for Org-mode format conversions. Org-mode is a document editing and organizing mode for Emacs. This function is called automatically by Ensure-FileConversion-Documents.

## Signature

```powershell
_ConvertFrom-OrgmodeToMarkdown [String]$InputPath, [String]$OutputPath
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires pandoc for conversions. Org-mode files use .org extension.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
